// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IRace.sol";

interface IRaceRegistry {
    function create(IRace newRace) external returns (uint256);

    function race(uint256 raceId) external view returns (IRace);

    function registeredRaces() external view returns (uint256);
}
