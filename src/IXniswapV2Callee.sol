// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IXniswapV2Callee {
    // the caller contract to implement call function that receives:
    // sender address, first output amount, second output amount, and the new data parameter.
    function call(address sender, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external;
}
