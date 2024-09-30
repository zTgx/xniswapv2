// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "./mocks/ERC20Mintable.sol";
import "./mocks/Flashloaner.sol";
import {XniswapV2Pair} from "../src/XniswapV2Pair.sol";
import {XniswapV2Factory} from "../src/XniswapV2Factory.sol";
import {XniswapV2Lib} from "../src/utils/XniswapV2Lib.sol";

contract XniswapV2PairTest is Test {
    XniswapV2Factory factory;
    XniswapV2Pair public pair;
    ERC20Mintable tokenA;
    ERC20Mintable tokenB;

    function setUp() public {
        tokenA = new ERC20Mintable("Token A", "TKNA");
        tokenB = new ERC20Mintable("Token B", "TKNB");
        tokenA.mint(100 ether, address(this));
        tokenB.mint(100 ether, address(this));

        factory = new XniswapV2Factory();
        address pairAddress = factory.newPair(address(tokenA), address(tokenB));
        console.log("[Setup] pair address: ", pairAddress);

        pair = XniswapV2Pair(pairAddress);
    }

    function assertReserves(uint112 expectedReserve0, uint112 expectedReserve1) internal view {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "unexpected reserve1");
    }

    function assertBlockTimestampLast(uint32 expected) internal view {
        (,, uint32 blockTimestampLast) = pair.getReserves();

        assertEq(blockTimestampLast, expected, "unexpected blockTimestampLast");
    }

    function getReservesWorks(uint112 expectedReserveA, uint112 expectedReserveB) internal view {
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

    function testMintBasic() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    function testMintWhenThereIsLiquidity() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP

        tokenA.transfer(address(pair), 2 ether);
        tokenB.transfer(address(pair), 2 ether);

        pair.mint(address(this)); // + 2 LP

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function testMintUnbalanced() public {
        // the token pair will be sorted in inner factory
        (address token0, address token1) = XniswapV2Lib.sortTokenAddress(address(tokenA), address(tokenB));

        ERC20(token0).transfer(address(pair), 1 ether);
        ERC20(token1).transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        ERC20(token0).transfer(address(pair), 2 ether);
        ERC20(token1).transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertReserves(3 ether, 2 ether);
    }

    function testMintZeroLiquidity() public {
        // the token pair will be sorted in inner factory
        (address token0, address token1) = XniswapV2Lib.sortTokenAddress(address(tokenA), address(tokenB));

        ERC20(token0).transfer(address(pair), 1000);
        ERC20(token1).transfer(address(pair), 1000);

        vm.expectRevert(abi.encodePacked("Insufficient liquidity minted"));
        pair.mint(address(this));
    }

    function testBurnBasic() public {
        // the token pair will be sorted in inner factory
        (address token0, address token1) = XniswapV2Lib.sortTokenAddress(address(tokenA), address(tokenB));

        ERC20(token0).transfer(address(pair), 1 ether);
        ERC20(token1).transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        // Transfer LP token to pair contract!!!
        uint256 lpToken = ERC20(pair).balanceOf(address(this));

        ERC20(pair).transfer(address(pair), lpToken);

        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);

        assertReserves(1000, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(ERC20(token0).balanceOf(address(this)), 100 ether - 1000);
        assertEq(ERC20(token1).balanceOf(address(this)), 100 ether - 1000);
    }
}
