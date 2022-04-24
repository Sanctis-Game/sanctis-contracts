// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IColonize.sol";
import "../SanctisModule.sol";
import "../extensions/ICommanders.sol";
import "../extensions/IPlanets.sol";
import "../extensions/ISpaceCredits.sol";

contract Colonize is IColonize, SanctisModule {
    /* ========== Sanctis extensions used ========== */
    bytes32 constant COMMANDERS = bytes32("COMMANDERS");
    bytes32 constant CREDITS = bytes32("CREDITS");
    bytes32 constant PLANETS = bytes32("PLANETS");

    /* ========== Contract variables ========== */
    uint8 constant PLANET_STATUS_UNKNOWN = 0;
    uint8 constant PLANET_STATUS_UNCHARTED = 1;
    uint8 constant PLANET_STATUS_SANCTIS = 2;
    uint8 constant PLANET_STATUS_COLONIZED = 3;

    /// @notice Cost to colonize a planet, paid to the Sanctis
    uint256 internal s_colonizationCost;

    constructor(ISanctis newSanctis, uint256 cost) SanctisModule(newSanctis) {
        s_colonizationCost = cost;
    }

    function colonize(uint256 ruler, uint256 planetId) external {
        if (
            IPlanets(s_sanctis.extension(PLANETS)).planet(planetId).status ==
            PLANET_STATUS_UNKNOWN
        ) IPlanets(s_sanctis.extension(PLANETS)).create(planetId);
        require(
            IPlanets(s_sanctis.extension(PLANETS)).planet(planetId).status ==
                PLANET_STATUS_UNCHARTED,
            "Colonized: Status"
        );
        require(
            ICommanders(s_sanctis.extension(COMMANDERS)).ownerOf(ruler) ==
                msg.sender,
            "Colonized: Owner"
        );

        IPlanets(s_sanctis.extension(PLANETS)).setPlanet(
            planetId,
            ruler,
            PLANET_STATUS_COLONIZED
        );

        ISpaceCredits(s_sanctis.extension(CREDITS)).transferFrom(
            msg.sender,
            s_sanctis.parliamentExecutor(),
            s_colonizationCost
        );
    }

    function setColonizationCost(uint256 newCost) public onlyExecutor {
        s_colonizationCost = newCost;
    }

    function colonizationCost() external view returns (uint256) {
        return s_colonizationCost;
    }
}
