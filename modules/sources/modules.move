module modlues::greeting{
    use std::string;

    struct Message has key{
        content:string::String
    }

    public fun set_message(account:&signer,msg:string::String){
        // Function implementation would go here
    }

    public fun get_message(addr:address):string::String{
        // Function implementation would go here
        string::utf8(b"Hello,world")
    }

}

module move_basics::struct_examples{
    // Basic struct without abilities
    struct BasicProfile{
        name: vector<u8>,
        age: u8
    }

    // struct with copy ability
    struct Score has copy{
        vlaue: u64
    }

    // struct with drop ability
    struct TemproryFlag has drop{
        is_active:bool
    }

    // struct with store ability
    struct StoreData has store{
        data:vector<u8>
    }

    // struct with key ability(for globle storage)
    struct UserAccount has key{
        balance:u64
    }

    // struct with multiple abilities
    struct GameItem has copy,drop,store{
        id:u64,
        name:vector<u8>
    }

    // example of a generic struct
    struct Container<T> has store{
        item:T
    }
}