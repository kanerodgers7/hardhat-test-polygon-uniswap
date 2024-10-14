// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPSTToken {
    function symbol() external view returns (string memory);

    function approve(address, uint256) external;

    function allowance(address, address) external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function transferFee(uint256) external view returns (uint256);

    function isPst() external pure returns (bool);
}
