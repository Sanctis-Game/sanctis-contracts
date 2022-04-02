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
    // Governance
    address internal _parliamentExecutor;

    // Metagame
    mapping(address => bool) internal _allowed;
    mapping(bytes32 => address) internal _extensions;

    /* ========== GOVERNANCE ========== */
    function parliamentExecutor() external view returns (address) {
        return _parliamentExecutor;
    }

    function setParliamentExecutor(address newParliamentExecutor)
        external
        onlyOwner
    {
        _parliamentExecutor = newParliamentExecutor;
        transferOwnership(newParliamentExecutor);
    }

    /* ========== MODULES ========== */
    function allowed(address object) external view returns (bool) {
        return _allowed[object];
    }

    function setAllowed(address object, bool value) external onlyOwner {
        _allowed[object] = value;
    }

    /* ========== EXTENSIONS ========== */
    function extension(bytes32 key) external view returns (address) {
        return _extensions[key];
    }

    function insertAndAllowExtension(ISanctisExtension object)
        external
        onlyOwner
    {
        _allowed[address(object)] = true;
        _extensions[object.key()] = address(object);
    }

    function reloadExtension(ISanctisExtension object) external onlyOwner {
        _extensions[object.key()] = address(object);
    }

    function ejectAndDisallowExtension(ISanctisExtension object)
        external
        onlyOwner
    {
        _allowed[address(object)] = false;
        _extensions[object.key()] = address(0);
    }
}
