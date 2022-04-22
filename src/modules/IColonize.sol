// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisModule.sol";

interface IColonize is ISanctisModule {
    /// @notice Unknown planets have never been explored
    /// @notice Uncharted planets have been explored but are unoccupied
    /// @notice Colonized planets are controlled by a commander
    /// @notice The Sanctis
    //
    // uint8 constant PLANET_STATUS_UNKNOWN = 0;
    // uint8 constant PLANET_STATUS_UNCHARTED = 1;
    // uint8 constant PLANET_STATUS_SANCTIS = 2;
    // uint8 constant PLANET_STATUS_COLONIZED = 3;

    function colonize(uint256 ruler, uint256 planetId) external;

    function setColonizationCost(uint256 newCost) external;

    function colonizationCost() external view returns (uint256);
}
