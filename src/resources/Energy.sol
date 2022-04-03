// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Resource.sol";

contract Energy is Resource {
    /* ========== Sanctis extensions used ========== */
    bytes32 constant FLEETS = "FLEETS";

    constructor(ISanctis _sanctis) Resource(_sanctis, "Energy", "NRG") {}

    function mint(uint256 planetId, uint256 amount)
        external
        override
        onlyAllowed
    {
        _reserves[planetId] += amount;
        emit Mint(planetId, amount);
    }

    function burn(uint256 planetId, uint256 amount)
        external
        override
        onlyAllowed
    {
        require(
            msg.sender != s_sanctis.extension(FLEETS),
            "No fleet transfer"
        );
        _reserves[planetId] -= amount;
        emit Burn(planetId, amount);
    }
}
