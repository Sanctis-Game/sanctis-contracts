// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisModule.sol";

interface IResource is ISanctisModule {
    error Unallowed(address sender);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function mint(uint256 planetId, uint256 amount) external;

    function burn(uint256 planetId, uint256 amount) external;

    function isAvailableOnPlanet(uint256 planetId) external view returns (bool);

    function reserve(uint256 planetId) external view returns (uint256);
}
