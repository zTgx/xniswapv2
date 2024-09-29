// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import "./XniswapV2Pair.sol";

contract XniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function newPair(address tokenA, address tokenB) public returns (address pairAddress) {
        require(tokenA != tokenB, "Identical Address");

        console.log(">>> tokenA: ", tokenA);
        console.log(">>> tokenB: ", tokenB);
        (address tokenA_, address tokenB_) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        console.log(">>> tokenA_: ", tokenA_);
        console.log(">>> tokenB_: ", tokenB_);

        require(tokenA_ != address(0), "Zero Address");
        require(pairs[tokenA_][tokenB_] == address(0), "Pair Exists");

        bytes memory bytecode = type(XniswapV2Pair).creationCode;
        // console.logBytes(bytecode);
        bytes32 salt = keccak256(abi.encodePacked(tokenA_, tokenB_));
        // console.logBytes32(salt);

        // assembly {
        //     pair := create2(0, add(bytecode, 20), mload(bytecode), salt)
        // }

        XniswapV2Pair pair = new XniswapV2Pair{salt: salt}();
        pairAddress = address(pair);
        require(pairAddress != address(0), "pair == address(0) -> Create2 failed on deploy!");

        console.log(">>> pairAddress: ", pairAddress);

        pair.initialize(tokenA_, tokenB_);

        console.log(">>> pair initialized");

        pairs[tokenA_][tokenB_] = pairAddress;
        pairs[tokenB_][tokenA_] = pairAddress;

        allPairs.push(pairAddress);

        console.log(">>> PairCreated! ");

        emit PairCreated(tokenA_, tokenB_, pairAddress, allPairs.length);
    }
}
