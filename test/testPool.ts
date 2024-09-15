import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-waffle';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';
import { expect } from 'chai';
import { ethers, network } from 'hardhat';

import { UniswapV3Pool } from '../typechain/pulse';

describe("Test the Pool Contract", async () => {
    let pool: UniswapV3Pool;
});