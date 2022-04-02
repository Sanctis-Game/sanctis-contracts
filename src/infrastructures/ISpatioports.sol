// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";
import "../ships/IShip.sol";

interface ISpatioports is IInfrastructure {
    struct Spatioport {
        uint256 level;
        IResource[] costsResources;
        uint256[] nextCosts;
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
