// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IInfrastructure.sol";
import "./IShip.sol";

interface ISpatioports is IInfrastructure {
    error SpatioportExistence(uint256 planetId);

    struct Spatioport {
        uint256 level;
        uint256[][] nextCosts;
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
