// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./XniswapV2Pair.sol";

contract XniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function newPair(address tokenA, address tokenB) public returns (address pair) {
        require(tokenA != tokenB, "Identical Address");

        (address tokenA_, address tokenB_) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(tokenA_ != address(0), "Zero Address");
        require(pairs[tokenA_][tokenB_] == address(0), "Pair Exists");

        bytes memory bytecode = type(XniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA_, tokenB_));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        XniswapV2Pair(pair).initialize(tokenA_, tokenB_);

        pairs[tokenA_][tokenB_] = pair;
        pairs[tokenB_][tokenA_] = pair;

        allPairs.push(pair);

        emit PairCreated(tokenA_, tokenB_, pair, allPairs.length);
    }
}
