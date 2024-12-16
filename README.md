# Enhancing Pension Asset Reinvestment via Blockchain Tokenization

A Hardhat-based project for developing, testing, and deploying smart contracts.

---

## **Prerequisites**

Before starting, ensure the following are installed on your system:

- **Node.js** (>= 12.0.0)
- **npm** or **yarn**
- **Hardhat** (installed via project dependencies)

---

## Basic Running

### 1. Clone the Repository
```
git clone https://github.com/yashmadhwal/Enhancing-Pension-Asset-Reinvestment-via-Blockchain-Tokenization.git
cd Enhancing-Pension-Asset-Reinvestment-via-Blockchain-Tokenization
```

### 2. Install Dependencies
Install all the necessary packages:
```
npm install
```

### 3. Compile Smart Contracts
Compile the Solidity smart contracts to prepare for deployment:
```
npx hardhat compile
```

### 4. Run Tests
Run the unit tests to verify the contracts' functionality:
```
npx hardhat test
```
---
## Deployment
For deploying contracts, the process is divided into two parts:

- **Local Deployment (for Experimentation):**
This step involves deploying the contract to a local Hardhat blockchain, ideal for testing and debugging purposes before deploying to a live network.

- **Network Deployment (to Testnet or Mainnet):**
Once the contract is tested locally, this step involves deploying it to a testnet or mainnet, such as Goerli or Ethereum Mainnet, using the appropriate network configuration.

### 1. Local deployment for experiment
Deploy your contracts locally on the Hardhat blockchain, which runs on your machine. You will need to open two separate terminal tabs for this process. One tab will be used to run the local Hardhat node, and the other will be used to execute the deployment script. **_Note_**: We use npm package [hardhat-deploy](https://www.npmjs.com/package/hardhat-deploy).
- First tab to run local node:
`npx hardhat node`
- Second tab to deploy smart contract on localnode:
`npx hardhat deploy --tags rm`

After deploying the smart contract, a folder named _deployments_ will be created, containing a file called _ReinvestmentManager.json_. This file includes the **contract address** of the deployed smart contract and its **ABI (Application Binary Interface)**. The provided _.ipynb_ file is already configured to automatically import these parameters, making it easy to interact with the deployed contract.


Now, open the Jupyter Notebook to run the experiment and interact with the deployed smart contract. Ensure that the local blockchain node is configured and connected via the appropriate **RPC URL**, and verify that the _deployments/ReinvestmentManager.json_ file is correctly set up for seamless execution:

```
jupyter notebook Experiments.ipynb
```



### 2. Network Deployment to Testnet or Mainnet
To deploy the contracts on a public or private network:

**Pre-requisite:**
- [RPC](https://docs.bscscan.com/misc-tools-and-utilities/public-rpc-nodes) for connecting to blockchain network
- API key from [Binance](https://www.binance.com/en/binance-api) for contract verification. 
_Note_: In this tutorial, we will be working with Binance, therefore the above links are for binance. You can choose any network that supports EVM (e.g. Ethereum), and then accordingly change the RPC and API keys
- Private key of wallet which will be deploying the contract. The best way is to have MetaMask wallet installed in your Browser.

**Deploying:**
1. Set up your private key and RPC URL in a _.env_ file.
    ```
    touch .env
     ```
    Open _.env_ by running `open .env` or opening by any code editor and paste the following and save it:
    ```
    privateKey = '#Your RPC key'
    PROVIDER_URL = '#Your API  Key'
    ```
    Replace the API keys with your keys. **_Note:_** This file will be ignored by git as it is included in the _.gitignore_ file.

2. Update the _hardhat.config.ts_ file with the appropriate network configuration. Replace _<network_name>_ with your preferred network name, and ensure that the corresponding URL is updated in the _.env_ file.
    ```
        <network_name>: {
            url: process.env.PROVIDER_URL,
            accounts: [process.env.privateKey],
          },
        },
    ```
3. Deploy the contract(s):
    `npx hardhat deploy --tags rm --network <network_name>`

4. Verify smart contract(s):
    `hardhat --network mainnet etherscan-verify --api-key <etherscan-apikey>`

---
## **Project Structure**

```plaintext
├── contracts/           # Contains Solidity smart contracts
├── scripts/             # Deployment scripts for smart contracts
├── test/                # Unit tests for verifying contract functionality
├── hardhat.config.ts    # Configuration file for Hardhat
├── package.json         # Defines project dependencies and npm scripts
├── .env                 # Stores environment variables for deployment
└── README.md            # Project documentation
```

---
## **Available Commands**

The following commands are available to help you set up, test, deploy, and verify the smart contracts:

| Command                  | Description                                   |
|--------------------------|-----------------------------------------------|
| `npm install`            | Install project dependencies                 |
| `npx hardhat compile`    | Compile Solidity contracts                   |
| `npx hardhat test`       | Run all unit tests                           |
| `npx hardhat node`       | Start a local Hardhat blockchain             |
| `npx hardhat deploy`       | Execute deployment or other custom scripts   |
| `npx hardhat verify`     | Verify deployed contracts on block explorers |

---

## Contributing

Feel free to fork this repository, create a branch, and submit a pull request. Contributions are welcome!

---

## License
This project is licensed under the MIT License. _This version is comprehensive, covering all aspects including setup, deployment, verification, and key commands. It ensures clarity and usability for developers working with the project._

---


