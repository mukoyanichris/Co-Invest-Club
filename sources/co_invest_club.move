module co_invest_club::co_invest_club {

    // Necessary imports
    use sui::object::{Self as Object, UID, ID, id, new, uid_to_inner};
    use sui::tx_context::{TxContext, sender};
    use sui::clock::{Self as Clock, timestamp_ms};
    use sui::balance::{Self as Balance, Balance, zero, withdraw_all, join, value};
    use sui::sui::{SUI};
    use sui::coin::{Self as Coin, Coin, into_balance, from_balance};
    use sui::table::{Self as Table, Table};
    
    use std::string::{String};
    use std::vector::{Self as Vector};

    // Gender Constants
    const OTHER: u8 = 0;
    const MALE: u8 = 1;
    const FEMALE: u8 = 2;

    // Status Constants
    const PENDING: u8 = 0;
    const PAID: u8 = 1;
    const OVERDUE: u8 = 2;
    
    // Errors 
    const ERROR_INVALID_GENDER: u64 = 0;
    const ERROR_INVALID_ACCESS: u64 = 1;
    const ERROR_INSUFFICIENT_FUNDS: u64 = 2;
    const ERROR_INVALID_TIME : u64 = 3;
    const ERROR_INVESTMENT_ALREADY_PAID: u64 = 4;
    
    // Struct Definitions
    
    // Club struct
    struct Club {
        id: UID,
        name: String,
        club_type: String,
        rules: Vector<u8>,
        description: Vector<u8>,
        members: Table<address, Member>,
        investments: Table<address, Investment>,
        balance: Balance<SUI>,
        founding_date: u64,
        status: Vector<u8>,
    }
    
    // struct that represent Club Capability
    struct ClubCap {
        id: UID,
        club_id: ID,
    }

    // Member Struct
    struct Member {
        id: UID,
        club_id: ID,
        name: String,
        gender: u8,
        contact_info: String,
        number_of_shares: u64,
        pay: bool,
        date_joined: u64
    }

    // Investment Struct
    struct Investment {
        member_id: ID,
        amount_payable: u64,
        payment_date: u64,
        due_date: u64, // Added due date field for investments
        status: u8,
    }

    // Create a new Club
    public fun create_club(name: String, club_type: String, description: Vector<u8>, rules: Vector<u8>, clock: &Clock, open: Vector<u8>, ctx: &mut TxContext): (Club, ClubCap) {
        let id_ = new(ctx);
        let inner_ = uid_to_inner(&id_);
        let club = Club {
            id: id_,
            name,
            club_type,
            description,
            rules,
            status: open,
            founding_date: timestamp_ms(clock),
            members: Table::new(ctx),
            investments: Table::new(ctx),
            balance: zero()
        };

        let cap = ClubCap {
            id: new(ctx),
            club_id: inner_,
        };
        (club, cap)

    }
    
    // Add a member to the club
    public fun add_member(club_id: ID, name: String, gender: u8, contact_info: String, number_of_shares: u64, clock: &Clock, ctx: &mut TxContext): Member {
        assert!(gender == OTHER || gender == MALE || gender == FEMALE, ERROR_INVALID_GENDER); // Modified gender options
        Member {
            id: new(ctx),
            club_id,
            name,
            gender,
            contact_info,
            number_of_shares,
            date_joined: timestamp_ms(clock),
            pay: false
        }
    }
    
    // Generate investment amount for a member
    public fun generate_investment_amount(cap: &ClubCap, club: &mut Club, member: &Member, member_id: ID, amount_payable: u64, status: u8, date: u64, due_date: u64, clock: &Clock, ctx: &mut TxContext) {
        assert!(cap.club_id == id(club), ERROR_INVALID_ACCESS);
        
        // Calculate the total amount payable based on the number of shares
        let total_amount_payable = amount_payable * member.number_of_shares; // Corrected calculation
        
        let investment = Investment {
            member_id,
            amount_payable: total_amount_payable,
            status,
            payment_date: timestamp_ms(clock),
            due_date, // Added due date field
        };
        Table::add(&mut club.investments, sender(ctx), investment);
    }
    
    // Function for member to pay investment
    public fun pay_investment(club: &mut Club, investment: &mut Investment, member: &mut Member, coin: Coin<SUI>, clock: &Clock, ctx: &mut TxContext) {
        // Ensure the investment is not already paid or canceled
        assert!(investment.status == PENDING || investment.status == OVERDUE, ERROR_INVESTMENT_ALREADY_PAID);
        
        let investment = Table::remove(&mut club.investments, sender(ctx));
        assert!(coin::value(&coin) == investment.amount_payable, ERROR_INSUFFICIENT_FUNDS);
        assert!(timestamp_ms(clock) < investment.due_date, ERROR_INVALID_TIME); // Check if payment is before due date
        
        // Add the coin to the club balance
        let balance_ = into_balance(coin);
        join(&mut club.balance, balance_);
        // Investment Status
        member.pay = true;
        investment.status = PAID;
    }
    
    // Function to withdraw funds from the club
    public fun withdraw_funds(cap: &ClubCap, club: &mut Club, ctx: &mut TxContext) -> Coin<SUI> {
        assert!(cap.club_id == id(club), ERROR_INVALID_ACCESS);
        let balance_ = withdraw_all(&mut club.balance);
        let coin_ = from_balance(balance_, ctx);
        coin_
    }
    
    // Function to get the total balance of the club
    public fun get_balance(club: &Club) -> u64 {
        value(&club.balance)
    }
    
    // Function to check the payment and investment status of a member
    public fun check_member_and_investment_status(member: &Member, investment: &Investment) -> (bool, u8) {
        (member.pay, investment.status)
    }

}
