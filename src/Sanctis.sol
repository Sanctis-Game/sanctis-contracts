// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "./ISanctis.sol";
import "./Parliament.sol";

/// @title The Sanctis, heart of the galaxy
/// @author Dodecahedr0x
/// @notice Commanders can onboard the Sanctis using this contract
/// @notice The Sanctis also handles registered races, ressources and ships
contract Sanctis is ISanctis, Ownable {
    /* ========== Contract variables ========== */
    // Governance
    address internal s_parliamentExecutor;
    // Metagame
    mapping(address => bool) internal s_allowed;
    mapping(bytes32 => address) internal s_extensions;

    /* ========== GOVERNANCE ========== */
    function parliamentExecutor() external view returns (address) {
        return s_parliamentExecutor;
    }

    function setParliamentExecutor(address newParliamentExecutor)
        external
        onlyOwner
    {
        s_parliamentExecutor = newParliamentExecutor;
        transferOwnership(newParliamentExecutor);
    }

    /* ========== MODULES ========== */
    function allowed(address object) external view returns (bool) {
        return s_allowed[object];
    }

    function setAllowed(address object, bool value) external onlyOwner {
        s_allowed[object] = value;
    }

    /* ========== EXTENSIONS ========== */
    function extension(bytes32 key) external view returns (address) {
        return s_extensions[key];
    }

    function insertAndAllowExtension(ISanctisExtension object)
        external
        onlyOwner
    {
        s_allowed[address(object)] = true;
        s_extensions[object.key()] = address(object);
    }

    function reloadExtension(ISanctisExtension object) external onlyOwner {
        s_extensions[object.key()] = address(object);
    }

    function ejectAndDisallowExtension(ISanctisExtension object)
        external
        onlyOwner
    {
        s_allowed[address(object)] = false;
        s_extensions[object.key()] = address(0);
    }
}
