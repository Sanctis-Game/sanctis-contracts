// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Race.sol";

contract Humans is Race {
    constructor(ISanctis _sanctis) Race(_sanctis, "Humans") {}
}
