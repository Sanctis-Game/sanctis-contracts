// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "solmate/utils/FixedPointMathLib.sol";

import "./interfaces/ISanctis.sol";
import "./interfaces/IPlanets.sol";

contract Planets is IPlanets, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using FixedPointMathLib for uint256;

    mapping(uint256 => Planet) private _planets;
    mapping(uint256 => EnumerableSet.UintSet) _commanderPlanets;

    ISanctis public sanctis;
    uint256 public colonizationCost;

    constructor(
        ISanctis newSanctis,
        ISpaceCredits credits,
        uint256 cost
    ) {
        transferOwnership(address(newSanctis.parliamentExecutor()));
        sanctis = newSanctis;
        colonizationCost = cost;
        credits.approve(sanctis.council(), colonizationCost);
    }

    function create(uint256 planetId) public {
        if(planetId > type(uint256).max)
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

        if (sanctis.commanders().ownerOf(ruler) != msg.sender)
            revert NotTheOwner({ruler: planetId});

        _planets[planetId].ruler = ruler;
        _planets[planetId].status = PlanetStatus.Colonized;
        _commanderPlanets[ruler].add(planetId);

        sanctis.credits().transferFrom(
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
                uint80((b.x - a.x)**2) + uint80((b.y - a.y)**2) + uint80((b.z - a.z)**2)
            );
    }

    function _isCreated(uint256 planetId) external view returns (bool) {
        return _planets[planetId].status != PlanetStatus.Unknown;
    }
}
