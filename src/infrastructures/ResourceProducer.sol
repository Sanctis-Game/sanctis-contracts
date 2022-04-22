// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./Infrastructure.sol";
import "./IResourceProducer.sol";

contract ResourceProducer is Infrastructure, IResourceProducer {
    /* ========== Contract variables ========== */
    mapping(uint256 => uint256) internal s_lastHarvests;
    IResource[] internal s_rewardsResources;
    uint256[] internal s_rewardsBase;
    uint256[] internal s_rewardsRates;

    constructor(
        ISanctis sanctis,
        uint256 delay,
        IResource[] memory rewardsResources,
        uint256[] memory rewardsBase,
        uint256[] memory rewardsRates,
        IResource[] memory costsResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates
    ) Infrastructure(sanctis, delay, costsResources, costsBase, costsRates) {
        require(
            rewardsResources.length == rewardsBase.length &&
                rewardsBase.length == rewardsRates.length,
            "Rewards mismatch"
        );
        for (uint256 i = 0; i < rewardsBase.length; i++) {
            s_rewardsResources.push(rewardsResources[i]);
            s_rewardsBase.push(rewardsBase[i]);
            s_rewardsRates.push(rewardsRates[i]);
        }
    }

    /* ========== Extractor interfaces ========== */
    function harvest(uint256 planetId) public {
        require(
            s_infrastructures[planetId].level > 0,
            "ResourceProducer: Level"
        );

        uint256[] memory harvestable = _production(
            s_infrastructures[planetId].level
        );
        uint256 elapsedBlocks = block.number - s_lastHarvests[planetId];
        s_lastHarvests[planetId] = block.number;

        for (uint256 i = 0; i < harvestable.length; i++) {
            s_rewardsResources[i].mint(
                planetId,
                harvestable[i] * elapsedBlocks
            );
        }
    }

    function lastHarvest(uint256 planetId) external view returns (uint256) {
        return s_lastHarvests[planetId];
    }

    function currentProduction(uint256 planetId)
        external
        view
        returns (IResource[] memory, uint256[] memory)
    {
        return (
            s_rewardsResources,
            _production(s_infrastructures[planetId].level)
        );
    }

    function nextProduction(uint256 planetId)
        external
        view
        returns (IResource[] memory, uint256[] memory)
    {
        return (
            s_rewardsResources,
            _production(s_infrastructures[planetId].level + 1)
        );
    }

    /* ========== Infrastructure hooks ========== */
    function _beforeCreation(uint256 planetId) internal override {
        _planetHasResource(planetId);

        s_lastHarvests[planetId] = block.number;
    }

    function _beforeUpgrade(uint256 planetId) internal override {
        harvest(planetId);
    }

    /* ========== Helpers ========== */
    function _planetHasResource(uint256 planetId) internal view {
        for (uint256 i = 0; i < s_rewardsBase.length; i++)
            require(
                s_rewardsResources[i].isAvailableOnPlanet(planetId),
                "ResourceProducer: Resource"
            );
    }

    function _production(uint256 infraLevel)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory production = s_rewardsBase;
        for (uint256 i = 0; i < production.length; i++) {
            production[i] += infraLevel * s_rewardsRates[i];
        }
        return production;
    }
}
