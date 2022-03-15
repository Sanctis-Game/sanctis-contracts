// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IRace.sol";
import "../interfaces/ISanctis.sol";

contract Humans is IRace {
    uint256 _id;
    string _name;

    constructor(ISanctis sanctis) {
        _id = sanctis.raceRegistry().create(this);
        _name = "Humans";
    }

    function id() external view returns (uint256) {
        return _id;
    }

    function name() external view returns (string memory) {
        return _name;
    }
}
