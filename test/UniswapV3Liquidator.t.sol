// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {UniV3Liquidator} from "../src/extensions/UniV3Liquidator.sol";
import {UniV3Liquidator} from "../src/extensions/UniV3Liquidator.sol";

contract ImpermaxV3LiquidatorTest is Test {
    UniV3Liquidator public liquidator;

    // Impermax Router and Uni's Swap router on this chain
    address constant ROUTER = 0x747B53B2aF6cd09A19c81085E85117fF11F7119D;
    address constant UNISWAP_ROUTER = 0xBE6D8f0d05cC4be24d5167a3eF062215bE6D18a5;

    // Position
    address constant NFTLP = 0x059C888D457A10de6921A0853E1a62EC58B447ad;
    uint256 constant TOKEN_ID = 23431656;

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
