// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/ISanctis.sol";
import "./Resource.sol";

contract Energy is Resource {
    constructor(ISanctis sanctis) Resource(sanctis, "Iron") {}
}
