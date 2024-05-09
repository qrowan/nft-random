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
```

## Test

```sh
forge test
forge test --mt testDeploy -vv # example
```

#
