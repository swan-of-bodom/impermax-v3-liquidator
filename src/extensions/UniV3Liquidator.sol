// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Base
import {INFTLP} from "../interfaces/INFTLP.sol";
import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ImpermaxV3Liquidator} from "../ImpermaxV3Liquidator.sol";

// Extensions
import {IUniV3SwapRouter} from "../interfaces/extensions/uniV3/IUniV3SwapRouter.sol";
import {INonfungiblePositionManager} from "../interfaces/extensions/aeroCL/INFPManager.sol";

contract UniV3Liquidator is ImpermaxV3Liquidator {
    using SafeTransferLib for address;

    /// @notice The address of UniV3's Swap Router
    IUniV3SwapRouter public constant SWAP_ROUTER = IUniV3SwapRouter(0x6D99e7f6747AF2cDbB5164b6DD50e40D4fDe1e77);

    /// @param _router The Impermax Router, can also use factory, just used for getLendingPool
    constructor(address _router) ImpermaxV3Liquidator(_router) {}

    /// @param data The data passed to the borrowable's `liquidate` function
    /// @param tokenId The TokenID we're liquidating
    function _redeemPositionAndRepay(LiquidateData memory data, uint256 tokenId) internal override {
        // Redeem NFTLP and receive Aero NFT
        (uint24 fee, , , , , , , ) = INFTLP(data.lendingPool.nftlp).positions(tokenId);
        INFTLP(data.lendingPool.nftlp).redeem(address(this), tokenId);

        // Swap to the token we need to repay
        address borrowable = data.isX ? data.lendingPool.borrowables[0] : data.lendingPool.borrowables[1];
        address tokenIn = data.isX ? data.lendingPool.tokens[1] : data.lendingPool.tokens[0];
        address tokenOut = data.isX ? data.lendingPool.tokens[0] : data.lendingPool.tokens[1];

        _swapTokensUniV3(tokenIn, tokenOut, tokenIn.balanceOf(address(this)), fee);

        // Repay
        tokenOut.safeTransfer(borrowable, data.repayAmount);
    }

    function _approveToken(address token, address to, uint256 amount) private {
        if (IERC20(token).allowance(address(this), to) >= amount) return;
        SafeTransferLib.safeApprove(token, to, type(uint256).max);
    }

    function _swapTokensUniV3(address tokenIn, address tokenOut, uint256 amountIn, uint24 fee) private {
        _approveToken(tokenIn, address(SWAP_ROUTER), amountIn);

        SWAP_ROUTER.exactInputSingle(
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
