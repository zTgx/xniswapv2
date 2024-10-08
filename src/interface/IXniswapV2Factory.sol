// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IXniswapV2Factory {
    function newPair(address, address) external returns (address);
    function pairs(address, address) external view returns (address);
    function allPairs(uint256) external view returns (address);
    function allPairsLength() external view returns (uint256);
}
