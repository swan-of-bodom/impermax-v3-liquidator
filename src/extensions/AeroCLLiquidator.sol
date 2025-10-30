// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Base
import {INFTLP} from "../interfaces/INFTLP.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ImpermaxV3Liquidator} from "../ImpermaxV3Liquidator.sol";

// Extensions
import {ISwapRouter} from "../interfaces/extensions/aeroCL/ISwapRouter.sol";
import {INonfungiblePositionManager} from "../interfaces/extensions/aeroCL/INFPManager.sol";

contract AeroCLLiquidator is ImpermaxV3Liquidator {
    using SafeTransferLib for address;

    /// @notice The address of Aerodrome's Swap Router
    ISwapRouter public immutable swapRouter;

    /// @notice The address of Aerodrome's NonFungiblePositionManager
    INonfungiblePositionManager public immutable positionManager;

    /// @param _router The Impermax router on this chain to get lending pool (could also use factory)
    /// @param _swapRouter The address of Aerodromes's Swap Router
    /// @param _positionManager The address of Aerodrome's NonFungiblePositionManager
    constructor(address _router, address _swapRouter, address _positionManager) ImpermaxV3Liquidator(_router) {
        swapRouter = ISwapRouter(_swapRouter);
        positionManager = INonfungiblePositionManager(_positionManager);
    }

    /// @param data The data passed to the borrowable's `liquidate` function
    /// @param tokenId The TokenID we're liquidating
    function _redeemPositionAndRepay(LiquidateData memory data, uint256 tokenId) internal override {
        // Redeem NFTLP and receive Aero NFT
        INFTLP(data.lendingPool.nftlp).redeem(address(this), tokenId);

        // Redeem Aero NFT
        (,,,, int24 tickSpacing,,, uint128 liquidity,,,,) = positionManager.positions(tokenId);

        positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        positionManager.burn(tokenId);

        (address borrowable, address tokenIn, address tokenOut) = _getSwapTokens(data);
        _swapTokensAero(tokenIn, tokenOut, tickSpacing, data.repayAmount);

        _repay(tokenOut, borrowable, data.repayAmount);
    }

    function _swapTokensAero(address tokenIn, address tokenOut, int24 tickSpacing, uint256 amountIn) private {
        _approveToken(tokenIn, address(swapRouter), amountIn);

        swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                tickSpacing: tickSpacing,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }
}
