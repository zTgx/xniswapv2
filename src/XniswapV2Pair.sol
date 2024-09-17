// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";

contract XniswapV2Pair is ERC20 {
    uint256 private reserve0;
    uint256 private reserve1;
    
    constructor() ERC20("XniswapV2 Pair", "XNIV2", 18) {}
}