// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "./mocks/ERC20Mintable.sol";
import "./mocks/Flashloaner.sol";
import {XniswapV2Pair} from "../src/XniswapV2Pair.sol";
import {XniswapV2Router} from "../src/XniswapV2Router.sol";
import {XniswapV2Factory} from "../src/XniswapV2Factory.sol";
import {XniswapV2Lib} from "../src/utils/XniswapV2Lib.sol";

contract XniswapV2RouterTest is Test {
    XniswapV2Factory factory;
    XniswapV2Router router;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;

    function setUp() public {
        tokenA = new ERC20Mintable("Token A", "TKNA");
        tokenB = new ERC20Mintable("Token B", "TKNB");
        tokenA.mint(100 ether, address(this));
        tokenB.mint(100 ether, address(this));

        factory = new XniswapV2Factory();
        router = new XniswapV2Router(address(factory));
    }

    function testAddLiquidityCreatesPair() public {
        console.log("[RouterTest] Add liquidity");

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(address(tokenA), address(tokenB), 1 ether, 1 ether, 1 ether, 1 ether, address(this));

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));
        assertEq(pairAddress, 0x750E7a24eD432D8a2dac51884a2aEbE5FFfE47Ad);
    }
}
