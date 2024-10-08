// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {XniswapV2Factory} from "../src/XniswapV2Factory.sol";
import {XniswapV2Pair} from "../src/XniswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";

contract XniswapV2FactoryTest is Test {
    XniswapV2Factory factory;

    ERC20Mintable token0;
    ERC20Mintable token1;

    function setUp() public {
        factory = new XniswapV2Factory();

        token0 = new ERC20Mintable("Token A", "TKNA");
        token0.mint(10 ether, address(this));

        token1 = new ERC20Mintable("Token B", "TKNB");
        token1.mint(10 ether, address(this));
    }

    function testNewPairWorks() public {
        address pairAddress = factory.newPair(address(token1), address(token0));

        XniswapV2Pair pair = XniswapV2Pair(pairAddress);

        assertEq(pair.tokenA(), address(token0));
        assertEq(pair.tokenB(), address(token1));
    }

    function test_ZeroPairsLength() public view {
        uint256 pairsLength = factory.allPairsLength();
        assertTrue(pairsLength == 0);
    }

    function test_NonZeroPairsLength() public {
        factory.newPair(address(token1), address(token0));
        uint256 pairsLength = factory.allPairsLength();
        assertTrue(pairsLength == 1);
    }

    function test_AllPairs() public {
        address pairAddress = factory.newPair(address(token1), address(token0));
        uint256 pairsLength = factory.allPairsLength();
        address expectedAddress = factory.allPairs(pairsLength - 1);
        assertTrue(pairAddress == expectedAddress);
    }
}
