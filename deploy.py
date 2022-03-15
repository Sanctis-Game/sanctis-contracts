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
    ("SANCTIS", "src/Sanctis.sol:Sanctis"),
    ("CREDITS", "src/SpaceCredits.sol:SpaceCredits"),
    ("PARLIAMENT", "src/Parliament.sol:Parliament"),
    ("COMMANDERS", "src/Commanders.sol:Commanders"),
    ("STANDARDS", "src/GalacticStandards.sol:GalacticStandards"),
    ("PLANETS", "src/Planets.sol:Planets"),
    ("FLEETS", "src/Fleets.sol:Fleets"),
    ("RACEREG", "src/RaceRegistry.sol:RaceRegistry"),
    ("RESREG", "src/ResourceRegistry.sol:ResourceRegistry"),
    ("INFRAREG", "src/InfrastructureRegistry.sol:InfrastructureRegistry"),
    ("SHIPREG", "src/ShipRegistry.sol:ShipRegistry"),
    ("HUMANS", "src/races/Humans.sol:Humans"),
    ("IRON", "src/resources/Iron.sol:Iron"),
    ("IRONEXTRACTOR", "src/infrastructures/Extractors.sol:Extractors"),
]

deployer = Deployer(
    Network.FTM_TESTNET,
    signer,
    contracts,
    is_legacy=True,  # for legacy transactions
    debug=True,  # if True, prints the calling commands and raw output
    name="test1",
)

path = [
    # Format :
    # (ACTION_TYPE, CONTRACT_LABEL, [ARG, ... ])
    # Governance
    (Deployer.DEPLOY, "SANCTIS", []),
    (
        Deployer.DEPLOY,
        "CREDITS",
        [],
    ),
    (Deployer.DEPLOY, "PARLIAMENT", ["$CREDITS", "$CREDITS"]),
    (
        Deployer.SEND,
        "SANCTIS",
        ["setGovernance", "$PARLIAMENT", keypair["public"], "$CREDITS"],
    ),
    # World
    (Deployer.DEPLOY, "COMMANDERS", ["$SANCTIS"]),
    (Deployer.DEPLOY, "STANDARDS", ["$SANCTIS"]),
    (Deployer.DEPLOY, "PLANETS", ["$SANCTIS", "$CREDITS", "1000000000000000000000000"]),
    (Deployer.DEPLOY, "FLEETS", ["$SANCTIS"]),
    (
        Deployer.SEND,
        "SANCTIS",
        ["setWorld", "$PLANETS", "$COMMANDERS", "$FLEETS", "$STANDARDS", "100"],
    ),
    # Registries
    (Deployer.DEPLOY, "RACEREG", []),
    (Deployer.DEPLOY, "RESREG", []),
    (Deployer.DEPLOY, "INFRAREG", []),
    (Deployer.DEPLOY, "SHIPREG", []),
    (
        Deployer.SEND,
        "SANCTIS",
        ["setRegistries", "$RACEREG", "$RESREG", "$INFRAREG", "$SHIPREG"],
    ),
    # Set up
    (Deployer.DEPLOY, "HUMANS", ["$SANCTIS"]),
    (Deployer.DEPLOY, "IRON", ["$SANCTIS"]),
    (
        Deployer.DEPLOY,
        "IRONEXTRACTOR",
        [
            "$SANCTIS",
            "1",  # Resource ID
            "1000000000000000000",  # Reward base
            "1000000000000000000",  # Reward rate
            "100",  # Delay
            "[[1,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0]]",  # Costs
            "[[1,1000000],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0]]",  # Rates
        ],
    ),
    # Add Humans
    (
        Deployer.SEND,
        "SANCTIS",
        ["add", "0", "1"],
    ),
    # Add Iron
    (
        Deployer.SEND,
        "SANCTIS",
        ["add", "1", "1"],
    ),
    # Add Extractors
    (
        Deployer.SEND,
        "SANCTIS",
        ["add", "2", "1"],
    ),
]

deployer.path(path)
