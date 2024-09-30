// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import "./XniswapV2Pair.sol";
import "./utils/XniswapV2Lib.sol";

contract XniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function newPair(address tokenA, address tokenB) public returns (address pairAddress) {
        require(tokenA != tokenB, "Identical Address");

        (address tokenA_, address tokenB_) = XniswapV2Lib.sortTokenAddress(tokenA, tokenB);

        require(tokenA_ != address(0), "Zero Address");
        require(pairs[tokenA_][tokenB_] == address(0), "Pair Exists");

        // By using create2
        bytes32 salt = keccak256(abi.encodePacked(tokenA_, tokenB_));
        XniswapV2Pair pair = new XniswapV2Pair{salt: salt}();

        pairAddress = address(pair);
        require(pairAddress != address(0), "pair == address(0) -> Create2 failed on deploy!");

        pair.initialize(tokenA_, tokenB_);

        pairs[tokenA_][tokenB_] = pairAddress;
        pairs[tokenB_][tokenA_] = pairAddress;

        allPairs.push(pairAddress);

        emit PairCreated(tokenA_, tokenB_, pairAddress, allPairs.length);
    }
}
