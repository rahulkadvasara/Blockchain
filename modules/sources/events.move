module modules::game_objects{

    use std::string;
    use aptos_framework::object::{object,self};
    use aptos_framework::event;
    use aptos_framework::account;

    struct GameItem has key{
        name:string::String,
        power:u64,
        create_events : event::EventHandle<ItemCreateEvent>,
        transfer_events : event::EventHandle<ItemTransferEvent>,
    }

    struct Player has key{
        name:string::String,
        level:u64,
        create_events : event::EventHandle<PlayerCreateEvent>,
        level_up_events : event::EventHandle<PlayerLevelUpEvent>,
    }

    struct ItemCreateEvent has drop,store{
        name:string::String,
        power:u64,
    }

    struct ItemTransferEvent has drop,store{
        item_address:address,
        from:address,
        to:address,
    }

    struct PlayerCreateEvent has drop,store{
        name:string::String,
    }

    struct PlayerLevelUpEvent has drop,store{
        player_address:address,
        new_level:u64,
    }

    // create a GameItem and store it in crater's account
    public entry fun create_item(creator:&signer,name:string::String,power:u64){
        let game_item=GameItem{
            name:name,
            power:power,
            create_events:account::new_event_handle<ItemCreateEvent>(creator),
            transfer_events:account::new_event_handle<ItemTransferEvent>(creator),
        };
        event::emit_event(&mut game_item.create_events,ItemCreateEvent{name:name,power:power});
        move_to(creator,game_item);
    }

    // create a Player and store it in creator's account
    public entry fun create_player(creator:&signer,name:string::String){
        let player=Player{
            name:name,
            level:1,
            create_events:account::new_event_handle<PlayerCreateEvent>(creator),
            level_up_events:account::new_event_handle<PlayerLevelUpEvent>(creator),
        };
        event::emit_event(&mut player.create_events,PlayerCreateEvent{name:name});
        move_to(creator,player);
    }

    // transfer ownership of a GameItem to another account
    public entry fun tranfer_item(owner:&signer,item:object<GameItem>,to:address) aquires GameItem {
        let from = std::signer::address_of(owner);
        let item_address = object::object_address(&item);
        let game_item = borrow_globle_mut<GameItem>(item_address);
        event::emit_event(&mut game_item.transfer_events,ItemTransferEvent{
            item_address:item_address,
            from:from,
            to:to,
        });
        object::transfer(owner,item,to);
    }

    // Get the current owner of a GameItem
    public fun get_item_owner(item:Object<GameItem>):address{
        object::owner(item)
    }

    // Function to get the power of a GameItem
    public fun get_item_power(item:Object<GameItem>):u64 aquires GameItem{
        let game_item = borrow_globle<GameItem>(object::object_address(&item));
        game_item.power
    }

    // Function to level up a player
    public entry fun level_up(player:Object<Player>) aquires Player{
        let player_address = object::object_address(&player);
        let mut_player = borrow_globle_mut<Player>(player_address);
        mut_player.level = mut_player.level+1;
        event::emit_event(&mut mut_player.level_up_events,PlayerLevelUpEvent{
            player_address: player_address,
            new_level:mut_player.level,
        });
    }

}

