// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IGalacticStandards.sol";

/// @notice Registers all allowed structures
contract GalacticStandards is IGalacticStandards, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet private _races;
    EnumerableSet.UintSet private _resources;
    EnumerableSet.UintSet private _ships;
    EnumerableSet.UintSet private _infrastructures;

    constructor(address sanctis) {
        transferOwnership(sanctis);
    }

    function add(StandardType standard, uint256 id) external onlyOwner {
        if (standard == StandardType.Race) _races.add(id);
        else if (standard == StandardType.Resource) _resources.add(id);
        else if (standard == StandardType.Ship) _ships.add(id);
        else _infrastructures.add(id);
    }

    function remove(StandardType standard, uint256 id) external onlyOwner {
        if (standard == StandardType.Race) _races.remove(id);
        else if (standard == StandardType.Resource) _resources.remove(id);
        else if (standard == StandardType.Ship) _ships.remove(id);
        else _infrastructures.remove(id);
    }

    function isAllowed(StandardType standard, uint256 id)
        external
        view
        returns (bool)
    {
        if (standard == StandardType.Race) return _races.contains(id);
        else if (standard == StandardType.Resource)
            return _resources.contains(id);
        else if (standard == StandardType.Ship) return _ships.contains(id);
        else return _infrastructures.contains(id);
    }

    function count(StandardType standard) external view returns (uint256) {
        if (standard == StandardType.Race) return _races.length();
        else if (standard == StandardType.Resource) return _resources.length();
        else if (standard == StandardType.Ship) return _ships.length();
        else return _infrastructures.length();
    }

    function getByIndex(StandardType standard, uint256 index)
        external
        view
        returns (uint256)
    {
        if (standard == StandardType.Race) return _races.at(index);
        else if (standard == StandardType.Resource) return _resources.at(index);
        else if (standard == StandardType.Ship) return _ships.at(index);
        else return _infrastructures.at(index);
    }
}
