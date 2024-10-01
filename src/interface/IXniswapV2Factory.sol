// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IXniswapV2Factory {
    function pairs(address, address) external pure returns (address);
    function newPair(address, address) external returns (address);
}
