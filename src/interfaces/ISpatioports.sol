// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Cost.sol";
import "./IInfrastructure.sol";
import "./IShip.sol";

interface ISpatioports is IInfrastructure {
    struct Spatioport {
        uint256 level;
        Cost[] nextCosts;
        uint256 nextUpgrade;
    }

    function build(
        uint256 planetId,
        IShip fleet,
        uint256 amount
    ) external;

    function spatioport(uint256 planetId)
        external
        view
        returns (Spatioport memory);
}
