// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IResource.sol";

struct Quantity {
    IResource resource;
    uint256 quantity;
}
