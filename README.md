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

## Frontend Collaborations

- Reorder of the Token A and Token B addresses is required:
  ```javascript
  if (token0.address.toUpperCase() > token1.address.toUpperCase()) {
    let temp = token0;
    token0 = token1;
    token1 = temp;
  }
  ```
- Customized price range should be provided as `starting tick point` and `ending tick point`

## Latest Deployment

The latest test deployment to Amoy network is following

- [Dex Factory](https://amoy.polygonscan.com/address/0x1901C8eb95DFbB5fF298c71262611B50483E25Ad)

- [Dex QuoterFact](https://amoy.polygonscan.com/address/0x58464BAF76165a2c86e49eb46995c94B32498DF9)
- [Dex ManagerFact](https://amoy.polygonscan.com/address/0x6DE99046531728De9763cCeD37d8014a46B1BD4a)

## Usage

Description for the usage of Dex contract.

- Creat a Pool

  - `createPool` is a function for creating a pool
  - there are 4 input parameters
    - `tokenA`: first token address like `0x6D502C7Ec05e89aDDBF2B0Cf2Eea28a1534Dd362`
    - `tokenB`: second token address like `0xF8bb0a8fd3A54b5B35Cc9E75214eD851C923E9E5`
    - `fee`: this is representing fee choice of swaping.
      there are 4 tired fee options: `100` (0.01%), `500` (0.05%), `3000` (0.3%), `10000` (1%)
    - `currentPrice`: this is the price ratio between tokenA and tokenB.
      this value is calculated like
      ```
      currentPrice = tokenB.price / tokenA.price * 10 ^ 10
      ```
      **Warning**: becareful for the order of tokenA and tokenB.
      Refer this: [Jump to Frontend Collaborations](#frontend-collaborations)

- Add Liquidity

  - `mint` function is for Adding Liquidity.
  - there are 9 parameters are required.
    - `tokenA` is for the ordered first token address.
    - `tokenB` is for the ordered second token address.
    - `fee` is representing pool fee amount.
    - `lowerTick` is the starting tick point.
    - `upperTick` is the eding tick point.
    - `amount0Desired` this is the desired tokenA amount
    - `aomount1Desired` this is the desired tokenB amount
    - `amount0Min` this is minimum amount for tokenA
    - `amount1Min` thi is minimum amount for tokenB

  **Warning**:

  - `tokenA`, `tokenB` and `fee` are used to indicate the pool contract.
  - default `lowerTick` and `upperTick` are found from `getStandardSlot0()`

- Swap

  - `swapSingle` is for swapping tokens for existing token pairs.
  - there are 4 input parameters
    - `tokenIn`: this is for token address that will be swapped.
    - `tokenOut` : this is token addresss that will get after swapping.
    - `fee` : this is swaping fee. this would be used to indicate the pool together with `tokenIn` and `tokenOut`

- Remove Liquidity

  - `burn` is the function for removing liquidity.
  - there are 6 input parameters
    - `tokenA`
    - `tokenB`
    - `fee`
    - `lowerTick`
    - `upperTick`
    - `liquidity` this is the amount for withdrawal of liquidity

  **Warning**:

  - `lowerTick` and `upperTick` should be same as adding liquidity unless it would fail.
  - if the `liquidity` is above the actual amount of LP's liquidity amount, it will withdraw his total amount.

- Yield Farming

  - `collect` is the function for yielding accumulated liquid revenue.
  - there are 8 input parameters
    - `tokenA`
    - `tokenB`
    - `fee`
    - `recipient` this is wallet address for receiving the liquidity revenue.
    - `lowerTick`
    - `upperTick`
    - `amount0Desired`
    - `amount1Desired`

- Yield Owner Fee
  - `collectOwnerFee` is the function for collecting accumulated Admin fee.
  - this is similar to Yield Farmining

**Precaution**

- before starting the transactions like mint and swap you need to make sure that you approved allowance to the contract for the amount you want to transfer.
