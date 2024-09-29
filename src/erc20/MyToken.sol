// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./ERC20.sol";

contract MyToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(_msgSender(), 1000 * 10 ** 18);
    }
}
