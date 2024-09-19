// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}

contract XniswapV2Pair is ERC20 {
    address public tokenA;
    address public tokenB;

    // Gas saving
    uint112 private reserveA;
    uint112 private reserveB;
    uint32 private blockTimestampLast;

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    // TODO: add events here
    event Burn(address indexed sender, uint256 amountA, uint256 amountB);
    event Update(uint256 _reserveA, uint256 _reserveB, uint32 _blockTimestampLast);

    constructor(address _tokenA, address _tokenB) ERC20("XniswapV2 Pair", "XNIV2", 18) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /**
     * constant product formula:
     *     (2.1) X * Y = L * L
     *     X -> Reserve of TokenA
     *     Y -> Reserve of TokenB
     *     L -> Liquidity parameter
     */
    function mint() public {
        (uint112 reserveA_, uint112 reserveB_,) = getReserves();
        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));

        uint256 amountA = balanceA - reserveA_;
        uint256 amountB = balanceB - reserveB_;

        // LP-token the liquidity provider received after add liquidity.
        uint256 liquidity;
        if (totalSupply == 0) {
            liquidity = FixedPointMathLib.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;

            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            /**
             * case1: b / a = B / A
             *             case2: b / a > B / A
             *             case3: b / a < B / A
             */
            liquidity = min((amountA * totalSupply) / reserveA_, (amountB * totalSupply) / reserveB_);
        }

        // q = min(a / A, b / B)
        // After that, newly minted LP-Tokens = qM + M

        require(liquidity > 0, "Insufficient liquidity minted");

        // Issue liquidity to msg.sender
        _mint(msg.sender, liquidity);

        _update(balanceA, balanceB, reserveA_, reserveB_);
    }

    function burn() public {
        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));

        uint256 liquidity = balanceOf[msg.sender];

        uint256 amountA = liquidity * (balanceA / totalSupply);
        uint256 amountB = liquidity * (balanceB / totalSupply);

        require(amountA > 0 && amountB > 0, "XniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");

        _burn(msg.sender, liquidity);

        SafeTransferLib.safeTransfer(ERC20(tokenA), msg.sender, amountA);
        SafeTransferLib.safeTransfer(ERC20(tokenB), msg.sender, amountB);

        balanceA = ERC20(tokenA).balanceOf(address(this));
        balanceB = ERC20(tokenB).balanceOf(address(this));

        (uint112 reserveA_, uint112 reserveB_,) = getReserves();
        _update(balanceA, balanceB, reserveA_, reserveB_);

        emit Burn(msg.sender, amountA, amountB);
    }

    // Utils
    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserveA, reserveB, blockTimestampLast);
    }

    // private functions

    function _update(uint256 _balanceA, uint256 _balanceB, uint112, uint112) private {
        reserveA = uint112(_balanceA);
        reserveB = uint112(_balanceB);
        blockTimestampLast = uint32(block.timestamp);

        emit Update(reserveA, reserveB, blockTimestampLast);
    }
}
