// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/ISpaceCredits.sol";
import "./interfaces/ISanctis.sol";
import "./interfaces/IPlanets.sol";
import "./interfaces/ICommanders.sol";
import "./interfaces/IFleets.sol";
import "./Parliament.sol";

/// @title The Sanctis, heart of the galaxy
/// @author Dodecahedr0x
/// @notice Commanders can onboard the Sanctis using this contract
/// @notice The Sanctis also handles registered races, ressources and ships
contract Sanctis is ISanctis, Ownable {
    /* ========== STATE VARIABLES ========== */
    /// @notice Commanders can onboard the Sanctis using this contract
    uint256 _numberOfCitizens;
    /// @notice Maximum number of citizen the Sanctis can have
    uint256 _citizensCapacity;
    /// @notice The cost for a citizen to onboard the Sanctis
    uint256 _citizenshipCost;

    IPlanets internal _planets;
    ICommanders internal _commanders;
    ISpaceCredits internal _credits;
    IFleets internal _fleets;

    // Governance
    address internal _parliamentExecutor;
    address internal _council;

    // Metagame
    mapping(address => bool) internal _allowed;

    /* ========== INITIALIZATION ========== */
    function setGovernance(
        address newParliamentExecutor,
        address newCouncil,
        ISpaceCredits newCredits
    ) external onlyOwner {
        _parliamentExecutor = newParliamentExecutor;
        _council = newCouncil;
        _credits = newCredits;
    }

    function setWorld(
        IPlanets newPlanets,
        ICommanders newCommanders,
        IFleets newFleets,
        uint256 capacity
    ) external onlyOwner {
        _planets = newPlanets;
        _commanders = newCommanders;
        _fleets = newFleets;
        _citizensCapacity = capacity;
    }

    /* ========== CITIZENSHIP ========== */
    /// @notice Onboards an existing citizen in the Sanctis
    /// @param citizenId The name of the new Citizen
    function onboard(uint256 citizenId) external payable {
        if (_numberOfCitizens >= _citizensCapacity)
            revert CitadelIsFull({capacity: _citizensCapacity});
        if (msg.value < _citizenshipCost)
            revert CitizenshipMoreExpensive({
                cost: _citizenshipCost,
                paid: msg.value
            });
        if (msg.sender != ICommanders(_commanders).ownerOf(citizenId))
            revert NotCitizenOwner({citizen: citizenId});
        if (!_allowed[address(_commanders.commander(citizenId).race)])
            revert RaceNotAllowed({race: _commanders.commander(citizenId).race});

        _commanders.onboard(citizenId);
    }

    /// @notice Offboards an existing citizen from the Sanctis
    /// @param citizenId The name of the exiling Citizen
    function offboard(uint256 citizenId) external {
        require(msg.sender == _commanders.ownerOf(citizenId), "not owner");

        _commanders.offboard(citizenId);
    }

    /* ========== INTERFACE GETTERS ========== */
    function planets() external view returns (IPlanets) {
        return _planets;
    }

    function commanders() external view returns (ICommanders) {
        return _commanders;
    }

    function credits() external view returns (ISpaceCredits) {
        return _credits;
    }

    function fleets() external view returns (IFleets) {
        return _fleets;
    }

    function allowed(address object) external view returns (bool) {
        return _allowed[object];
    }

    function setAllowed(address object, bool value) external onlyOwner {
        _allowed[object] = value;
    }

    function parliamentExecutor() external view returns (address) {
        return _parliamentExecutor;
    }

    function council() external view returns (address) {
        return _council;
    }

    /// @notice This is different from the supply of Citizen
    function numberOfCitizens() external view override returns (uint256) {
        return _numberOfCitizens;
    }

    function citizenCapacity() external view override returns (uint256) {
        return _citizensCapacity;
    }
}
