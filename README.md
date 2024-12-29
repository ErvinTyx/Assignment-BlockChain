# Asignment Blockchain

    Gagamove is a decentralized delivery service platform controlled by a TimeLock smart contract that enables secure, efficient, and transparent scheduling of delivery-related transactions. The dApp can ensure that deliveries and associated actions such as payment releases, order confirmations or status updates are carried out only after a certain amount of time has passed.

	The TimeLock smart contract is the heart of the system that enables users to schedule future transactions while also providing advanced features like transaction cancellation and parameter modifications before execution. Each transaction is safely locked until the specified release time, preventing premature execution and increasing delivery reliability.

	The platform’s user interface displays queued transactions with detailed information, such as the contract address, function calls, input parameters and execution dates. This transparency allows users to easily track and manage their deliveries. Furthermore, multi-signature authentication is available for transactions involving high-value assets, which adds additional layers of security by requiring consensus from many parties before execution.

	The dApp can emit events such as “queued”, “executed” and “canceled”, allowing for real-time notifications on the status of delivery transactions. This ensures that all actions are traceable and verifiable, which builds confidence among users.

	By integrating TimeLock technology with blockchain’s immutable and transparent nature, the dApp enhances delivery services, providing a dependable and user-friendly solution for time-sensitive tasks.
---
# Overview
- [***Quick Start***](#requirements-installation)
- [***Why Foundry***](#why-choose-foundry)
- [***Other Commands***](#Other-command)
- [***References***](#reference)




# Requirements installation
### Setup Enviroment
#### 1. Install windows sub-system for Linux
To install wsl type this command in CMD or you can [read more](installation-readme/README.md).
```bash
wsl --install
```

#### 2. Installation for foundry into wsl
```bash
curl -L https://foundry.paradigm.xyz
```
2.1 Verify installation is completed
- Forge

```bash
forge --version
```
- Anvil
```bash
anvil --version
```

#### 3. installation git to clone this project
```bash
sudo apt-get install git
```

#### 4. installation make for easy shortcut command which are ready
```bash
sudo apt-get install make
```

#### 5. clone this project into your project directory
``` bash
git clone https://github.com/ErvinTyx/Assignment-BlockChain.git
```

#### 6. installation libary on this project
```bash
make build
```

#### 7. Start a ***local node*** 
``` bash
anvil
```

#### 8. To Deploy the script on anvil **open another WSL Terminal**
```bash
make deploy
```
---
---

# Why choose foundry
Foundry is a compelling choice for developing and testing smart contracts in Solidity and other Ethereum-based applications. Here are the key reasons to choose Foundry:



### ***1. Speed and Efficiency***
- **Lightweight and Fast:** Foundry is known for its performance. It compiles and runs tests significantly faster than other frameworks like Hardhat or Truffle.
- **Parallel Testing:** Foundry leverages Rust's performance to run tests in parallel, reducing testing time.



### ***2. Native Solidity Testing***
- **Solidity-first Approach:** Unlike frameworks that rely heavily on JavaScript or TypeScript for testing, Foundry allows developers to write tests directly in Solidity, ensuring seamless interaction with the contracts.
- **Built-in Assertions:** Foundry includes built-in utilities for testing Solidity contracts, such as `expectRevert`, `expectEmit`, and other assert functions.



### ***3. Advanced Debugging Tools***
- **Gas Reports:** Provides detailed gas usage reports for each function and test, helping developers optimize smart contracts.
- **Stack Traces:** Foundry includes clear and precise error messages with stack traces, making debugging easier.



### ***4. Cross-Platform and Interoperability***
- **Compatibility:** Foundry works well with existing tools like Hardhat, OpenZeppelin, and others, allowing easy integration into existing projects.
- **Cross-Chain Testing:** Foundry supports testing on various Ethereum-compatible networks, including Layer 2s.



### ***5. Easy Setup and Usage***
- **Simple Installation:** Foundry can be installed with a single command using `foundryup`, making it quick to set up.
- **Command-Line Interface (CLI):** Offers intuitive commands like `forge build`, `forge test`, and `forge script`.



### ***6. Modular Tooling***
- **Forge:** For building, testing, and interacting with smart contracts.
- **Cast:** For interacting with the Ethereum blockchain directly from the command line.
- **Anvil:** A local Ethereum development chain similar to Ganache.



### ***7. Security and Auditing***
- **Fuzz Testing:** Built-in support for fuzz testing helps identify edge cases and potential vulnerabilities.
- **Property-based Testing:** Allows developers to define properties that should always hold true for their contracts.



### ***8. Open Source and Community-Driven***
- **Actively Maintained:** Foundry is actively maintained and has a growing community, ensuring regular updates and improvements.
- **Developer-Focused:** Built by Paradigm, Foundry incorporates feedback from developers to meet real-world requirements.



### ***9. Robust Scripting***
- Foundry enables scripting in Solidity or Yul, making deployment and automation more straightforward compared to relying on external scripting languages.



### ***10. Future-Ready***
- **Supports the Latest EIPs:** Foundry is often quick to adopt new Ethereum Improvement Proposals (EIPs) and integrates them into its workflow.
---
---
# Other Command
## For cleaning cache project
```bash
forge clean
```
## For compile the project and install libary in this project
```bash
forge build
# or 
forge compile
```
## For Testing
Those testing function are in testing directory for testing purpose
#### To check all function work properly
```bash
forge test
```
#### To check a test on a specific function
```bash
forge test --mt <function_name> 
```

#### To check a test on a specific function with much more details
```bash
forge test --mt <function_name> -vvvvvv
```

#### To check the testing coverage in the contract
```bash
forge coverage
```
---
---

# Reference
### [Styling in solidity](https://docs.soliditylang.org/en/latest/style-guide.html#code-layout)
### [NatSpec Format](https://docs.soliditylang.org/en/latest/natspec-format.html)
### [Cheatsheet solidity](https://docs.soliditylang.org/en/latest/cheatsheet.html)
### [Data Feed in solidity](https://docs.chain.link/data-feeds)

Special Thank To [Patrick Collins](https://github.com/PatrickAlphaC)
[Blockchain Developer, Smart Contract, & Solidity Career Path - Powered By AI - Beginner to Expert Course
| Foundry Edition 2024 |](https://github.com/Cyfrin/foundry-full-course-cu?tab=readme-ov-file#-blockchain-developer-smart-contract--solidity-career-path---powered-by-ai---beginner-to-expert-course--foundry-edition-2024--)