// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/ISanctis.sol";
import "./Resource.sol";

contract Energy is Resource {
    constructor(ISanctis sanctis) Resource(sanctis, "Energy", "NRG") {}

    function mint(uint256 planetId, uint256 amount)
        external
        override
        onlyAllowed
    {
        _reserves[planetId] += amount;
    }

    function burn(uint256 planetId, uint256 amount)
        external
        override
        onlyAllowed
    {
        require(msg.sender != sanctis.extension("FLEETS"), "Non transferrable through fleets");
        _reserves[planetId] -= amount;
    }
}
