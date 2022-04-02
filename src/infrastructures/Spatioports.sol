// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./Infrastructure.sol";
import "./ISpatioports.sol";

contract Spatioports is Infrastructure, ISpatioports {
    constructor(
        ISanctis sanctis,
        uint256 delay,
        IResource[] memory costsResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates
    ) Infrastructure(sanctis, delay, costsResources, costsBase, costsRates) {}

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
                costsResources: _costsResources,
                nextCosts: _costsAtLevel(_infrastructures[planetId].level),
                nextUpgrade: _infrastructures[planetId].lastUpgrade
            });
    }
}
