// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisExtension.sol";

interface IPlanets is ISanctisExtension {
    event Changed(uint256 indexed id, uint256 indexed ruler, uint8 status);

    /// @notice Unknown planets have never been explored
    /// @notice Uncharted planets have been explored but are unoccupied
    /// @notice Colonized planets are controlled by a commander
    /// @notice The Sanctis
    //
    // uint8 constant PLANET_STATUS_UNKNOWN = 0;
    // uint8 constant PLANET_STATUS_UNCHARTED = 1;
    // uint8 constant PLANET_STATUS_COLONIZED = 2;
    // uint8 constant PLANET_STATUS_SANCTIS = 3;

    struct Planet {
        uint256 ruler;
        int80 x;
        int80 y;
        int80 z;
        uint8 humidity;
        uint8 status;
    }

    function create(uint256 planetId) external;

    function colonize(uint256 ruler, uint256 planetId) external;

    function setPlanet(
        uint256 planetId,
        uint256 ruler,
        uint8 status
    ) external;

    function planet(uint256 planetId) external view returns (Planet memory);

    function empireSize(uint256 commanderId) external view returns (uint256);

    function commanderPlanetByIndex(uint256 commanderId, uint256 index)
        external
        view
        returns (uint256);

    function distance(uint256 from, uint256 to) external view returns (uint256);
}
