// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IV3BaseRouter01} from "./IImpermaxV3BaseRouter01.sol";
import {IBorrowable} from "./IBorrowable.sol";
import {ICollateral} from "./ICollateral.sol";
import {IERC20} from "./IERC20.sol";
import {INFTLP} from "./INFTLP.sol";

interface IImpermaxV3Liquidator {
    error PositionNotLiquidatable();
    error PositionIsUnderwater();
    error UnauthorizedCaller();
    error UnauthorizedOperator();
    error UnauthorizedFrom();

    event Liquidate(
        address indexed nftlp,
        uint256 indexed tokenId,
        address indexed liquidator,
        address borrowable,
        uint256 liquidateAmount
    );

    struct LiquidateData {
        uint256 tokenId;
        IV3BaseRouter01.LendingPool lendingPool;
        uint256 repayAmount;
        bool isX;
    }

    function router() external view returns (IV3BaseRouter01);
    function admin() external view returns (address);
    function ERC721_RECEIVER() external view returns (bytes4);
    function isPositionLiquidatable(address nftlp, uint256 tokenId) external returns (bool);
    function isPositionUnderwater(address nftlp, uint256 tokenId) external returns (bool);
    function flashLiquidate(address nftlp, uint256 tokenId) external;
    function getLendingPool(address nftlp) external view returns (IV3BaseRouter01.LendingPool memory lendingPool);
    function collectTokens(address[] calldata tokens, address to) external;
}
