# CoInvestClub

## Overview

The `co_invest_club` is designed for managing investment clubs on the Sui blockchain. This module enables the creation of clubs, addition of members, management of investments, and handling of transactions within a secure and decentralized platform.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Run a local network](#run-a-local-network)
- [Configure connectivity to a local node](#configure-connectivity-to-a-local-node)
- [Create addresses](#create-addresses)
- [Get localnet SUI tokens](#get-localnet-SUI-tokens)
- [Build and publish a smart contract](#build-and-publish-a-smart-contract)
   - [Build package](#build-package)
   - [Publish package](#publish-package)
- [Structs](#structs)
  - [Club](#club)
  - [Member](#member)
  - [Investment](#investment)
- [Core Functionalities](#core-functionalities)
  - [Creating a Club](#creating-a-club-)
  - [Adding a Member](#adding-a-member-)
  - [Generate Investment](#generate_investment_amount-)
  - [Pay Investment](#pay_investment-)
  - [Withdraw Funds](#withdraw_funds-)
  - [Get the Club's balance](#get_balance-)
  - [Check member and investment status](#check_member_and_investment_status-)

## Prerequisites
1. Install dependencies by running the following commands:
   
   - `sudo apt update`
   
   - `sudo apt install curl git-all cmake gcc libssl-dev pkg-config libclang-dev libpq-dev build-essential -y`

2. Install Rust and Cargo
   
   - `curl https://sh.rustup.rs -sSf | sh`
   
   - source "$HOME/.cargo/env"

3. Install Sui Binaries
   
   - run the command `chmod u+x sui-binaries.sh` to make the file an executable
   
   execute the installation file by running
   
   - `./sui-binaries.sh "v1.21.0" "devnet" "ubuntu-x86_64"` for Debian/Ubuntu Linux users
   
   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-x86_64"` for Mac OS users with Intel based CPUs
   
   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-arm64"` for Silicon based Mac 

For detailed installation instructions, refer to the [Installation and Deployment](#installation-and-deployment) section in the provided documentation.

## Installation

1. Clone the repository:
   ```sh
   https://github.com/mukoyanichris/Co-Invest-Club.git
   ```
2. Navigate to the working directory
   ```sh
   cd co_invest_club
   ```
## Run a local network
To run a local network with a pre-built binary (recommended way), run this command:
```
RUST_LOG="off,sui_node=info" sui-test-validator
```
## Configure connectivity to a local node
Once the local node is running (using `sui-test-validator`), you should the url of a local node - `http://127.0.0.1:9000` (or similar).
Also, another url in the output is the url of a local faucet - `http://127.0.0.1:9123`.

Next, we need to configure a local node. To initiate the configuration process, run this command in the terminal:
```
sui client active-address
```
The prompt should tell you that there is no configuration found:
```
Config file ["/home/codespace/.sui/sui_config/client.yaml"] doesn't exist, do you want to connect to a Sui Full node server [y/N]?
```
Type `y` and in the following prompts provide a full node url `http://127.0.0.1:9000` and a name for the config, for example, `localnet`.

On the last prompt you will be asked which key scheme to use, just pick the first one (`0` for `ed25519`).

After this, you should see the ouput with the wallet address and a mnemonic phrase to recover this wallet. You can save so later you can import this wallet into SUI Wallet.

Additionally, you can create more addresses and to do so, follow the next section - `Create addresses`.


### Create addresses
For this tutorial we need two separate addresses. To create an address run this command in the terminal:
```
sui client new-address ed25519
```
where:
- `ed25519` is the key scheme (other available options are: `ed25519`, `secp256k1`, `secp256r1`)

And the output should be similar to this:
```
╭─────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Created new keypair and saved it to keystore.                                                   │
├────────────────┬────────────────────────────────────────────────────────────────────────────────┤
│ address        │ 0x05db1e318f1e4bc19eb3f2fa407b3ebe1e7c3cd8147665aacf2595201f731519             │
│ keyScheme      │ ed25519                                                                        │
│ recoveryPhrase │ lava perfect chef million beef mean drama guide achieve garden umbrella second │
╰────────────────┴────────────────────────────────────────────────────────────────────────────────╯
```
Use `recoveryPhrase` words to import the address to the wallet app.


### Get localnet SUI tokens
```
curl --location --request POST 'http://127.0.0.1:9123/gas' --header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "<ADDRESS>"
    }
}'
```
`<ADDRESS>` - replace this by the output of this command that returns the active address:
```
sui client active-address
```

You can switch to another address by running this command:
```
sui client switch --address <ADDRESS>
```

## Build and publish a smart contract

### Build package
To build tha package, you should run this command:
```
sui move build
```

If the package is built successfully, the next step is to publish the package:
### Publish package
```
sui client publish --gas-budget 100000000 --json
` - `sui client publish --gas-budget 1000000000`
```
## Structs

### Club

```
struct Club has key, store {
    id: UID,
    name: String,
    club_type: String,
    rules: vector<u8>,
    description: vector<u8>,
    members: Table<address, Member>,
    investments: Table<address, Investment>,
    balance: Balance<SUI>,
    founding_date: u64,
    status: vector<u8>,
}
```
### Member

```
struct Member has key, store {
    id: UID,
    club_id: ID,
    name: String,
    gender: u8,
    contact_info: String,
    number_of_shares: u64,
    pay: bool,
    date_joined: u64
}
```
### Investment

```
struct Investment has copy, store, drop {
    member_id: ID,
    amount_payable: u64,
    payment_date: u64,
    status: u8,
}
```
## Core Functionalities

### creating-a-club 🏢

- **Parameters**:
  - name: `String`
  - club_type: `String`
  - description: `vector<u8>`
  - rules: `vector<u8>`
  - clock: `&Clock`
  - open: `vector<u8>`
  - ctx: `&mut TxContext`

- **Description**: Initializes a new investment club with specified details and governance rules.

- **Errors**:
  - **ERROR_INVALID_ACCESS**: if unauthorized access is detected during the creation process.

### adding-a-member 👥

- **Parameters**:
  - club_id: `ID`
  - name: `String`
  - gender: `u8`
  - contact_info: `String`
  - number_of_shares: `u64`
  - clock: `&Clock`
  - ctx: `&mut TxContext`

- **Description**: Adds a new member to the investment club, assigning shares and recording membership details.

- **Errors**:
  - **ERROR_INVALID_GENDER**: if the gender specified is not recognized.

### generate_investment_amount 💵

- **Parameters**:
  - cap: `&ClubCap`
  - club: `&mut Club`
  - member: `&Member`
  - member_id: `ID`
  - amount_payable: `u64`
  - status: `u8`
  - date: `u64`
  - clock: `&Clock`
  - ctx: `&mut TxContext`

- **Description**: Calculates and records an investment amount for a member based on their share count.

- **Errors**:
  - **ERROR_INVALID_ACCESS**: if the member trying to invest does not have the proper capabilities.

### pay_investment 💸

- **Parameters**:
  - club: `&mut Club`
  - investment: `&mut Investment`
  - member: `&mut Member`
  - coin: `Coin<SUI>`
  - clock: `&Clock`
  - ctx: `&mut TxContext`

- **Description**: Processes the payment of a member's investment into the club's funds.

- **Errors**:
  - **ERROR_INSUFFICIENT_FUNDS**: if the coin provided does not cover the investment amount.
  - **ERROR_INVALID_TIME**: if the payment is made past the due date.

### withdraw_funds 🏦

- **Parameters**:
  - cap: `&ClubCap`
  - club: `&mut Club`
  - ctx: `&mut TxContext`

- **Description**: Withdraws available funds from the club's balance, converting them into a coin.

- **Errors**:
  - **ERROR_INVALID_ACCESS**: if the action is attempted by someone without the necessary club capabilities.

### get_balance 💹

- **Parameters**:
  - club: `&Club`

- **Description**: Retrieves the current balance of the club's funds.

### check_member_and_investment_status 📊

- **Parameters**:
  - member: `&Member`
  - investment: `&Investment`

- **Description**: Checks and returns the payment and investment status of a member.

- **Errors**:
  - **ERROR_INVALID_ACCESS**: if the check is performed without proper authorization.

