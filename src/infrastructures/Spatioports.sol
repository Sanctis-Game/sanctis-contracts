// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./Infrastructure.sol";
import "./ISpatioports.sol";

contract Spatioports is Infrastructure, ISpatioports {
    /* ========== Spatioport interfaces ========== */
    uint256 internal _discountFactor;

    constructor(
        ISanctis sanctis,
        uint256 delay,
        IResource[] memory costsResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates,
        uint256 discount
    ) Infrastructure(sanctis, delay, costsResources, costsBase, costsRates) {
        _discountFactor = discount;
    }

    /* ========== Spatioport interfaces ========== */
    function build(
        uint256 planetId,
        IShip ship,
        uint256 amount
    ) external {
        _assertInfrastructureExists(planetId);
        _isPlanetOwner(msg.sender, planetId);

        (IResource[] memory resources, uint256[] memory costs) = ship
            .unitCosts();
        uint256 discount = _discount(_infrastructures[planetId].level);
        uint256 i;
        for (; i < costs.length; ++i) {
            resources[i].burn(planetId, (costs[i] * amount * discount) / 10000);
        }

        ship.mint(planetId, amount);
    }

    function discountFactor() external view returns (uint256) {
        return _discountFactor;
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

    /* ========== Contract variables ========== */
    function _discount(uint256 level) internal view returns (uint256) {
        return _discountFactor**(level + 1) / 10000**level;
    }
}
