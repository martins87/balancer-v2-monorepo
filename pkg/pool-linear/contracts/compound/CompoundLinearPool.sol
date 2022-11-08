// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ERC20.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

import "./CToken.sol";
import "../LinearPool.sol";

contract CompoundLinearPool is LinearPool {
    using Math for uint256;

    uint256 private immutable _rateScaleFactor;

    struct ConstructorArgs {
        IVault vault;
        string name;
        string symbol;
        IERC20 mainToken;
        IERC20 wrappedToken;
        address assetManager;
        uint256 upperTarget;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
    }

    constructor(ConstructorArgs memory args)
        LinearPool(
            args.vault,
            args.name,
            args.symbol,
            args.mainToken,
            args.wrappedToken,
            args.upperTarget,
            _toAssetManagerArray(args),
            args.swapFeePercentage,
            args.pauseWindowDuration,
            args.bufferPeriodDuration,
            args.owner
        )
    {
        // The cToken Exchange Rate is scaled by the difference in decimals between the cToken and the underlying asset.
        // See https://docs.compound.finance/v2/ on "Interpreting Exchange Rates"

        // _getWrappedTokenRate is scaled e18
        uint256 wrappedTokenDecimals = ERC20(address(args.wrappedToken)).decimals();
        uint256 mainTokenDecimals = ERC20(address(args.mainToken)).decimals();

        // This is always positive because we only accept tokens with <= 18 decimals
        uint256 digitsDifference = Math.add(18, mainTokenDecimals).sub(wrappedTokenDecimals);
        _rateScaleFactor = 10**digitsDifference;
    }

    function _toAssetManagerArray(ConstructorArgs memory args) private pure returns (address[] memory) {
        // We assign the same asset manager to both the main and wrapped tokens.
        address[] memory assetManagers = new address[](2);
        assetManagers[0] = args.assetManager;
        assetManagers[1] = args.assetManager;

        return assetManagers;
    }

    function _getWrappedTokenRate() internal view override returns (uint256) {
        // Maybe calling an ICToken interface is a better way
        CToken wrappedToken = CToken(address(getWrappedToken()));

        // When a market is launched, the cToken exchange rate (how much ETH one cETH is worth) begins at 0.020000
        // and increases at a rate equal to the compounding market interest rate.
        // For example, after one year, the exchange rate might equal 0.021591
        // Each user has the same cToken exchange rate; there’s nothing unique to your wallet that you have to worry about.

        // Each cToken is convertible into an ever increasing quantity of the underlying asset, as interest accrues in the market.
        // The exchange rate between a cToken and the underlying asset is equal to:
        // exchangeRate = (getCash() + totalBorrows() - totalReserves()) / totalSupply()
        // See https://docs.compound.finance/v2/ctokens/#exchange-rate

        // This implementation is pulled from the CToken contract internal function exchangeRateStoredInternal
        // See https://github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol#L293

        uint256 unscaledRate = wrappedToken.exchangeRateStored();
        uint256 rate = unscaledRate.mul(_rateScaleFactor).divDown(FixedPoint.ONE);
        return rate;
    }
}
