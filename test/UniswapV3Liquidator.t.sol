// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {UniV3Liquidator} from "../src/extensions/UniV3Liquidator.sol";
import {UniV3Liquidator} from "../src/extensions/UniV3Liquidator.sol";

contract ImpermaxV3LiquidatorTest is Test {
    UniV3Liquidator public liquidator;

    // Impermax Router and Uni's Swap router on this chain
    address constant ROUTER = 0x7e22a1385B487936F095eBfFa7bEC3ff6908339a;
    address constant UNISWAP_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;

    // Position
    address constant NFTLP = 0x9a0A67c75978d58f36290ef767400eed6A53B014;
    uint256 constant TOKEN_ID = 215;

    function setUp() public {
        vm.createSelectFork("base");
        liquidator = new UniV3Liquidator(ROUTER, UNISWAP_ROUTER);
    }

    function test_flashLiquidate() public {
        bool isLiquidatable = liquidator.isPositionLiquidatable(NFTLP, TOKEN_ID);
        bool isUnderwater = liquidator.isPositionUnderwater(NFTLP, TOKEN_ID);
        console.log("Is underwater: ", isUnderwater);

        if (!isLiquidatable) {
            console.log("Position not liquidatable");
            return;
        }

        address liquidatorAddress = makeAddr("liquidator");
        vm.startPrank(liquidatorAddress);
        liquidator.flashLiquidate_U1R(NFTLP, TOKEN_ID);
        vm.stopPrank();
    }
}
