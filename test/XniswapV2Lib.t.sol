// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {XniswapV2Lib} from "../src/XniswapV2Lib.sol";
import "./mocks/ERC20Mintable.sol";
import {XniswapV2Factory} from "../src/XniswapV2Factory.sol";
import {XniswapV2Pair} from "../src/XniswapV2Pair.sol";

contract XniswapV2LibTest is Test {
    XniswapV2Factory factory;
    XniswapV2Pair pair;
    ERC20Mintable tokenA;
    ERC20Mintable tokenB;

    function setUp() public {
        console.log("##########################");
        console.log("XniswapV2Lib Test");

        console.log(">>> address: ", address(this));

        factory = new XniswapV2Factory();

        tokenA = new ERC20Mintable("TokenA", "TKNA");
        tokenB = new ERC20Mintable("TokenB", "TKNB");

        tokenA.mint(10 ether, address(this));
        console.log("address(this) balance TokenA: ", ERC20(tokenA).balanceOf(address(this)));

        tokenB.mint(10 ether, address(this));
        console.log("address(this) balance TokenB: ", ERC20(tokenB).balanceOf(address(this)));

        address pairAddress = factory.newPair(address(tokenA), address(tokenB));
        console.log(">>> pairAddress: ", pairAddress);

        pair = XniswapV2Pair(pairAddress);

        console.log("##########################");
    }

    function testMin() public pure {
        assertEq(XniswapV2Lib.min(1, 2), 1);
        assertEq(XniswapV2Lib.min(2, 1), 1);
    }

    function testSortTokenAddress() public pure {
        address tokenA = 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a;
        address tokenB = 0x2e234DAe75C793f67A35089C9d99245E1C58470b;

        (address tokenA_, address tokenB_) = XniswapV2Lib.sortTokenAddress(tokenA, tokenB);
        assertEq(tokenA_, tokenB);
        assertEq(tokenB_, tokenA);
    }

    function testGetReserves() public {
        tokenA.transfer(address(pair), 1.1 ether);
        tokenB.transfer(address(pair), 0.8 ether);

        pair.mint(address(this));

        (uint256 reserve0, uint256 reserve1) =
            XniswapV2Lib.getReserves(address(factory), address(tokenA), address(tokenB));

        assertEq(reserve0, 1.1 ether);
        assertEq(reserve1, 0.8 ether);
    }
}
