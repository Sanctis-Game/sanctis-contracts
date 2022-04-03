import json
from foundrydeploy import Deployer, Signer, KeyKind

with open("key.json") as f:
    keypair = json.load(f)


class Network:
    LOCAL = "--rpc-url http://127.0.0.1:8545"
    FTM_MAINNET = "--rpc-url https://rpc.fantom.network/"
    FTM_TESTNET = "--rpc-url https://xapi.testnet.fantom.network/lachesis"


signer = Signer(
    keypair["public"],
    KeyKind.PRIVATE,
    keypair["private"],
)

contracts = [
    # (Contract Label, ContractPath:ContractName, ContractAddress)
    ("sanctis", "src/Sanctis.sol:Sanctis"),
    ("credits", "src/extensions/SpaceCredits.sol:SpaceCredits"),
    ("parliament", "src/Parliament.sol:Parliament"),
    ("commanders", "src/extensions/Commanders.sol:Commanders"),
    ("planets", "src/extensions/Planets.sol:Planets"),
    ("fleets", "src/extensions/Fleets.sol:Fleets"),
    ("humans", "src/races/Humans.sol:Humans"),
    ("energy", "src/resources/Energy.sol:Energy"),
    ("iron", "src/resources/Resource.sol:Resource"),
    ("deuterium", "src/resources/Resource.sol:Resource"),
    ("silicon", "src/resources/Resource.sol:Resource"),
    ("ironMines", "src/infrastructures/ResourceProducer.sol:ResourceProducer"),
    ("siliconFurnaces", "src/infrastructures/ResourceProducer.sol:ResourceProducer"),
    ("heavyWaterPlants", "src/infrastructures/ResourceProducer.sol:ResourceProducer"),
    ("solarPanels", "src/infrastructures/PowerPlants.sol:PowerPlants"),
    ("fusionPlants", "src/infrastructures/PowerPlants.sol:PowerPlants"),
    ("spatioports", "src/infrastructures/Spatioports.sol:Spatioports"),
    ("transporters", "src/ships/Ship.sol:Ship"),
    ("scouts", "src/ships/Ship.sol:Ship"),
    ("destroyers", "src/ships/Ship.sol:Ship"),
    ("plundering", "src/modules/Plundering.sol:Plundering"),
    ("resourceWrapper", "src/utils/ResourceWrapper.sol:ResourceWrapper"),
]

deployer = Deployer(
    Network.FTM_TESTNET,
    signer,
    contracts,
    is_legacy=True,  # for legacy transactions
    debug=True,  # if True, prints the calling commands and raw output
    name="test2.2",
)

path = [
    # Format :
    # (ACTION_TYPE, CONTRACT_LABEL, [ARG, ... ])
    # Governance
    (Deployer.DEPLOY, "sanctis", []),
    (
        Deployer.DEPLOY,
        "credits",
        ["$sanctis"],
    ),
    (Deployer.DEPLOY, "parliament", ["$credits", keypair["public"]]),
    # Extensions
    (Deployer.DEPLOY, "commanders", ["$sanctis"]),
    (Deployer.DEPLOY, "planets", ["$sanctis", "10000000000000000000"]),
    (Deployer.DEPLOY, "fleets", ["$sanctis"]),
    # Resource
    (Deployer.DEPLOY, "humans", ["$sanctis"]),
    (Deployer.DEPLOY, "energy", ["$sanctis"]),
    (Deployer.DEPLOY, "iron", ["$sanctis", "Iron", "IRON"]),
    (Deployer.DEPLOY, "deuterium", ["$sanctis", "Deuterium", "DEUT"]),
    (Deployer.DEPLOY, "silicon", ["$sanctis", "Silicon", "SILI"]),
    # Resource Infrastructures
    (
        Deployer.DEPLOY,
        "ironMines",
        [
            "$sanctis",
            "36",  # Delay
            f"[$iron]",  # Rewards resources
            f"[1000000000000000000]",  # Rewards base
            f"[1000000000000000000]",  # Rewards rate
            f"[$iron,$energy]",  # Costs Resources
            f"[0,0]",  # Costs Base
            f"[1000000000000000000,500000000000000000]",  # Costs Rates
        ],
    ),
    (
        Deployer.DEPLOY,
        "siliconFurnaces",
        [
            "$sanctis",
            "1600",  # Delay
            "[$silicon]",  # Reward resources
            "[1000000000000000000]",  # Reward base
            "[1000000000000000000]",  # Reward rate
            "[$iron,$energy]",  # Costs Resources
            "[1000000000000000000,10000000000000000]",  # Costs Base
            "[1000000000000000000,10000000000000000]",  # Costs Rates
        ],
    ),
    (
        Deployer.DEPLOY,
        "heavyWaterPlants",
        [
            "$sanctis",
            "3600",  # Delay
            "[$deuterium]",  # Reward resources
            "[1000000000000000000]",  # Reward base
            "[1000000000000000000]",  # Reward rate
            "[$iron,$silicon,$energy]",  # Costs Resources
            "[1000000000000000000,30000000000000000,30000000000000000]",  # Costs Base
            "[1000000000000000000,30000000000000000,10000000000000000]",  # Costs Rates
        ],
    ),
    (
        Deployer.DEPLOY,
        "solarPanels",
        [
            "$sanctis",
            "$energy",
            "1000000000000000000",  # Reward base
            "1000000000000000000",  # Reward rate
            "360",  # Delay
            "[$iron,$silicon]",  # Costs Resources
            "[0,0]",  # Costs Base
            "[1000000000000000000,10000000000000000]",  # Costs Rates
        ],
    ),
    (
        Deployer.DEPLOY,
        "fusionPlants",
        [
            "$sanctis",
            "$energy",
            "1000000000000000000",  # Reward base
            "1000000000000000000",  # Reward rate
            "3600",  # Delay
            "[$iron,$deuterium]",  # Costs Resources
            "[1000000000000000000,1000000000000000000]",  # Costs Base
            "[1000000000000000000,100000000000000000]",  # Costs Rates
        ],
    ),
    # Fleets
    (
        Deployer.DEPLOY,
        "spatioports",
        [
            "$sanctis",
            "3600",  # Delay
            "[$iron,$silicon]",  # Costs Resources
            "[1000000000000000000,1000000000000000000]",  # Costs base
            "[1000000000000000000,10000000000000000]",  # Costs Rates
            "9500",  # Base Discount
        ],
    ),
    (
        Deployer.DEPLOY,
        "transporters",
        [
            "$sanctis",
            "3600",  # Speed
            "5",  # Offensive power
            "100",  # Defensive power
            "1000000000000000000",  # Capacity
            "[$iron,$silicon]",  # Costs resources
            "[1000000000000000000,1000000000000000000]",  # Costs base
        ],
    ),
    (
        Deployer.DEPLOY,
        "scouts",
        [
            "$sanctis",
            "7000",  # Speed
            "0",  # Offensive power
            "1",  # Defensive power
            "0",  # Capacity
            "[$iron,$silicon]",  # Costs resources
            "[1000000000000000000,3000000000000000000]",  # Costs base
        ],
    ),
    (
        Deployer.DEPLOY,
        "destroyers",
        [
            "$sanctis",
            "3600",  # Speed
            "250",  # Offensive power
            "125",  # Defensive power
            "0",  # Capacity
            "[$iron,$silicon,$deuterium]",  # Costs resources
            "[1000000000000000000,1000000000000000000,1000000000000000000]",  # Costs base
        ],
    ),
    # Modules
    (
        Deployer.DEPLOY,
        "plundering",
        ["$sanctis", "84600", "1000"],
    ),
    # Utils
    (
        Deployer.DEPLOY,
        "resourceWrapper",
        ["$sanctis"],
    ),
    # Governance setup
    (
        Deployer.SEND,
        "sanctis",
        ["setParliamentExecutor", keypair["public"]],
    ),
    # Insert extensions
    (Deployer.SEND, "sanctis", ["insertAndAllowExtension", "$credits"]),
    (Deployer.SEND, "sanctis", ["insertAndAllowExtension", "$commanders"]),
    (Deployer.SEND, "sanctis", ["insertAndAllowExtension", "$planets"]),
    (Deployer.SEND, "sanctis", ["insertAndAllowExtension", "$fleets"]),
    # Allow
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$energy", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$iron", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$deuterium", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$silicon", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$ironMines", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$heavyWaterPlants", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$siliconFurnaces", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$spatioports", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$transporters", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$scouts", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$destroyers", "1"],
    ),
    (
        Deployer.SEND,
        "sanctis",
        ["setAllowed", "$resourceWrapper", "1"],
    ),
    # Mint initial supply
    (
        Deployer.SEND,
        "credits",
        ["mint", keypair["public"], "10000000000000000000000000"],
    ),
]

deployer.path(path)
