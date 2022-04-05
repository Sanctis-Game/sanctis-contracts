// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../SanctisModule.sol";
import "./IRace.sol";

abstract contract Race is IRace, SanctisModule {
    string internal s_name;

    constructor(ISanctis sanctis_, string memory name_)
        SanctisModule(sanctis_)
    {
        s_name = name_;
    }

    /* ========== Resource interfaces ========== */
    function name() external view returns (string memory) {
        return s_name;
    }
}
