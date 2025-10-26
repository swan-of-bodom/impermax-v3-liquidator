// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {UniV3Liquidator} from "../src/extensions/UniV3Liquidator.sol";

contract ImpermaxV3LiquidatorTest is Test {
    UniV3Liquidator public liquidator;

    // Impermax Router on this chain
    address constant ROUTER = 0x0fD27DC61e2Dc85EF63298E39cB2879432F2DaF6;
    // Extension router on this chain (Uniswap's SwapRouter for UniV3Liquidator, etc.)
    address uniswapRouter = 0x2626664c2603336E57B271c5C0b26F421741e481;

    // Position to liquidate
    address constant NFTLP = 0x62Eb5c0f829e7fAE4da4B1bDE3b1540F581Fc187;
    uint256 constant TOKEN_ID = 39;

    function setUp() public {
        vm.createSelectFork("base");
        liquidator = new UniV3Liquidator(ROUTER, uniswapRouter);
    }

    function test_flashLiquidate() public {
        bool isLiquidatable = liquidator.isPositionLiquidatable(NFTLP, TOKEN_ID);

        if (!isLiquidatable) {
            console.log("Position not liquidatable");
            return;
        }

        address liquidatorAddress = makeAddr("liquidator");
        vm.startPrank(liquidatorAddress);
        liquidator.flashLiquidate(NFTLP, TOKEN_ID);
        vm.stopPrank();
    }
}
