// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// import {console} from "forge-std/console.sol";
import "./XniswapV2Pair.sol";
import "./utils/XniswapV2Lib.sol";
import "./interface/IXniswapV2Factory.sol";

contract XniswapV2Factory is IXniswapV2Factory {
    // PairAddress => (TokenAddress, TokenAddress)
    mapping(address => mapping(address => address)) public pairs;

    // Store all new created pairAddress
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function newPair(address tokenA, address tokenB) public returns (address pairAddress) {
        require(tokenA != tokenB, "NewPair: Identical Address");

        (address tokenA_, address tokenB_) = XniswapV2Lib.sortTokenAddress(tokenA, tokenB);
        require(tokenA_ != address(0), "Zero Address");
        require(pairs[tokenA_][tokenB_] == address(0), "Pair Exists");

        // By using create2
        bytes32 salt = keccak256(abi.encodePacked(tokenA_, tokenB_));
        XniswapV2Pair pair = new XniswapV2Pair{salt: salt}();
        pairAddress = address(pair);
        require(pairAddress != address(0), "pairAddress == address(0) : Create2 failed on deploy!");

        // Initialize pair with sorted tokens address
        pair.initialize(tokenA_, tokenB_);

        // Store pairs
        pairs[tokenA_][tokenB_] = pairAddress;
        pairs[tokenB_][tokenA_] = pairAddress;
        allPairs.push(pairAddress);

        emit PairCreated(tokenA_, tokenB_, pairAddress, allPairs.length);
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}
