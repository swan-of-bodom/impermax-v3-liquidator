// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {INFTLP} from "./INFTLP.sol";
import {IBorrowable} from "./IBorrowable.sol";
import {ICollateral} from "./ICollateral.sol";
import {IERC20} from "./IERC20.sol";

interface IV3BaseRouter01 {
	struct LendingPool {
		address nftlp;
		address collateral;
		address[2] borrowables;
		address[2] tokens;
	}
	function getLendingPool(address nftlp) external view returns (LendingPool memory pool);
	function factory() external view returns (address);
	
	function execute(
		address nftlp,
		uint _tokenId,
		bytes calldata actionsData,
		bytes calldata permitsData,
		bool withCollateralTransfer
	) external payable;
}

