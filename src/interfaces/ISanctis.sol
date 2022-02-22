// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/governance/IGovernor.sol";

import "./IPlanets.sol";
import "./ICommanders.sol";
import "./IFleets.sol";
import "./ISpaceCredits.sol";
import "./IGalacticStandards.sol";
import "./IRaceRegistry.sol";
import "./IResourceRegistry.sol";
import "./IInfrastructureRegistry.sol";
import "./IShipRegistry.sol";

interface ISanctis {
    error CitadelIsFull(uint256 capacity);
    error CitizenshipMoreExpensive(uint256 cost, uint256 paid);
    error NotCitizenOwner(uint256 citizen);
    error RaceNotAllowed(uint256 race);

    function onboard(uint256 citizenId) external payable;

    function offboard(uint256 citizenId) external;

    function add(IGalacticStandards.StandardType standard, uint256 id) external;

    function remove(IGalacticStandards.StandardType standard, uint256 id)
        external;

    function planets() external view returns (IPlanets);

    function commanders() external view returns (ICommanders);

    function credits() external view returns (ISpaceCredits);

    function fleets() external view returns (IFleets);

    function standards() external view returns (IGalacticStandards);

    function parliamentExecutor() external view returns (address);

    function council() external view returns (address);

    function raceRegistry() external view returns (IRaceRegistry);

    function resourceRegistry() external view returns (IResourceRegistry);

    function infrastructureRegistry()
        external
        view
        returns (IInfrastructureRegistry);

    function shipRegistry() external view returns (IShipRegistry);

    function numberOfCitizens() external view returns (uint256);

    function citizenCapacity() external view returns (uint256);
}
