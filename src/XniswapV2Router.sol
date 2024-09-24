// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "solmate/tokens/ERC20.sol";
import {XniswapV2Lib} from "./XniswapV2Lib.sol";
import "./IXniswapV2Pair.sol";
import "./IXniswapV2Factory.sol";

contract XniswapV2Router {
    error InsufficientAAmount();
    error InsufficientBAmount();

    IXniswapV2Factory factory;

    constructor(address factoryAddress) {
        factory = IXniswapV2Factory(factoryAddress);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADeposit,
        uint256 amountBDeposit,
        uint256 amountAMin,
        uint256 amountBMin,
        address to //the address that receives LP-tokens
    ) public returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (factory.pairs(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }

        (amountA, amountB) = _calcLiquidity(tokenA, tokenB, amountADeposit, amountBDeposit, amountAMin, amountBMin);

        address pairAddress = XniswapV2Lib.getPairAddress(address(factory), tokenA, tokenB);

        SafeTransferLib.safeTransferFrom(ERC20(tokenA), msg.sender, pairAddress, amountA);
        SafeTransferLib.safeTransferFrom(ERC20(tokenB), msg.sender, pairAddress, amountB);

        liquidity = IXniswapV2Pair(pairAddress).mint(to);
    }

    function _calcLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADeposite,
        uint256 amountBDeposite,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = XniswapV2Lib.getReserves(address(factory), tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADeposite, amountBDeposite);
        } else {
            uint256 amountBOptimal = XniswapV2Lib.quote(amountADeposite, reserveA, reserveB);

            if (amountBOptimal <= amountBDeposite) {
                if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADeposite, amountBOptimal);
            } else {
                uint256 amountAOptimal = XniswapV2Lib.quote(amountBDeposite, reserveB, reserveA);
                assert(amountAOptimal <= amountADeposite);

                if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDeposite);
            }
        }
    }
}
