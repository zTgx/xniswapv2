// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {XniswapV2Pair} from "./XniswapV2Pair.sol";
import "./IXniswapV2Pair.sol";
import "./IXniswapV2Factory.sol";

library XniswapV2Lib {
    error InsufficientAmount();
    error InsufficientLiquidity();

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function sortPair(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getPairAddress(address factoryAddress, address tokenA, address tokenB)
        internal
        pure
        returns (address pairAddress)
    {
        (address tokenA_, address tokenB_) = sortPair(tokenA, tokenB);

        // create2:
        // https://eips.ethereum.org/EIPS/eip-1014
        // keccak256( 0xff ++ address ++ salt ++ keccak256(init_code))
        pairAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factoryAddress,
                            keccak256(abi.encodePacked(tokenA_, tokenB_)),
                            keccak256(type(XniswapV2Pair).creationCode)
                        )
                    )
                )
            )
        );
    }

    function getReserves(address factoryAddress, address tokenA, address tokenB)
        public
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, address token1) = sortPair(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) =
            IXniswapV2Pair(getPairAddress(factoryAddress, token0, token1)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // this function calculates output amount based on input amount and pair reserves.
    function quote(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        return (amountIn * reserveOut) / reserveIn;
    }

    //reserveIn : the amount of token A in the pool
    //reserveOut: the amount of token B in the pool
    //amountIn  : Need to deposite <amountIn of token A>
    //amountOut : the desired amount of token B to receive
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset.
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        if (amountOut == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;

        return (numerator / denominator) + 1;
    }

    // given an input amount of an asset and pair reserves,
    // returns the maximum output amount of the other asset.
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }

    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path //memory - variable is in memory and it exists while a function is being called
    ) public returns (uint256[] memory) {
        require(path.length >= 2, "Invalid Path");

        // Index from 0
        uint256[] memory amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }

        return amounts;
    }

    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        public
        returns (uint256[] memory)
    {
        require(path.length >= 2, "Invalid Path");

        uint256[] memory amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }

        return amounts;
    }
}
