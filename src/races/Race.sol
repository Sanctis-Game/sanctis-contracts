// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IRace.sol";
import "../SanctisModule.sol";

abstract contract Race is IRace, SanctisModule {
    string internal _name;

    constructor(ISanctis sanctis_, string memory name_) SanctisModule(sanctis_) {
        _name = name_;
    }

    /* ========== Resource interfaces ========== */
    function name() external view returns (string memory) {
        return _name;
    }
}
