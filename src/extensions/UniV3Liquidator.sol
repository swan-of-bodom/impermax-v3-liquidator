// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Base
import {INFTLP} from "../interfaces/INFTLP.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ImpermaxV3Liquidator} from "../ImpermaxV3Liquidator.sol";

// Extensions
import {IUniV3SwapRouter} from "../interfaces/extensions/uniV3/IUniV3SwapRouter.sol";

contract UniV3Liquidator is ImpermaxV3Liquidator {
    using SafeTransferLib for address;

    /// @notice The address of UniV3's Swap Router
    IUniV3SwapRouter public immutable swapRouter;

    /// @param _router The Impermax router on this chain to get lending pool (could also use factory)
    /// @param _swapRouter The address of UniV3's Swap Router
    constructor(address _router, address _swapRouter) ImpermaxV3Liquidator(_router) {
        swapRouter = IUniV3SwapRouter(_swapRouter);
    }

    /// @param data The data passed to the borrowable's `liquidate` function
    /// @param tokenId The TokenID we're liquidating
    function _redeemPositionAndRepay(LiquidateData memory data, uint256 tokenId) internal override {
        // Get pool to swap before redeeming
        (uint24 fee,,,,,,,) = INFTLP(data.lendingPool.nftlp).positions(tokenId);

        // Redeem NFTLP and receive token0/token1
        INFTLP(data.lendingPool.nftlp).redeem(address(this), tokenId);

        (address borrowable, address tokenIn, address tokenOut) = _getSwapTokens(data);
        _swapTokensUniV3(tokenIn, tokenOut, tokenIn.balanceOf(address(this)), fee);

        _repay(borrowable, tokenOut, data.repayAmount);
    }

    function _swapTokensUniV3(address tokenIn, address tokenOut, uint256 amountIn, uint24 fee) private {
        _approveToken(tokenIn, address(swapRouter), amountIn);

        swapRouter.exactInputSingle(
            IUniV3SwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }
}
