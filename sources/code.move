module address::SimpleGamblingGame {
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::signer;
    use std::vector;

    struct Bet has store, key {
        player: address,
        color_choice: u8, // 0 for Red, 1 for Blue
        stake: u64,
    }

    struct GamblingHouse has store, key {
        bets: vector<Bet>,
    }


    public fun init_game(player: &signer) {
        let game_house_address = signer::address_of(player);
        assert!(!exists<GamblingHouse>(game_house_address), 0); 
        move_to(player, GamblingHouse { bets: vector::empty<Bet>() });
    }

    public fun place_bet(player: &signer, color_choice: u8, stake: u64) acquires GamblingHouse {
        let game_house_address = signer::address_of(player);
        let game_house = borrow_global_mut<GamblingHouse>(game_house_address);

        // Ensure valid bet (color_choice must be 0 or 1)
        assert!(color_choice == 0 || color_choice == 1, 1);


        vector::push_back(&mut game_house.bets, Bet {
            player: signer::address_of(player),
            color_choice,
            stake,
        });

        // Deduct the staked amount from the player's balance
        let coins = coin::withdraw<AptosCoin>(player, stake);
    }

    public fun play_game(player: &signer, user_input: u64) acquires GamblingHouse {
        let game_house_address = signer::address_of(player);
        let game_house = borrow_global_mut<GamblingHouse>(game_house_address);


        assert!(vector::length(&game_house.bets) > 0, 2);

        let random_number = (user_input % 10) + 1; // Generate a random number between 1 and 10


        let winning_color = if (random_number <= 5) { 0 } else { 1 };


        let len = vector::length(&game_house.bets);
        let mut i = 0;
        while (i < len) {
            let bet = vector::borrow(&game_house.bets, i);

            let reward = if (bet.color_choice == winning_color) {
                // Player wins double the stake
                bet.stake * 2
            } else {
                0
            };

            if (reward > 0) {
                // Mint new coins as a reward and deposit them to the player's account
                let reward_coins = coin::mint<AptosCoin>(reward);
                coin::deposit<AptosCoin>(bet.player, reward_coins);
            };

            i = i + 1; // Move to the next bet
        }


        game_house.bets = vector::empty();
    }
}
