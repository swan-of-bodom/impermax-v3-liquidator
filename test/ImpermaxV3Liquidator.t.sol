// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {AeroCLLiquidator} from "../src/extensions/AeroCLLiquidator.sol";

contract ImpermaxV3LiquidatorTest is Test {
    AeroCLLiquidator public liquidator;

    // Impermax Router on this chain
    address constant ROUTER = 0xd894B2C116Ba9473109e3d2675EA25964E1f8797;

    // Position to liquidate
    address constant NFTLP = 0x059C888D457A10de6921A0853E1a62EC58B447ad;
    uint256 constant TOKEN_ID = 29207926;

    function setUp() public {
        vm.createSelectFork("base", 37010128);
        liquidator = new AeroCLLiquidator(ROUTER);
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
