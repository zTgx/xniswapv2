// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/FixedPointMathLib.sol";
import {console} from "forge-std/console.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "./interface/IXniswapV2Callee.sol";
import "./XniswapV2Lib.sol";

contract XniswapV2Pair is ERC20, ReentrancyGuard {
    address public factory;
    address public tokenA;
    address public tokenB;

    // Gas saving
    uint112 private reserveA;
    uint112 private reserveB;
    uint32 private blockTimestampLast;

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    // TODO: add events here
    event Mint(address indexed sender, uint256 amountA, uint256 amountB);
    event Burn(address indexed sender, uint256 amountA, uint256 amountB, address indexed to);
    event Update(uint256 _reserveA, uint256 _reserveB, uint32 _blockTimestampLast);
    event Swap(address indexed sender, uint256 amountAOut, uint256 amountBOut, address indexed to);

    constructor() ERC20("XniswapV2 Pair", "XNIV2", 18) {
        factory = msg.sender;
    }

    function initialize(address _tokenA, address _tokenB) public {
        console.log(">>> msg.sender: ", msg.sender);
        console.log(">>> factory   : ", factory);

        require(msg.sender == factory, "XniswapV2: FORBIDDEN");

        console.log(">>> XniswapV2Pair initialized!");

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
    function mint(address to) public {
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
             * case2: b / a > B / A
             * case3: b / a < B / A
             */
            liquidity = XniswapV2Lib.min((amountA * totalSupply) / reserveA_, (amountB * totalSupply) / reserveB_);
        }

        // q = min(a / A, b / B)
        // After that, newly minted LP-Tokens = qM + M

        require(liquidity > 0, "Insufficient liquidity minted");

        // Issue liquidity to `to`
        _mint(to, liquidity);

        _update(balanceA, balanceB, reserveA_, reserveB_);

        emit Mint(to, amountA, amountB);
    }

    //NOTE: sender send liquidity to contract, then burn
    function burn(address to) public {
        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));

        uint256 liquidity = balanceOf[address(this)];

        uint256 amountA = liquidity * (balanceA / totalSupply);
        uint256 amountB = liquidity * (balanceB / totalSupply);

        require(amountA > 0 && amountB > 0, "XniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");

        _burn(address(this), liquidity);

        SafeTransferLib.safeTransfer(ERC20(tokenA), to, amountA);
        SafeTransferLib.safeTransfer(ERC20(tokenB), to, amountB);

        balanceA = ERC20(tokenA).balanceOf(address(this));
        balanceB = ERC20(tokenB).balanceOf(address(this));

        (uint112 reserveA_, uint112 reserveB_,) = getReserves();
        _update(balanceA, balanceB, reserveA_, reserveB_);

        emit Burn(msg.sender, amountA, amountB, to);
    }

    function swap(uint256 amountAOut, uint256 amountBOut, address to, bytes calldata data) public nonReentrant {
        require(amountAOut != 0 || amountBOut != 0, "InsufficientOutputAmount");

        (uint112 reserveA_, uint112 reserveB_,) = getReserves();
        require(amountAOut <= reserveA_ && amountBOut <= reserveB_, "InsufficientLiquidity");

        uint256 balanceA = ERC20(tokenA).balanceOf(address(this)) - amountAOut;
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this)) - amountBOut;

        // the product of reserves after a swap must be equal or greater than that before the swap
        require(balanceA * balanceB >= uint256(reserveA_) * uint256(reserveB_), "Invalid L(L means L * L = X * Y)");

        _update(balanceA, balanceB, reserveA_, reserveB_);

        if (amountAOut > 0) SafeTransferLib.safeTransfer(ERC20(tokenA), to, amountAOut);
        if (amountBOut > 0) SafeTransferLib.safeTransfer(ERC20(tokenB), to, amountBOut);
        if (data.length > 0) IXniswapV2Callee(to).call(msg.sender, amountAOut, amountBOut, data);

        emit Swap(msg.sender, amountAOut, amountBOut, to);
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
