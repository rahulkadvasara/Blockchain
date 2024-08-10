module modules::coin_functions{

    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    const E_INSUFFICIENT_BALANCE: u64=1;

    // public function to get balance
    public fun get_balance(addr:address):u64{
        coin::balance<AptosCoin>(addr)
    }

    // public entry function to transfer coins
    public entry fun transfer(from:&signer,to:address,amount:u64){
        let from_addr = signer::address_of(from);
        assert!(get_balance(from_addr)>=amount,E_INSUFFICIENT_BALANCE);
        coin::transfer<AptosCoin>(from,to,amount);
    }

    // private helper function
    fun is_valid_amount(amount:u64):bool{
        amount > 0 && amount <= 1000000
    }

    // public function with generic type
    public fun safe_transfer<CoinType>(from:&signer,to:address,amount:u64){
        assert!(is_valid_amount(amount),0);  // Here 0 is representing an error
        coin::transfer<CoinType>(from,to,amount);
    }

    // View Function
    #[view]
    public fun can_transfer(addr:address,amount:u64):bool{
        get_balance(addr)>=amount && is_valid_amount(amount)
    }

}