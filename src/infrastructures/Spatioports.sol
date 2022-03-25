// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/Quantity.sol";
import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResource.sol";
import "../interfaces/ISpatioports.sol";
import "./Infrastructure.sol";

contract Spatioports is Infrastructure, ISpatioports {
    constructor(
        ISanctis sanctis,
        uint256 delay,
        Quantity[] memory baseCosts,
        Quantity[] memory costRates
    ) Infrastructure(sanctis, delay, baseCosts, costRates) {}

    /* ========== Spatioport interfaces ========== */
    function build(
        uint256 planetId,
        IShip ship,
        uint256 amount
    ) external {
        _assertInfrastructureExists(planetId);
        _isPlanetOwner(msg.sender, planetId);

        // Costs are handled by the ship
        ship.build(planetId, amount);
    }

    function spatioport(uint256 planetId)
        public
        view
        returns (Spatioport memory)
    {
        return
            Spatioport({
                level: _infrastructures[planetId].level,
                nextCosts: _costsAtLevel(_infrastructures[planetId].level),
                nextUpgrade: _infrastructures[planetId].lastUpgrade
            });
    }
}
