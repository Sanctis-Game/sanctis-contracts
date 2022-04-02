// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisModule.sol";
import "../resources/IResource.sol";

interface IShip is ISanctisModule {
    error UnauthorizedPlayer(address player, uint256 planet);
    error UnallowedOperator(address operator);
    error InvalidFleet(uint256 fleet);
    error NotEnoughReserve(uint256 planet, uint256 amount);
    error PlanetNotOwned(address player, uint256 planet);

    function speed() external view returns (uint256);

    function offensivePower() external view returns (uint256);

    function defensivePower() external view returns (uint256);

    function capacity() external view returns (uint256);

    function unitCosts()
        external
        view
        returns (IResource[] memory, uint256[] memory);

    function reserve(uint256 planetId) external view returns (uint256);

    function mint(uint256 planetId, uint256 amount) external;

    function burn(uint256 planetId, uint256 amount) external;
}
