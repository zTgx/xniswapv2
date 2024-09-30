// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/XniswapV2Pair.sol";
import "./ERC20Mintable.sol";

contract TestUser {
    function addLiquidity(
        address pairAddress_,
        address tokenAAddress_,
        address tokenBAddress_,
        uint256 amountA_,
        uint256 amountB_
    ) public {
        ERC20(tokenAAddress_).transfer(pairAddress_, amountA_);
        ERC20(tokenBAddress_).transfer(pairAddress_, amountB_);

        XniswapV2Pair(pairAddress_).mint(address(this));
    }

    function removeLiquidity(address pairAddress_) public {
        XniswapV2Pair(pairAddress_).burn(msg.sender);
    }
}
