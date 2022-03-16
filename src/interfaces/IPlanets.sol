// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IPlanets {
    error InvalidPlanet(uint256 planet);
    error PlanetAlreadyExists(uint256 planet);
    error PlanetAlreadyColonized(uint256 planet, IPlanets.PlanetStatus status);
    error NotTheOwner(uint256 ruler);

    /// @notice Uncharted planets have never been explored
    /// @notice Colonized planets have at least settlement
    /// @notice Federated planets are ruled by a Citizen
    /// @notice Occupied planets lost control to a barbarian
    enum PlanetStatus {
        Unknown,
        Uncharted,
        Colonized,
        Federated,
        Occupied,
        Sanctis
    }

    struct Planet {
        PlanetStatus status;
        uint256 ruler;
        int80 x;
        int80 y;
        int80 z;
        uint8 humidity;
    }

    function create(uint256 planetId) external;

    function colonize(uint256 ruler, uint256 planetId) external;

    function planet(uint256 planetId) external view returns (Planet memory);

    function empireSize(uint256 commanderId) external view returns (uint256);

    function commanderPlanetByIndex(uint256 commanderId, uint256 index)
        external
        view
        returns (uint256);

    function distance(uint256 from, uint256 to) external view returns (uint256);
}
