// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/IRace.sol";
import "../interfaces/ISanctis.sol";

contract Humans is IRace {
    string _name;

    constructor() {
        _name = "Humans";
    }

    function name() external view returns (string memory) {
        return _name;
    }
}
