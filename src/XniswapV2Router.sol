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
    error SafeTransferFailed();

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public returns (uint256 amountA, uint256 amountB) {
        address pair = XniswapV2Lib.getPairAddress(address(factory), tokenA, tokenB);

        IXniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        (amountA, amountB) = IXniswapV2Pair(pair).burn(to);

        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountA < amountBMin) revert InsufficientBAmount();
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

    // Swaps an exact input amount (amountIn) for some output amount not smaller than amountOutMin.
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to)
        public
        returns (uint256[] memory amounts)
    {
        amounts = XniswapV2Lib.getAmountsOut(address(factory), amountIn, path);

        require(amounts[amounts.length - 1] >= amountOutMin, "InsufficientOutputAmount");

        _safeTransferFrom(
            path[0], msg.sender, XniswapV2Lib.getPairAddress(address(factory), path[0], path[1]), amounts[0]
        );

        _swap(amounts, path, to);
    }

    //Swapping unknown amount of input tokens for exact amount of output tokens.
    //This is an interesting use case and it’s probably not used very often but it’s still possible.
    function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to)
        public
        returns (uint256[] memory amounts)
    {
        amounts = XniswapV2Lib.getAmountsIn(address(factory), amountOut, path);
        require(amounts[amounts.length - 1] <= amountInMax, "ExcessiveInputAmount");

        _safeTransferFrom(
            path[0], msg.sender, XniswapV2Lib.getPairAddress(address(factory), path[0], path[1]), amounts[0]
        );

        _swap(amounts, path, to);
    }

    function _swap(uint256[] memory amounts, address[] memory path, address to_) internal {
        for (uint256 i; i < path.length; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = XniswapV2Lib.sortPair(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

            address to = i < path.length - 2 ? XniswapV2Lib.getPairAddress(address(factory), output, path[i + 2]) : to_;

            IXniswapV2Pair(XniswapV2Lib.getPairAddress(address(factory), input, output)).swap(
                amount0Out, amount1Out, to, ""
            );
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) private {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert SafeTransferFailed();
        }
    }
}
