// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./interfaces/IRaceRegistry.sol";

contract RaceRegistry is IRaceRegistry {
    mapping(uint256 => IRace) private _races;
    uint256 private _registeredRaces;

    function create(IRace newRace) external returns (uint256) {
        _registeredRaces++;
        _races[_registeredRaces] = newRace;
        return _registeredRaces;
    }

    function race(uint256 raceId) external view returns (IRace) {
        return _races[raceId];
    }

    function registeredRaces() external view returns (uint256) {
        return _registeredRaces;
    }
}
