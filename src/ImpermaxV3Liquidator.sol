// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IBorrowable} from "./interfaces/IBorrowable.sol";
import {ICollateral} from "./interfaces/ICollateral.sol";
import {IV3BaseRouter01} from "./interfaces/IImpermaxV3BaseRouter01.sol";
import {IImpermaxV3Liquidator} from "./interfaces/IImpermaxLiquidator.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";
import {INFTLP} from "./interfaces/INFTLP.sol";
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {IERC20} from "./interfaces/IERC20.sol";

abstract contract ImpermaxV3Liquidator is IImpermaxV3Liquidator, IERC721Receiver {
    using SafeTransferLib for address;

    /// @inheritdoc IImpermaxV3Liquidator
    IV3BaseRouter01 public immutable override router;

    /// @inheritdoc IImpermaxV3Liquidator
    address public immutable override admin;

    /// @inheritdoc IImpermaxV3Liquidator
    bytes4 public constant override ERC721_RECEIVER =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @notice Overridden by extension liquidators
    function _redeemPositionAndRepay(LiquidateData memory data, uint256 tokenId) internal virtual;

    constructor(address _router) {
        router = IV3BaseRouter01(_router);
        admin = msg.sender;
    }

    /// @inheritdoc IImpermaxV3Liquidator
    function getLendingPool(address nftlp)
        public
        view
        override
        returns (IV3BaseRouter01.LendingPool memory lendingPool)
    {
        return router.getLendingPool(nftlp);
    }

    /// @inheritdoc IImpermaxV3Liquidator
    function flashLiquidate(address nftlp, uint256 tokenId) external override {
        IV3BaseRouter01.LendingPool memory lendingPool = getLendingPool(nftlp);

        if (!_isPositionLiquidatable(lendingPool.collateral, tokenId)) revert PositionNotLiquidatable();

        uint256 borrowBalance0 = IBorrowable(lendingPool.borrowables[0]).currentBorrowBalance(tokenId);
        uint256 borrowBalance1 = IBorrowable(lendingPool.borrowables[1]).currentBorrowBalance(tokenId);

        IBorrowable(lendingPool.borrowables[0]).liquidate(
            tokenId,
            borrowBalance0,
            address(this),
            abi.encode(
                LiquidateData({tokenId: tokenId, lendingPool: lendingPool, repayAmount: borrowBalance0, isX: true})
            )
        );

        IBorrowable(lendingPool.borrowables[1]).liquidate(
            tokenId,
            borrowBalance1,
            address(this),
            abi.encode(
                LiquidateData({tokenId: tokenId, lendingPool: lendingPool, repayAmount: borrowBalance1, isX: false})
            )
        );
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
        external
        override
        returns (bytes4)
    {
        // On the second call just accept the NFTLP
        if (data.length == 0) return ERC721_RECEIVER;

        LiquidateData memory $ = abi.decode(data, (LiquidateData));

        if (msg.sender != $.lendingPool.nftlp) revert UnauthorizedCaller();
        if (operator != $.lendingPool.collateral) revert UnauthorizedOperator();
        if (from != $.lendingPool.collateral) revert UnauthorizedFrom();

        _redeemPositionAndRepay($, tokenId);

        return ERC721_RECEIVER;
    }

    /// @inheritdoc IImpermaxV3Liquidator
    function collectTokens(address[] calldata tokens, address to) external override {
        if (msg.sender != admin) revert UnauthorizedCaller();

        for (uint256 i = 0; i < tokens.length;) {
            uint256 balance = tokens[i].balanceOf(address(this));
            if (balance > 0) tokens[i].safeTransfer(to, balance);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IImpermaxV3Liquidator
    function isPositionLiquidatable(address nftlp, uint256 tokenId) external override returns (bool) {
        IV3BaseRouter01.LendingPool memory lendingPool = getLendingPool(nftlp);
        return _isPositionLiquidatable(lendingPool.collateral, tokenId);
    }

    /// @inheritdoc IImpermaxV3Liquidator
    function isPositionUnderwater(address nftlp, uint256 tokenId) external override returns (bool) {
        IV3BaseRouter01.LendingPool memory lendingPool = getLendingPool(nftlp);
        return _isPositionUnderwater(lendingPool.collateral, tokenId);
    }

    // -----------------------------
    //   Private
    // -----------------------------

    function _isPositionLiquidatable(address collateral, uint256 tokenId) private returns (bool) {
        return ICollateral(collateral).isLiquidatable(tokenId);
    }

    function _isPositionUnderwater(address collateral, uint256 tokenId) private returns (bool) {
        return ICollateral(collateral).isUnderwater(tokenId);
    }

    // -----------------------------
    //   Internal
    // -----------------------------

    // Used by extensions to get the borrowable we need to repay, and the token we need to swap
    function _getSwapTokens(LiquidateData memory data)
        internal
        pure
        returns (address borrowable, address tokenIn, address tokenOut)
    {
        borrowable = data.isX ? data.lendingPool.borrowables[0] : data.lendingPool.borrowables[1];
        tokenIn = data.isX ? data.lendingPool.tokens[1] : data.lendingPool.tokens[0];
        tokenOut = data.isX ? data.lendingPool.tokens[0] : data.lendingPool.tokens[1];
    }
}
