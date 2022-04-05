// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./Infrastructure.sol";
import "./IPowerPlants.sol";

contract PowerPlants is Infrastructure, IPowerPlants {
    /* ========== Contract variables ========== */
    IResource internal s_energy;
    uint256 internal s_rewardsBase;
    uint256 internal s_rewardsRates;

    constructor(
        ISanctis sanctis,
        IResource _energy,
        uint256 rewardsBase,
        uint256 rewardsRates,
        uint256 delay,
        IResource[] memory costsResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates
    ) Infrastructure(sanctis, delay, costsResources, costsBase, costsRates) {
        s_energy = _energy;
        s_rewardsBase = rewardsBase;
        s_rewardsRates = rewardsRates;
    }

    /* ========== Power plant interfaces ========== */
    function energy() external view returns (IResource) {
        return s_energy;
    }

    function currentProduction(uint256 planetId)
        external
        view
        returns (uint256)
    {
        return _production(s_infrastructures[planetId].level);
    }

    function nextProduction(uint256 planetId) external view returns (uint256) {
        return _production(s_infrastructures[planetId].level + 1);
    }

    /* ========== Infrastructure interfaces ========== */
    function _beforeCreation(uint256 planetId) internal override {
        s_energy.mint(planetId, _production(0));
    }

    function _beforeUpgrade(uint256 planetId) internal override {
        s_energy.mint(
            planetId,
            _production(s_infrastructures[planetId].level) -
                _production(s_infrastructures[planetId].level - 1)
        );
    }

    /* ========== Helpers ========== */
    function _production(uint256 infraLevel) internal view returns (uint256) {
        return s_rewardsBase + infraLevel * s_rewardsRates;
    }
}
