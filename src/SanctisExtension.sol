// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/ISanctis.sol";
import "./interfaces/ISanctisExtension.sol";
import "./SanctisModule.sol";

abstract contract SanctisExtension is SanctisModule, ISanctisExtension {
    string _key;

    constructor(string memory key_, ISanctis _sanctis) SanctisModule(_sanctis) {
        _key = key_;
    }

    function key() external view returns(string memory) {
        return _key;
    }
}
