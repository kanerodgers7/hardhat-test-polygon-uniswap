# Dex development details

This page provides general information about the used contract and required files around the contract. All contract source codes can be found under the _src_ folder.

## Contracts overview

The following are the main contract features:

- Fork of Uniswap V3 for Polygon.

- Tiered transaction fees.
- Allow users add arbitrary coin/ERC20 Pools.
- Concentrated liquidity model
  - Default range of +/-20% of current price
  - Option for custom ranges (for a fee)
- Yield and dividend features:
  - Auto-compounds yields into the pool
  - Provides harvestable rewards for LPs (native coin or token e.g. HKD)

## Unit tests

The contracts are covered by unit tests. Both happy paths and unhappy
paths should be sufficiently covered.

You can run unit tests with Hardhat: `npx hardhat test`.

## Development

To start development on the project, you should do (at least) the following:

1. Install packages: `npm i`

1. Compile contracts: `npx hardhat compile`
1. Run unit tests: `npx hardhat test`

## Deployment

A sample deployment script has been created. It deploys all the contracts and also verifies them in Etherscan. You can run the script by following these steps:

1. Set up environment variables in a file called `.env`. There is an example of the settings in `.env.example`.
1. Run script with `npx hardhat run scripts/deploy.ts --network [network]`

   - base-amoy: This is for Polygon test Network
   - base-polygon: This is for Poygon main Network
   - sepolia: This is for Ethereum test Network
   - base-ethereum: This is for Ethereum main Network
   - base-binance: This is for Binance main Network

## Verification

- Create Polygon scan API KEY(update .env file) and run the script.

  **_`npx hardhat verify --network [network] deployed_address args`_**

- here is example

  `npx hardhat verify --network base-amoy 0x1A8F35390151042886dDf2221886AAc25E689b3F`

## Latest Deployment

The latest test deployment to Amoy network is following

- [Dex Factory](https://amoy.polygonscan.com/address/0x1A8F35390151042886dDf2221886AAc25E689b3F)

- [Dex QuoterFact](https://amoy.polygonscan.com/address/0x151915948daF2D0d7a80d1889920586ef13bb359)
- [Dex ManagerFact](https://amoy.polygonscan.com/address/0x019614711545C39Efc47F803B0759bc316691B88)
