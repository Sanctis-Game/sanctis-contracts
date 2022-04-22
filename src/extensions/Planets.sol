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
    uint8 constant PLANET_STATUS_SANCTIS = 2;
    uint8 constant PLANET_STATUS_COLONIZED = 3;

    mapping(uint256 => Planet) private s_planets;
    mapping(uint256 => EnumerableSet.UintSet) s_commanderPlanets;

    constructor(ISanctis newSanctis) SanctisExtension(PLANETS, newSanctis) {
        // Placing the Sanctis at the center of the universe
        s_planets[0] = Planet({
            status: PLANET_STATUS_SANCTIS,
            ruler: 0,
            x: 0,
            y: 0,
            z: 0,
            humidity: 125
        });

        emit Changed({id: 0, ruler: 0, status: PLANET_STATUS_SANCTIS});
    }

    function create(uint256 planetId) public {
        require(planetId <= type(uint240).max, "Planets: ID");
        require(
            s_planets[planetId].status == PLANET_STATUS_UNKNOWN,
            "Planets: Exists"
        );

        uint256 seed = uint256(keccak256(abi.encode(planetId)));
        uint8 humidity;
        unchecked {
            humidity = uint8(seed);
        }
        s_planets[uint256(planetId)] = Planet({
            status: PLANET_STATUS_UNCHARTED,
            ruler: 0,
            x: int80(int256(planetId & 0xFFFFF)),
            y: int80(int256((planetId >> 80) & 0xFFFFF)),
            z: int80(int256((planetId >> 160) & 0xFFFFF)),
            humidity: humidity
        });

        emit Changed({id: planetId, ruler: 0, status: PLANET_STATUS_UNCHARTED});
    }

    function planet(uint256 planetId) external view returns (Planet memory) {
        return s_planets[planetId];
    }

    function empireSize(uint256 commanderId) external view returns (uint256) {
        return s_commanderPlanets[commanderId].length();
    }

    function commanderPlanetByIndex(uint256 commanderId, uint256 index)
        external
        view
        returns (uint256)
    {
        return s_commanderPlanets[commanderId].at(index);
    }

    function distance(uint256 from, uint256 to)
        external
        view
        returns (uint256)
    {
        Planet memory a = s_planets[from];
        Planet memory b = s_planets[to];
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
        s_planets[planetId].ruler = ruler;
        s_planets[planetId].status = status;

        emit Changed({
            id: planetId,
            ruler: ruler,
            status: PLANET_STATUS_COLONIZED
        });
    }
}
