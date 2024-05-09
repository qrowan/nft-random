## Getting Started

### Install global tools
* Look here to install yarn : https://classic.yarnpkg.com/lang/en/docs/install/#mac-stable
* Look here to install foundry : https://book.getfoundry.sh/getting-started/installation
* modify .env.example to .env with your KEYs

### Install packages and compile contracts
```sh
yarn
forge install
foundryup # update foundry
forge build # compile contracts
source .env
```

## Test

```sh
forge test
forge test --mt testDeploy -vv # example
```

## Deploy
```sh
forge script script/Deploy.s.sol:Deploy --broadcast --verify -vvvv
# after modifying Constant.sol with newly deployed address, 
# the script below tests until the final NFT URI be decided.
# It requires some LINK tokens in your wallet.
forge script script/Purchase.s.sol:Purchase --broadcast -vvvv
forge script script/Purchase.s.sol:StartReveal --broadcast -vvvv
forge script script/Purchase.s.sol:Reveal --broadcast -vvvv

```
## Check Live Data Deployed
```sh
forge test --mt testShowLiveData -vv
```

## Deployed Info
```solidity
    uint64 public constant SUBSCRIPTION_ID = 11629;
    address public constant DEPLOYER = 0xA9f0C55a0d8FC0bcE1027e60b42DcbF5D6D7b56d;
    address public constant PROXY_ADMIN = 0x31d9b6E1A0a76627cFe48A8d03995F621d5fB017;
    address public constant NFT = 0x08AE0f0a7DcA7b4dDa12d682934eFF48F3241F09;
    address public constant REAL_NFT_FOR_SEPERATED_COLLECTION = 0x510A6E848B33E1461A5BA2a10D73fB7b806A398d;
```
* Chain : Sepolia testnet (ChainId : 11155111)
* wallet used (deployer)      : 0xA9f0C55a0d8FC0bcE1027e60b42DcbF5D6D7b56d
* chainlink VRF2 Subscription : https://vrf.chain.link/sepolia/11624
* etherscan log               : https://sepolia.etherscan.io/address/0xA9f0C55a0d8FC0bcE1027e60b42DcbF5D6D7b56d
* wakatime link               : https://wakatime.com/@Rowan/projects/uhqvyfxwec?start=2024-05-05&end=2024-05-09
