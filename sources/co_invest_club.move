module co_invest_club::co_invest_club {

    // Necessary imports
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext, sender};
    use sui::clock::{Self, Clock};
    use sui::balance::{Self, Balance};
    use sui::sui::{SUI};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};
    
    use std::string::{Self, String};

    // Errors 
    const ERROR_INVALID_GENDER: u64 = 0;
    const ERROR_INVALID_ACCESS: u64 = 1;
    const ERROR_INSUFFICIENT_FUNDS: u64 = 2;
    const ERROR_INVALID_TIME : u64 = 3;
    const ERROR_INVESTMET_ALREADY_PAID: u64 = 4;
    
    // Struct Definitions
    
    // Club struct
    struct Club has key, store{
        id: UID,
        name: String,
        club_type: String,
        rules: String,
        description: String,
        investments: Table<address, Investment>,
        balance: Balance<SUI>,
        sub_price: u64,
        founding_date: u64,
        status: String,
    }
    
    // struct that represent Club Capability
    struct ClubCap has key {
        id: UID,
        club_id: ID,
    }

    // Member Struct
    struct Member has key, store {
        id: UID,
        club_id: ID,
        name: String,
        gender: String,
        contact_info: String,
        sub_count: u64,
        pay: bool,
        date_joined: u64
    }

    // Investment Struct
    struct Investment has copy, store, drop {
        member_id: ID,
        amount_payable: u64,
        payment_date: u64,
    }

    // Create a new Club
    public fun create_club(name: String, club_type: String, description: String, rules: String, sub: u64, open: String, c: &Clock, ctx: &mut TxContext): (Club, ClubCap) {
        let id_ = object::new(ctx);
        let inner_ = object::uid_to_inner(&id_);
        let club = Club {
            id: id_,
            name,
            club_type,
            description,
            rules,
            status: open,
            founding_date: clock::timestamp_ms(c),
            sub_price: sub,
            investments: table::new(ctx),
            balance: balance::zero(),
        };

        let cap = ClubCap {
            id: object::new(ctx),
            club_id: inner_,
        };
        (club, cap)

    }
    
    // Add a member to the club
    public fun new_member(self: &mut Club, name: String, gender: String, contact_info: String, coin: Coin<SUI>, clock: &Clock, ctx: &mut TxContext): Member {
        let amount = coin::value(&coin);
        assert!(amount == self.sub_price, ERROR_INSUFFICIENT_FUNDS);
        assert!(gender == string::utf8(b"MALE") || gender == string::utf8(b"FAMALE"), ERROR_INVALID_GENDER);
        coin::put(&mut self.balance, coin);

        let id_ = object::new(ctx);
        let inner_ = object::uid_to_inner(&id_);
        let member = Member {
            id: id_,
            club_id: object::id(self),
            name,
            gender,
            contact_info,
            sub_count: 1,
            date_joined: clock::timestamp_ms(clock),
            pay: true
        };
        let investment = Investment {
            member_id: inner_,
            amount_payable: amount,
            payment_date: clock::timestamp_ms(clock)
        };
        table::add(&mut self.investments, sender(ctx), investment);
        member
    }
    
    // Function for member to re investment
    public fun pay_investment(self: &mut Club, investment: &mut Investment, member: &mut Member, coin: Coin<SUI>, clock: &Clock, ctx: &mut TxContext) {
        let investment = table::borrow_mut(&mut self.investments, sender(ctx));
        let amount = coin::value(&coin);
        assert!(amount == investment.amount_payable, ERROR_INSUFFICIENT_FUNDS);
        assert!(investment.payment_date < clock::timestamp_ms(clock), ERROR_INVALID_TIME);
        
        // Add the coin to the club balance
        let balance_ = coin::into_balance(coin);
        balance::join(&mut self.balance, balance_);
        // Investment Status
        investment.amount_payable = investment.amount_payable + amount;
        member.pay = true;
        member.sub_count = member.sub_count + 1;
    }
    
    // Function to withdraw funds from the club
    public fun withdraw_funds(cap: &ClubCap, club: &mut Club, ctx: &mut TxContext) : Coin<SUI> {
        assert!(cap.club_id == object::id(club), ERROR_INVALID_ACCESS);
        let balance_ = balance::withdraw_all(&mut club.balance);
        let coin_ = coin::from_balance(balance_, ctx);
        coin_
    }
    
    // Function to get the total balance of the club
    public fun get_balance(club: &Club) : u64 {
        balance::value(&club.balance)
    }
}
