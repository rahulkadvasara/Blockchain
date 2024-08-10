module modules::vault{
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event::{Self,EventHandle};
    use aptos_framework::account;
    use aptos_std::table::{Self,Table};

    // Error codes
    const E_NOT_ADMIN:u64 = 1;
    const E_INSUFFICIENT_BALANCE:u64 = 2;
    const E_NO_ALLOCATION:u64 = 3;

    // Events
    struct AllocationMadeEvent has drop,store{address:address,amount: u64}
    struct AllocationClaimedEvent has drop,store{address:address,amount: u64}
    struct TokenDepositeEvent has drop,store{address:address,amount: u64}
    struct TokenWithdrawnEvent has drop,store{address:address,amount: u64}

    // The Vault Struct
    struct Vault has key{
        admin:address,
        vault_address:address,
        allocations : Table<address,u64>,
        total_allocated:u64,
        total_balance:u64,
        allocation_made_events:EventHandle<AllocationMadeEvent>,
        allocation_claimed_events:EventHandle<AllocationClaimedEvent>,
        tokens_deposited_events:EventHandle<TokenDepositeEvent>,
        tokens_withdrawn_events:EventHandle<TokenWithdrawnEvent>,
    }

    struct VaultSignerCapability has key{
        cap:account::SignerCapability
    }

    fun init_module(resource_account : &signer){
        let resource_account_address = signer::address_of(resource_account);

        let (vault_signer,vault_signer_cap) = account::create_resource_account(resource_account_address,b"Vault");
        let vault_address = signer::address_of(vault_signer);

        if(!coin::is_account_registered<AptosCoin>(vault_address)){
            coin::register<AptosCoin>(&vault_signer);
        };

        move_to(&vault_signer,Vault{
            admin:resource_account,
            vault_address,
            allocations:table::new(),
            total_allocated:0,
            total_balance:0,
            allocation_made_events:account::new_event_handle<AllocationMadeEvent>(&vault_signer),
            allocation_claimed_events:account::new_event_handle<AllocationClaimedEvent>(&vault_signer),
            tokens_deposited_events:account::new_event_handle<TokenDepositeEvent>(&vault_signer),
            tokens_withdrawn_events:account::new_event_handle<TokenWithdrawnEvent>(&vault_signer),
        });

        move_to(resource_account,VaultSignerCapability{cap:vault_signer_cap});

    }

    public fun get_vault_address(admin_address:address):address acquires VaultSignerCapability{
        let vault_signer_cap = &borrow_globle<VaultSignerCapability>(admin_address).cap;
        account::get_signer_capability_address(vault_signer_cap)
    }

    public entry fun deposit_tokens(admin:&signer,amount:u64) acquires Vault,VaultSignerCapability{
        let admin_address = signer::address_of(admin);
        let vault_address = get_vault_address(admin_address);
        let vault = borrow_globle_mut<Vault>(vault_address);

        coin::transfer<AptosCoin>(admin,vault.vault_address,amount);
        vault.total_balance = vault.total_balance+amount;

        emit::emit_event(&mut vault.tokens_deposited_events,TokenDepositeEvent{amount});
    }

    public entry fun allocate_tokens(admin:&signer,address:address,amount:u64) acquires Vault,VaultSignerCapability{
        let admin_address = signer::address_of(admin);
        let vault_address = get_vault_address(admin_address);
        let vault = borrow_globle_mut<Vault>(vault_address);

        assert!(vault.admin == admin_address,E_NOT_ADMIN);
        assert!(vault.total_balance>=vault.total_allocated+amount,E_INSUFFICIENT_BALANCE);

        let current_allocation = if (table::contains(&vault.allocations,address)){
            *table::borrow(&vault.allocations,address)
        } else {
            0
        };

        table::upsert(&mut vault.allocations,address,current_allocation+amount);
        vault.total_allocated = vault.total_allocated+amount;

        emit::emit_event(&mut vault.allocation_made_events,AllocationMadeEvent{address,amount});
    }

    public entry fun claim_tokens(admin:&signer,admin_address:address) acquires Vault,VaultSignerCapability{
        let account_address = signer::address_of(account);
        let vault_address = get_vault_address(admin_address);
        let vault = borrow_globle_mut<Vault>(vault_address);

        assert!(table::contains(&vault.allocations,account_address),E_NO_ALLOCATION);

        let amount = table::remove(&mut vault.allocations,account_address);

        assert!(vault.total_balance>=amount,E_INSUFFICIENT_BALANCE);

        vault.total_allocated=v.total_allocated-amount;
        vault.total_balance=v.total_balance-amount;

        let vault_signer_cap = borrow_globle<VaultSignerCapability>(admin_address).cap;
        let vault_signer = account::create_signer_with_capability(vault_signer_cap);

        if(!coin::is_account_registered<AptosCoin>(account_address)){
            coin::register<AptosCoin>(account);
        };

        coin::tranfer<AptosCoin>(&vault_signer,account_address,amount);
        event::emit_event(&mut vault.allocation_claimed_events,AllocationClaimedEvent{address:account_address,amount});
    }

    public entry fun withdraw_tokens(admin:&signer,admin_address:address) acquires Vault,VaultSignerCapability{
        let admin_address = signer::address_of(admin);
        let vault_address = get_vault_address(admin_address);
        let vault = borrow_globle_mut<Vault>(vault_address);

        assert!(vault.admin == admin_address,E_NOT_ADMIN);

        let available_balance = vault.total_balance - vault.total_allocated;

        assert!(vault.total_balance>=amount,E_INSUFFICIENT_BALANCE);

        let vault_signer_cap = borrow_global<VaultSignerCapability>(vault.admin).cap;
        let vault_signer = account::create_signer_with_capability(vault_signer_cap);

        let amount:u64=100;

        coin::transfer<AptosCoin>(&vault_signer,admin_address,amount);
        event::emit_event(&mut vault.tokens_withdrawn_events,TokenWithdrawnEvent{amount,address:vault_address});
    }

    #[view]
    public fun vault_address(admin_address:address):address acquires VaultSignerCapability{
        let vault_signer_cap = &borrow_global<VaultSignerCapability>(admin_address).cap;
        account::get_signer_capability_address(vault_signer_cap)
    }

    // Get the vault's balance
    #[view]
    public fun get_balance(admin_address:address):u64 acquires Vault,VaultSignerCapability{
        let vault_address = get_vault_address(admin_address);
        let vault = borrow_global<Vault>(vault_address);
        vault.total_balance
    }

    // Get the total allocated ammount
    #[view]
    public fun get_total_allocated(admin_address:address):u64 acquires Vault,VaultSignerCapability{
        let vault_address = get_vault_address(admin_address);
        let vault = borrow_global<Vault>(vault_address);
        vault.total_allocated
    }

    // Get the allocation for a specific address
    #[view]
    public fun get_allocation(admin_address:address,address:address):u64 acquires Vault,VaultSignerCapability{
        let vault_address = get_vault_address(admin_address);
        let vault = borrow_global<Vault>(vault_address);
        if(table::contains<address,u64>(&vault.allocations,address)){
            *table::borrow(&vault.allocations,address)
        } else {
            0
        }
    }

}



