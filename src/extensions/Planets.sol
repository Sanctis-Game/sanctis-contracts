// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "solmate/utils/FixedPointMathLib.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/ISpaceCredits.sol";
import "../SanctisExtension.sol";

contract Planets is IPlanets, SanctisExtension {
    using EnumerableSet for EnumerableSet.UintSet;
    using FixedPointMathLib for uint256;

    mapping(uint256 => Planet) private _planets;
    mapping(uint256 => EnumerableSet.UintSet) _commanderPlanets;

    uint256 public colonizationCost;

    constructor(
        ISanctis newSanctis,
        uint256 cost
    ) SanctisExtension("PLANETS", newSanctis) {
        colonizationCost = cost;

        // Placing the Sanctis at the center of the universe
        _planets[0] = Planet({
            status: PlanetStatus.Sanctis,
            ruler: 0,
            x: 0,
            y: 0,
            z: 0,
            humidity: 125
        });
    }

    function setColonizationCost(uint256 newCost) public onlyExecutor {
        colonizationCost = newCost;
    }

    function create(uint256 planetId) public {
        if(planetId > type(uint240).max)
            revert InvalidPlanet({planet: planetId});
        if (_planets[planetId].status != PlanetStatus.Unknown)
            revert PlanetAlreadyExists({planet: planetId});

        uint256 seed = uint256(keccak256(abi.encode(planetId)));
        uint8 humidity;
        unchecked {
            humidity = uint8(seed);
        }
        _planets[uint256(planetId)] = Planet({
            status: PlanetStatus.Uncharted,
            ruler: 0,
            x: int80(uint80(planetId & 0xFFFFF)),
            y: int80(uint80((planetId >> 80) & 0xFFFFF)),
            z: int80(uint80((planetId >> 160) & 0xFFFFF)),
            humidity: humidity
        });
    }

    function colonize(uint256 ruler, uint256 planetId) external {
        if  (_planets[planetId].status == PlanetStatus.Unknown)
            create(planetId);
        else if (_planets[planetId].status != PlanetStatus.Uncharted)
            revert PlanetAlreadyColonized({
                planet: planetId,
                status: _planets[planetId].status
            });

        if (ICommanders(sanctis.extension("COMMANDERS")).ownerOf(ruler) != msg.sender)
            revert NotTheOwner({ruler: planetId});

        _planets[planetId].ruler = ruler;
        _planets[planetId].status = PlanetStatus.Colonized;
        _commanderPlanets[ruler].add(planetId);

        ISpaceCredits(sanctis.extension("CREDITS")).transferFrom(
            msg.sender,
            sanctis.parliamentExecutor(),
            colonizationCost
        );
    }

    function planet(uint256 planetId) external view returns (Planet memory) {
        return _planets[planetId];
    }

    function empireSize(uint256 commanderId) external view returns (uint256) {
        return _commanderPlanets[commanderId].length();
    }

    function commanderPlanetByIndex(uint256 commanderId, uint256 index)
        external
        view
        returns (uint256)
    {
        return _commanderPlanets[commanderId].at(index);
    }

    function distance(uint256 from, uint256 to)
        external
        view
        returns (uint256)
    {
        Planet memory a = _planets[from];
        Planet memory b = _planets[to];
        return
            FixedPointMathLib.sqrt(
                uint256(int256((b.x - a.x)**2)) + uint256(int256((b.y - a.y)**2)) + uint256(int256((b.z - a.z)**2))
            );
    }
}
