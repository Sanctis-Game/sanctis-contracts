// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../interfaces/ISanctis.sol";
import "./Resource.sol";

contract Iron is Resource {
    constructor(ISanctis sanctis) Resource(sanctis, "Iron") {}
}
