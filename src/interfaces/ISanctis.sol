// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/governance/IGovernor.sol";

import "./IPlanets.sol";
import "./ICommanders.sol";
import "./IFleets.sol";
import "./ISpaceCredits.sol";

interface ISanctis {
    error CitadelIsFull(uint256 capacity);
    error CitizenshipMoreExpensive(uint256 cost, uint256 paid);
    error NotCitizenOwner(uint256 citizen);
    error RaceNotAllowed(IRace race);

    function onboard(uint256 citizenId) external payable;

    function offboard(uint256 citizenId) external;

    function planets() external view returns (IPlanets);

    function commanders() external view returns (ICommanders);

    function credits() external view returns (ISpaceCredits);

    function fleets() external view returns (IFleets);

    function allowed(address) external view returns (bool);
    
    function setAllowed(address, bool) external;

    function parliamentExecutor() external view returns (address);

    function council() external view returns (address);

    function numberOfCitizens() external view returns (uint256);

    function citizenCapacity() external view returns (uint256);
}
