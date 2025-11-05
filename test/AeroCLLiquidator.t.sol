// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {UniV3Liquidator} from "../src/extensions/UniV3Liquidator.sol";
import {AeroCLLiquidator} from "../src/extensions/AeroCLLiquidator.sol";

contract ImpermaxV3LiquidatorTest is Test {
    AeroCLLiquidator public liquidator;

    // Impermax Router, aero's Swap router and nfp manager on this chain
    address constant ROUTER = 0x747B53B2aF6cd09A19c81085E85117fF11F7119D;
    address constant AERO_ROUTER = 0xBE6D8f0d05cC4be24d5167a3eF062215bE6D18a5;
    address constant NFP_MANAGER = 0x827922686190790b37229fd06084350E74485b72;

    // Position
    address constant NFTLP = 0x49B3f8b07e645D7c31F41DE3296E9905aA93BE6C;
    uint256 constant TOKEN_ID = 26746844;

    function setUp() public {
        vm.createSelectFork("base");
        liquidator = new AeroCLLiquidator(ROUTER, AERO_ROUTER, NFP_MANAGER);
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
