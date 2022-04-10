// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "solmate/utils/FixedPointMathLib.sol";

import "../ISanctis.sol";
import "../extensions/IPlanets.sol";
import "../extensions/ICommanders.sol";
import "../extensions/ISpaceCredits.sol";
import "../SanctisExtension.sol";

contract Planets is IPlanets, SanctisExtension {
    using EnumerableSet for EnumerableSet.UintSet;
    using FixedPointMathLib for uint256;

    /* ========== Sanctis extensions used ========== */
    bytes32 constant COMMANDERS = bytes32("COMMANDERS");
    bytes32 constant CREDITS = bytes32("CREDITS");
    bytes32 constant PLANETS = bytes32("PLANETS");

    /* ========== Contract variables ========== */
    uint8 constant PLANET_STATUS_UNKNOWN = 0;
    uint8 constant PLANET_STATUS_UNCHARTED = 1;
    uint8 constant PLANET_STATUS_COLONIZED = 2;
    uint8 constant PLANET_STATUS_SANCTIS = 3;

    mapping(uint256 => Planet) private _planets;
    mapping(uint256 => EnumerableSet.UintSet) _commanderPlanets;
    uint256 public colonizationCost;

    constructor(ISanctis newSanctis, uint256 cost)
        SanctisExtension(PLANETS, newSanctis)
    {
        colonizationCost = cost;

        // Placing the Sanctis at the center of the universe
        _planets[0] = Planet({
            status: PLANET_STATUS_SANCTIS,
            ruler: 0,
            x: 0,
            y: 0,
            z: 0,
            humidity: 125
        });

        emit Changed({id: 0, status: PLANET_STATUS_SANCTIS});
    }

    function setColonizationCost(uint256 newCost) public onlyExecutor {
        colonizationCost = newCost;
    }

    function create(uint256 planetId) public {
        if (planetId > type(uint240).max)
            revert InvalidPlanet({planet: planetId});
        if (_planets[planetId].status != PLANET_STATUS_UNKNOWN)
            revert PlanetAlreadyExists({planet: planetId});

        uint256 seed = uint256(keccak256(abi.encode(planetId)));
        uint8 humidity;
        unchecked {
            humidity = uint8(seed);
        }
        _planets[uint256(planetId)] = Planet({
            status: PLANET_STATUS_UNCHARTED,
            ruler: 0,
            x: int80(int256(planetId & 0xFFFFF)),
            y: int80(int256((planetId >> 80) & 0xFFFFF)),
            z: int80(int256((planetId >> 160) & 0xFFFFF)),
            humidity: humidity
        });

        emit Changed({id: planetId, status: PLANET_STATUS_UNCHARTED});
    }

    function colonize(uint256 ruler, uint256 planetId) external {
        if (_planets[planetId].status == PLANET_STATUS_UNKNOWN)
            create(planetId);
        else if (_planets[planetId].status != PLANET_STATUS_UNCHARTED)
            revert PlanetAlreadyColonized({
                planet: planetId,
                status: _planets[planetId].status
            });

        if (
            ICommanders(s_sanctis.extension(COMMANDERS)).ownerOf(ruler) !=
            msg.sender
        ) revert NotTheOwner({ruler: planetId});

        _planets[planetId].ruler = ruler;
        _planets[planetId].status = PLANET_STATUS_COLONIZED;
        _commanderPlanets[ruler].add(planetId);

        ISpaceCredits(s_sanctis.extension(CREDITS)).transferFrom(
            msg.sender,
            s_sanctis.parliamentExecutor(),
            colonizationCost
        );

        emit Changed({id: planetId, status: PLANET_STATUS_COLONIZED});
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
                uint256(int256((b.x - a.x)**2)) +
                    uint256(int256((b.y - a.y)**2)) +
                    uint256(int256((b.z - a.z)**2))
            );
    }

    function setPlanet(
        uint256 planetId,
        uint256 ruler,
        uint8 status
    ) public onlyAllowed {
        _planets[planetId].ruler = ruler;
        _planets[planetId].status = status;
    }
}
