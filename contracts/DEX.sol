// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DEX is ReentrancyGuard {
    // -----------------------------
    // State Variables (MANDATORY)
    // -----------------------------

    address public tokenA;
    address public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    // -----------------------------
    // Events (MANDATORY)
    // -----------------------------

    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityMinted
    );

    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityBurned
    );

    event Swap(
        address indexed trader,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    // -----------------------------
    // Constructor
    // -----------------------------

    /// @notice Initialize the DEX with two token addresses
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0), "TokenA zero address");
        require(_tokenB != address(0), "TokenB zero address");
        require(_tokenA != _tokenB, "Tokens must differ");

        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // -----------------------------
    // Add Liquidity
    // -----------------------------

    /// @notice Add liquidity to the pool
    function addLiquidity(uint256 amountA, uint256 amountB)
        external
        nonReentrant
        returns (uint256 liquidityMinted)
    {
        require(amountA > 0 && amountB > 0, "Zero amount");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        if (totalLiquidity == 0) {
            liquidityMinted = _sqrt(amountA * amountB);
        } else {
            require(
                amountB == (amountA * reserveB) / reserveA,
                "Ratio mismatch"
            );
            liquidityMinted = (amountA * totalLiquidity) / reserveA;
        }

        require(liquidityMinted > 0, "Insufficient liquidity");

        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(
            msg.sender,
            amountA,
            amountB,
            liquidityMinted
        );
    }


        // -----------------------------
    // Remove Liquidity
    // -----------------------------

    /// @notice Remove liquidity from the pool
    /// @param liquidityAmount Amount of LP tokens to burn
    /// @return amountA Amount of token A returned
    /// @return amountB Amount of token B returned
    function removeLiquidity(uint256 liquidityAmount)
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB)
    {
        require(liquidityAmount > 0, "Zero liquidity");
        require(
            liquidity[msg.sender] >= liquidityAmount,
            "Not enough liquidity"
        );

        amountA = (liquidityAmount * reserveA) / totalLiquidity;
        amountB = (liquidityAmount * reserveB) / totalLiquidity;

        require(amountA > 0 && amountB > 0, "Zero output");

        // Burn liquidity
        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens back to user
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        emit LiquidityRemoved(
            msg.sender,
            amountA,
            amountB,
            liquidityAmount
        );
    }

        // -----------------------------
    // AMM Math
    // -----------------------------

    /// @notice Calculate output amount with 0.3% fee
    /// @param amountIn Amount of input token
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountOut Amount of output token
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        public
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "Zero input");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        amountOut = numerator / denominator;
    }

        // -----------------------------
    // Swaps
    // -----------------------------

    /// @notice Swap token A for token B
    /// @param amountAIn Amount of token A to swap
    /// @return amountBOut Amount of token B received
    function swapAForB(uint256 amountAIn)
        external
        nonReentrant
        returns (uint256 amountBOut)
    {
        require(amountAIn > 0, "Zero input");

        amountBOut = getAmountOut(amountAIn, reserveA, reserveB);
        require(amountBOut > 0, "Zero output");

        // Transfer token A from user to pool
        IERC20(tokenA).transferFrom(
            msg.sender,
            address(this),
            amountAIn
        );

        // Transfer token B from pool to user
        IERC20(tokenB).transfer(
            msg.sender,
            amountBOut
        );

        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit Swap(
            msg.sender,
            tokenA,
            tokenB,
            amountAIn,
            amountBOut
        );
    }

        /// @notice Swap token B for token A
    /// @param amountBIn Amount of token B to swap
    /// @return amountAOut Amount of token A received
    function swapBForA(uint256 amountBIn)
        external
        nonReentrant
        returns (uint256 amountAOut)
    {
        require(amountBIn > 0, "Zero input");

        amountAOut = getAmountOut(amountBIn, reserveB, reserveA);
        require(amountAOut > 0, "Zero output");

        // Transfer token B from user to pool
        IERC20(tokenB).transferFrom(
            msg.sender,
            address(this),
            amountBIn
        );

        // Transfer token A from pool to user
        IERC20(tokenA).transfer(
            msg.sender,
            amountAOut
        );

        // Update reserves
        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit Swap(
            msg.sender,
            tokenB,
            tokenA,
            amountBIn,
            amountAOut
        );
    }

        // -----------------------------
    // View Functions
    // -----------------------------

    /// @notice Get current price of token A in terms of token B
    /// @return price Current price (reserveB / reserveA)
    function getPrice() external view returns (uint256 price) {
        if (reserveA == 0 || reserveB == 0) {
            return 0;
        }
        price = reserveB / reserveA;
    }

    /// @notice Get current reserves
    /// @return _reserveA Current reserve of token A
    /// @return _reserveB Current reserve of token B
    function getReserves()
        external
        view
        returns (uint256 _reserveA, uint256 _reserveB)
    {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }

    // -----------------------------
    // Internal Math
    // -----------------------------

    /// @dev Babylonian method for square root
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
