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

import "@balancer-labs/v2-interfaces/contracts/pool-linear/ICToken.sol";

import "@balancer-labs/v2-solidity-utils/contracts/test/TestToken.sol";

contract MockCToken is TestToken, ICToken {
    // using FixedPoint for uint256;

    // rate scaled to 2e16
    // When a market is launched, the cToken exchange rate (how much ETH one cETH is worth)
    // begins at 0.020000 - see "Do I need to calculate the cToken exchange rate?"
    // on https://docs.compound.finance/v2/ctokens/
    uint256 private _rate = 2e16;
    // uint256 private _scaleAssetsToFP;
    // uint256 private _scaleSharesToFP;
    // uint256 private _totalAssets;
    address private immutable _ASSET;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address underlyingAsset
    ) TestToken(name, symbol, decimals) {
        _ASSET = underlyingAsset;

        // uint256 assetDecimals = TestToken(asset).decimals();
        // uint256 assetDecimalsDifference = Math.sub(18, assetDecimals);
        // _scaleAssetsToFP = FixedPoint.ONE * 10**assetDecimalsDifference;

        // uint256 shareDecimalsDifference = Math.sub(18, uint256(decimals));
        // _scaleSharesToFP = FixedPoint.ONE * 10**shareDecimalsDifference;
    }

    function getRate() external view returns (uint256) {
        return _rate;
    }

    function setRate(uint256 newRate) external {
        _rate = newRate;
    }

    function rate() external pure override returns (uint256) {
        revert("Should not call this");
    }

    function deposit(
        address,
        uint256,
        uint16,
        bool
    ) external pure override returns (uint256) {
        return 0;
    }

    function withdraw(
        address,
        uint256,
        bool
    ) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function staticToDynamicAmount(uint256 amount) external pure override returns (uint256) {
        return amount;
    }
}
