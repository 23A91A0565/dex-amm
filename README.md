# \# DEX AMM Project

# 

# \## Overview

# This project implements a simplified \*\*Decentralized Exchange (DEX)\*\* using an \*\*Automated Market Maker (AMM)\*\* model similar to Uniswap V2.  

# It enables decentralized token swaps without order books or intermediaries, using smart contracts to manage liquidity pools and pricing.

# 

# Users can:

# \- Provide liquidity and earn fees

# \- Swap between two ERC-20 tokens

# \- Withdraw liquidity proportionally with accumulated fees

# 

# ---

# 

# \## Features

# \- Initial and subsequent liquidity provision

# \- Liquidity removal with proportional share calculation

# \- Token swaps using constant product formula (`x \* y = k`)

# \- 0.3% trading fee distributed to liquidity providers

# \- LP token minting and burning

# \- Reentrancy protection and input validation

# \- 46 automated tests with >80% code coverage

# \- Fully Dockerized setup for deterministic evaluation

# 

# ---

# 

# \## Architecture

# 

# \### Smart Contracts

# \- \*\*DEX.sol\*\*

# &nbsp; - Core AMM logic

# &nbsp; - Manages liquidity, swaps, reserves, and LP accounting

# \- \*\*MockERC20.sol\*\*

# &nbsp; - Simple ERC-20 token used for testing

# &nbsp; - Supports minting for test scenarios

# 

# \### Design Choices

# \- Reserves are tracked internally instead of relying on token balances

# \- LP tokens are implemented via internal accounting (mapping + totalLiquidity)

# \- Fees remain in the pool, increasing `k` and rewarding LPs

# \- Solidity 0.8+ is used for built-in overflow protection

# 

# ---

# 

# \## Mathematical Implementation

# 

# \### Constant Product Formula

# The AMM maintains the invariant:

# 

# x \* y = k

# 

# 

# Where:

# \- `x` = reserve of Token A

# \- `y` = reserve of Token B

# \- `k` = constant

# 

# Swaps adjust reserves while preserving (or increasing) `k`.

# 

# ---

# 

# \### Fee Calculation (0.3%)

# A 0.3% trading fee is applied on each swap:

# 

# 

# 

# amountInWithFee = amountIn \* 997

# numerator = amountInWithFee \* reserveOut

# denominator = (reserveIn \* 1000) + amountInWithFee

# amountOut = numerator / denominator

# 

# 

# This ensures:

# \- Only 99.7% of input affects price

# \- 0.3% stays in the pool

# \- Liquidity providers earn fees automatically

# 

# ---

# 

# \### LP Token Minting

# 

# \#### Initial Liquidity

# For the first liquidity provider:

# 

# 

# 

# liquidityMinted = sqrt(amountA \* amountB)

# 

# 

# The first provider sets the initial price ratio.

# 

# \#### Subsequent Liquidity

# For later providers:

# 

# 

# 

# liquidityMinted = (amountA \* totalLiquidity) / reserveA

# 

# 

# This preserves proportional ownership.

# 

# ---

# 

# \### Liquidity Removal

# When LP tokens are burned:

# 

# 

# 

# amountA = (liquidityBurned \* reserveA) / totalLiquidity

# amountB = (liquidityBurned \* reserveB) / totalLiquidity

# 

# 

# Providers receive their proportional share plus earned fees.

# 

# ---

# 

# \## Setup Instructions

# 

# \### Prerequisites

# \- Node.js (v18 recommended)

# \- Docker \& Docker Compose

# \- Git

# 

# ---

# 

# \### Using Docker (Recommended)

# 

# ```bash

# git clone <your-repo-url>

# cd dex-amm

# docker-compose build --no-cache

# docker-compose up -d

# docker-compose exec app npm run compile

# docker-compose exec app npm test

# docker-compose exec app npm run coverage

# docker-compose down

# 

# Running Locally (Without Docker)

# npm install

# npm run compile

# npm test

# npm run coverage

# 

# Contract Addresses

# 

# This project is intended for local development and evaluation.

# If deployed to a testnet, contract addresses can be listed here.

# 

# Known Limitations

# 

# Supports only a single trading pair

# 

# No slippage protection (minAmountOut)

# 

# No deadline parameter for swaps

# 

# Direct token transfers to the contract are not reflected in reserves

# 

# No flash swap functionality

# 

# Security Considerations

# 

# Reentrancy protection using OpenZeppelin ReentrancyGuard

# 

# Validation of zero values and insufficient liquidity

# 

# Solidity 0.8+ prevents arithmetic overflow/underflow

# 

# Fees applied before swap calculations

# 

# Reserves updated only after successful state transitions

# 

# Extensive test coverage including edge cases and revert paths

# 

# Testing Summary

# 

# 46 automated tests using Hardhat + Chai

# 

# Liquidity management, swaps, pricing, fees, and events covered

# 

# Code coverage:

# 

# Statements: ~87%

# 

# Lines: ~82%

# 

# Functions: 100%

# 

# Conclusion

# 

# This project demonstrates the fundamentals of decentralized exchanges and AMMs, closely following Uniswap-style mechanics.

# It showcases secure smart contract design, rigorous testing, and production-ready tooling suitable for real-world DeFi systems.

# 

# 

# ---

# 

