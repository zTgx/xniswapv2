// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {XniswapV2Pair} from "../src/XniswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";
import "./mocks/Flashloaner.sol";

contract XniswapV2PairTest is Test {
    XniswapV2Pair public pair;
    ERC20Mintable tokenA;
    ERC20Mintable tokenB;

    function setUp() public {
        tokenA = new ERC20Mintable("Token A", "TKNA");
        tokenB = new ERC20Mintable("Token B", "TKNB");
        pair = new XniswapV2Pair(address(tokenA), address(tokenB));

        tokenA.mint(10 ether, address(this));
        tokenB.mint(10 ether, address(this));
    }

    function assertReserves(uint112 expectedReserveA, uint112 expectedReserveB) internal view {
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        assertEq(reserveA, expectedReserveA, "unexpected reserveA");
        assertEq(reserveB, expectedReserveB, "unexpected reserveB");
    }

    function testFlashloan() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);

        pair.mint(address(this));

        uint256 flashloanAmount = 0.1 ether;
        uint256 flashloanFee = (flashloanAmount * 1000) / 997 - flashloanAmount + 1;
        console.log("flashload fee: ", flashloanFee);

        Flashloaner fl = new Flashloaner();

        console.log("Flashloaner address: ", address(fl));

        tokenA.transfer(address(fl), flashloanFee);

        fl.flashloan(address(pair), 0, flashloanAmount, address(tokenA));

        assertEq(tokenA.balanceOf(address(fl)), 0);
        assertEq(tokenA.balanceOf(address(pair)), 2 ether + flashloanFee);
    }
}
