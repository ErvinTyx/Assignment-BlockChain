# Gagamove Delivery DApp
This project is a decentralized application(DApp) for scheduling, tracking, modifying, and canceling delivery orders. The application integrates with MetaMask and utilizes the ether.js library for blockchain interactions.

## Features

1. **Connect Wallet:** 
   - Connects to the user's Ethereum wallet using Metamask.
   - Validates wallet connection and ensure the wallet is unlocked.

2. **Delivery Scheduling**
   - Allows users to schedule deliveries by specifying pickup and delivery locations, as well as a timelock for the delivery.
   - Dynamically calculates delivery costs in USD and ETH based on distance( 3 USD per km).

3. **Delivery Tracking**
   - Fetches real-time delivery details using the delivery ID.
   - Displays information such as user address, locations, price, and status.

4. **Delivery Modification**
   - Enables user to modify the delivery schedule if needed.
   - Fetches and validates existing delivery details.

5. **Owner and Contract Information**
   - Fetches and displays the smart contract owner's address for transparency.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js**
- **Metamask** (browser extension)
- **Ethereum wallet** with testnet/mainnet Ether for transactions

## Installation

### Clone the repository:

```bash
git clone https:github.com/your-repo-name/gagamove.git
cd gagamove
```
### Install dependencies:

```bash
npm install
```

### Serve the application:

```bash
npx serve .
```

### Open the application in your browser:

```arduino
http://localhost:3000
```

## Usage

### Connect Wallet:

- Click the **"Connect Wallet"** button to link your MetaMask wallet.
- Ensure MetaMask is installed and logged in.

### Add Custom Network:

To use the Gochain network, configure Metamask as follows:

1. Open Metamask and go to **Settings** > **Networks** > **Add Network**.
2. Enter the following details:
   - **Network Name**: Gochain
   - **UR;**:`http://127.0.0.1:8545`
   - **Chain ID** :`31337`
   - **Symbol** :GO
3. Save the network settings.

### Schedule a Delivery

1. Enter pickup and delivery locations.
2. Specify the delivery time(must be at least 2 hours in the future).
3. Review the calculated price(in USD and ETH).
4. Click **"Place Order"** to confirm and send the transaction to the blockchain.

### Track an Order:

1. Navigate to the **"Track Order"** section.
2. Enter the delivery ID and click **"Track Order"**.
3. View real-time delivery details.

### Modify an Order:

1. Navigate to the **"Modify Order"** section.
2. Enter the delivery ID to fetch existing details.
3. Specify the new schedule and click **"Update Schedule"**.

### Cancel an Order:

1. Navigate to the **"Cancel Order"** section.
2. Enter the delivery ID and click **"Cancel Order"**.

## Smart Contract Interaction

The DApp interacts with a smart contract deployed on the Ethereum blockchain. The contract's ABI and address are stored in `abi.js` , and `ethers.js` handles all blockchain communication.

### Smart Contract Functions Used:
- `scheduledDelivery`: Schedules a new delivery.
- `getDelivery`: Fetches delivery details.
- `modifyDelivery`: Modifies an existing delivery.
- `getOwner`: Retrieves the owner of the smart contract.

## Folder Structure

```plaintext
project/
├── index.html       # Main HTML file
├── index.css        # Stylesheet for the application
├── index.js         # Main JavaScript file for DApp logic
├── ethers.js        # Ethers.js integration
├── abi.js           # Smart contract ABI and address
└── README.md        # Documentation
```

## Konow Issues and Limitations

- **MetaMask Compatibility** : Ensure Metamask is installed and the Ethereum network is properly selected.
- **Static Exchange Rate**: Currently, the ETH/USD exhange rate is hardcoded. Consider using a real-time API for dynamic updates.
- **Distance Calculation** :  For counting the distance, it is a random distance value, it lead to inaccurate route planning and delivery cost estimation.

## Future Enhacements

- Dynamic gas price estimation.
- Real-time ETH/USD price integration
- Improve UI/UX with loading indicators.
- Enhanced error handling for better user feedback.
- Distance count automatically for the system.




