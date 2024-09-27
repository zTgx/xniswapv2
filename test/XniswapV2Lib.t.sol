// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {XniswapV2Lib} from "../src/XniswapV2Lib.sol";

contract XniswapV2LibTest is Test {
    function setUp() public pure override {
        console.log("##########################");
        console.log("XniswapV2Lib Test");
        console.log("##########################");
    }

    function testMin() public pure {
        assertEq(XniswapV2Lib.min(1, 2), 1);
        assertEq(XniswapV2Lib.min(2, 1), 1);
    }
}
