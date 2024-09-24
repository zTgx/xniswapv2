// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {XniswapV2Pair} from "./XniswapV2Pair.sol";
import "./IXniswapV2Pair.sol";
import "./IXniswapV2Factory.sol";

library XniswapV2Lib {
    error InsufficientAmount();
    error InsufficientLiquidity();

    function sortPair(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getPairAddress(address factoryAddress, address tokenA, address tokenB)
        internal
        pure
        returns (address pairAddress)
    {
        (address tokenA_, address tokenB_) = sortPair(tokenA, tokenB);

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

    function quote(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        return (amountIn * reserveOut) / reserveIn;
    }
}
