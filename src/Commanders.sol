// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/ICommanders.sol";
import "./interfaces/IPlanets.sol";
import "./interfaces/ISanctis.sol";

contract Commanders is ICommanders, ERC721Enumerable, Ownable {
    mapping(uint256 => Citizen) private _commanders;
    uint256 private _createdCitizens;

    ISanctis public sanctis;

    constructor(ISanctis newSanctis) ERC721("Commanders", "CITIZEN") {
        transferOwnership(address(newSanctis.parliamentExecutor()));
        sanctis = newSanctis;
    }

    function create(
        string memory name,
        uint256 raceId
    ) external {
        _createdCitizens++;
        _mint(msg.sender, _createdCitizens);
        _commanders[_createdCitizens] = Citizen({
            name: name,
            raceId: raceId,
            onboarding: 0
        });
    }

    function onboard(uint256 citizenId) external {
        if (msg.sender != address(sanctis))
            revert NotTheCitadel({caller: msg.sender});

        _commanders[citizenId].onboarding = block.timestamp;
    }

    function offboard(uint256 citizenId) external {
        if (msg.sender != address(sanctis))
            revert NotTheCitadel({caller: msg.sender});

        _commanders[citizenId].onboarding = 0;
    }

    /* ========== CITIZENSHIP ========== */
    function citizen(uint256 citizenId)
        external
        view
        returns (Citizen memory)
    {
        return _commanders[citizenId];
    }

    function created() external view returns (uint256) {
        return _createdCitizens;
    }
}
