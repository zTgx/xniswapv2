// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "../../src/XniswapV2Pair.sol";

contract Flashloaner {
    error InsufficientFlashLoanAmount();

    uint256 expectedLoanAmount;

    function flashloan(address pairAddress, uint256 amount0Out, uint256 amount1Out, address tokenAddress) public {
        if (amount0Out > 0) {
            expectedLoanAmount = amount0Out;
        }
        if (amount1Out > 0) {
            expectedLoanAmount = amount1Out;
        }

        XniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), abi.encode(tokenAddress));
    }

    function call(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) public {
        address tokenAddress = abi.decode(data, (address));
        uint256 balance = ERC20(tokenAddress).balanceOf(address(this));

        require(balance >= expectedLoanAmount, "InsufficientFlashLoanAmount");

        //TODO:
        //Do something with this balance...

        ERC20(tokenAddress).transfer(sender, balance);
    }
}
