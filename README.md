# Sanctis contracts

This repositories contains the set of "canonical" smart contracts powering the _Sanctis, heart of the galaxy_.

Sanctis is an on-chain space colonization game where players incarnate a Commander guiding its empire to be one of the most powerful in the galaxy.
To do so, commanders can develop their planet, colonize new worlds, build a fleet, trade with other players or whatever they think will lead them to glory.

At the center of the galaxy lies the temple of ciilizations, the **Sanctis**. The Sanctis acts as the world government, controlled by commanders from all over the galaxy.

## How to use

- Build: `forge build && forge bind --bindings-path ./bindings --crate-name bindings`

## Motivation

This game was designed with [Rarity Manifested](https://github.com/andrecronje/rarity) in mind.
Rarity was a great experience that tried to build on what the [Loot (for adventurers)](https://www.lootproject.com/) project started: a community owned, accessible and highly creative experience.

Loot's base system is simple: a set of 8000 NFTs, each representing a set of RPG items.
After that, it was up to participants to build the rest of the universe.
There was a token, fan made derivatives such as lands, adventurers, etc.
But this approach had a downside:

- The limited number of NFTs made it hard to get, reducing the size of the core community.
  Not everybody in a community is capable of building on a blockchain and the limited stock + high demand + high fees reduced prevented potential community involvement.
- As the project was oriented toward high creativity, a lot of initiatives pushed the project in many different directions without really achieving long lasting, sustainable efforts.

Rarity addressed this issue by moving to Fantom, making it free for anyone to create an adventurer and giving a direction to the project by following Dungeons & Dragons guidelines.
It worked very well, with Rarity becoming one of the most used contract on Fantom.
But there were also limiting factors:

- Using a better defined base system made the ecosystem dependent on changes of the base. Not all contracts were available at the start and you had to wait for them to be available before building. For example, several community members wanted to have a skill system before the "official" one came out but spending time doing it would have been useless as the rest of the community would have used the official one when it becomes available. In general, despite the fact that was autonomous, it was highly centralized around the base implementation.
- Lack of sustainable financing of developments. As everything in the project is free, contributions were only open source. While this is great while it lasts, economic incentives help sustain work. There was a grant program, but it was just "VC money" charitably given to builders.
- Lack of leadership. The creator of Rarity explicitly wanted the project to be community driven. However, as explained in the points above, there was still some degree of centralization due to the structure of the project. This adds friction for contribution, as builders have to either get integrated in the official repository or be integrated in one of the main web UIs to have a chance to exist.
- Excessive botting. The game is so accessible that it's basically free to manage an army of adventurers. In-game items are therefore mostly worthless, as they can easily be farmed to infinity. This is making it hard to build any real value in the game, once again preventing financial sustainability.

The solutions for these issues that **Sanctis** is proposing are the following:

- A fully modular base system that allows using templated components and only adding game logics to them. This gives builders a framework to enhance composability and interactions with all the different elements in the game.
- A governance based game meta decisions. With ths Sanctis modular system, anyone can develop a new module and integrate it in the universe, however, to allow it to interact with the rest of the community modules, it needs to be accepted by the community through a governance process. This means that most modules will maintain a community-validated state and a general state, to handle its acceptance by the community. This prevents for example grieffing, where a malicious modules steals all the resources from a player.
- A small fee is required to play. The fee itself is decided by the community, meaning it can evolve with the game's needs. The funds collected can then be used to finance development and marketing and other community initiatives. The membership also offers some in-game advantages. This also limits botting, as you can automate some part of the game but cannot scale to an unlimited number of account.

## Game overview

This section will first present the different components of the galaxy.

![Sanctis' elements](./docs/Sanctis.jpg)

### Commanders

For players, commanders are the gateway to the world of Sanctis: most interactions require a commander and game items are generally held by the commander, not the player.
It is possible to create as many commanders as you want however, focusing on a few commanders should be more rewarding.

Anyone can create a commander, find a homeworld and start building for free.

Commanders are (NFTs)[https://en.wikipedia.org/wiki/Non-fungible_token] and can thus be traded in most standard NFT marketplace.

**Attributes**

- Race. Can give the commander synergies with certain resources, planets, infrastructures or specific ships.
- Name. Chosen by the player to identify his commanders.

### Planets

Your commander can colonize planets to expand its empire. The homeworld of your commander can be colonized immediatly but subsequent colonization require your commander to build colonization spaceships.

**Attributes**

- Seed. The unique identifier of your planet. This can be derived to create new attributes and interactions by other modules of Sanctis.
- A 3D position. In Sanctis, the galaxy can be divided into cubes and each cube hosts a planet.

### Infrastructures

Infrastructures can be built on planets and are used to interact with many objects of the galaxy such as resources and fleets.

### Resources

Each planet can have a vast amount of resources. Which resource is actually available generally depends on the resource and the planet's seed.

Resources can only be minted, burned and transferred by infrastructures and fleets.

### Fleets

Fleets are produced by infrastructures and make connections between planets. They can have many different purposes: trade, war are just a few of them.

### Sanctis

The Sanctis is the largest space station in the galaxy, where commanders meet to take decision on how the galaxy should work.
It is governed by Space Credits ($CRED) holders, the governance token of Sanctis and the base currency in most trades.

Only players who have at least one commander who is a citizen of the Sanctis can take part in the governance of the platform.
Becoming a citizen of the Sanctis will cost the player a small fee, used to fund game developments, contributor incentives and community management.

The governance of the Sanctis is split in two:

- The Council is a multisig in charge of handling resources (e.g. paying developers, marketing, etc).
- The Parliament is controlled by $CRED holders. Its main role is to determine what races, resources, fleets and infrastructures are allowed. As anybody can create new game elements, it is the community's duty to maintain game balances. The Parliament can also revoke Council members if they are deemed dangerous for the progress of the game.
