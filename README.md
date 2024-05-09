# <h1 align="center"> Forge Template </h1>

**Template repository for getting started quickly with Foundry projects**

![Github Actions](https://github.com/foundry-rs/forge-template/workflows/CI/badge.svg)

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
```
## Check Live Data Deployed
```sh
forge test --mt testShowLiveData -vv
```
* wallet used (deployer)      : 0xA9f0C55a0d8FC0bcE1027e60b42DcbF5D6D7b56d
* chainlink VRF2 Subscription : https://vrf.chain.link/sepolia/11624
* etherscan log               : https://sepolia.etherscan.io/address/0xA9f0C55a0d8FC0bcE1027e60b42DcbF5D6D7b56d

