<p align="center">

<br />
<div align="center">
  <a href="https://github.com/7Cedars/separated-powers"> 
    <img src="../public/logo.png" alt="Logo" width="300" height="300">
  </a>

<h2 align="center"> Powers protocol </h2>
  <p align="center">
    A role restricted governance protocol for DAOs. 
    <br />
    <br />
    <!--NB: TO DO --> 
    <a href="../README.md">Conceptual overview</a>
    ·
    <a href="#whats-included">What's included</a> ·
    <a href="#prerequisites">Prerequisites</a> ·
    <a href="#getting-started">Getting Started</a>
  </p>
  <br />
  <br />
</div>

## What's included
- A fully functional proof-of-concept of the Separated Powers governance protocol. 
- Base electoral laws, that enable different ways to assign roles to accounts. 
- Base executive laws, that enable different ways to role restrict and call external functions.
- Example constitutions and founders documents needed to initialise DAOs  (still a work in progress).
- Example implementations of DAOs building on the Separated Powers protocol (still a work in progress).
- Extensive unit, integration, fuzz and invariant tests (still a work in progress).

## How it works
The protocol closely mirrors {Governor.sol} and includes code derived from {AccessManager.sol}. Its code layout is inspired by the Hats protocol.

There are several key differences between {Powers.sol} and openZeppelin's {Governor.sol}.  
- Any DAO action needs to be encoded in role restricted external contracts, or laws, that follow the {ILaw.sol} interface.
- Proposing, voting, cancelling and executing actions are role restricted along the target law that is called.
- All DAO actions need to run through the governance protocol. Calls to laws that do not need a proposal vote to be executed, still need to be executed through {Powers::execute}.
- The core protocol uses a non-weighted voting mechanism: one account has one vote.
- The core protocol is minimalistic. Any complexity (timelock, delayed execution, guardian roles, weighted votes, staking, etc.) has to be integrated through laws.

Laws are role restricted contracts that provide the following functionalities:
- Role restricting DAO actions
- Transforming a lawCalldata input into an output of targets[], values[], calldatas[] to be executed by the Powers protocol.
- Adding conditions to the execution of the law. Any conditional logic can be added to a law, but the standard implementation supports the following:   
  - a vote quorum, threshold and period in case the law needs a proposal vote to pass before being executed.  
  - a parent law that needs to be completed before the law can be executed.
  - a parent law that needs to NOT be completed before the law can be executed.
  - a vote delay: an amount of time in blocks that needs to have passed since the proposal vote ended before the law can be executed. 
  - a minimum amount of blocks that need to have passed since the previous execution before the law can be executed again. 

The combination of checks and execution logics allows for creating almost any type of governance infrastructure with a minimum number of laws. For example implementations of DAOs, see the implementations/daos folder.



<!-- ### AgDao is deployed on the Arbitrum Sepolia testnet: 
Contracts have not been verified, but can be interacted with through [our bespoke user interface](https://separated-powers.vercel.app/).   

[AgDao](https://sepolia.arbiscan.io/address/0x001A6a16D2fc45248e00351314bCE898B7d8578f) - An example Dao implementation. This Dao aims to fund accounts that are aligned to its core values. <br>
[AgCoins](https://sepolia.arbiscan.io/address/0xC45B6b4013fd888d18F1d94A32bc4af882cDCF86) - A mock coin contract. <br>

#### Laws 
[Public_assignRole](https://sepolia.arbiscan.io/address/0x7Dcbd2DAc6166F77E8e7d4b397EB603f4680794C) - Allows anyone to claim a member role. <br> 
[Senior_assignRole](https://sepolia.arbiscan.io/address/0x420bf9045BFD5449eB12E068AEf31251BEb576b1) - Allows senior to vote in assigning senior role. <br> 
[Senior_revokeRole](https://sepolia.arbiscan.io/address/0x3216EB8D8fF087536835600a7e0B32687744Ef65)- Allows seniors to on revoking a senior role. <br> 
[Member_assignWhale](https://sepolia.arbiscan.io/address/0xbb45079e74399e7238AAF63C764C3CeE7D77712F) - Allows members to asses if account has sufficient tokens to get whale role. <br> 
[Whale_proposeLaw](https://sepolia.arbiscan.io/address/0x0Ea769CD03D6159088F14D3b23bF50702b5d4363) - Allows whales to propose a law. <br> 
[Senior_acceptProposedLaw](https://sepolia.arbiscan.io/address/0xa2c0C9d9762c51DA258d008C92575A158121c87d) - Allows seniors to accept a proposed law. <br> 
[Admin_setLaw](https://sepolia.arbiscan.io/address/0xfb7291B8FbA99C9FC29E95797914777562983D71) - Allows admin to implement a proposed law. <br> 
[Member_proposeCoreValue](https://sepolia.arbiscan.io/address/0x8383547475d9ade41cE23D9Aa4D81E85D1eAdeBD) - Allows member to propose a core value. <br> 
[Whale_acceptCoreValue](https://sepolia.arbiscan.io/address/0xBfa0747E3AC40c628352ff65a1254cC08f1957Aa) - Allows a whale to accept a proposed value as core requirement for funding accounts. <br> 
[Whale_revokeMember](https://sepolia.arbiscan.io/address/0x71504Ced3199f8a0B32EaBf4C274D1ddD87Ecc4d) - Allows  whale to revoke and blacklist a member for funding non-aligned accounts. <br> 
[Public_challengeRevoke](https://sepolia.arbiscan.io/address/0x0735199AeDba32A4E1BaF963A3C5C1D2930BdfFd)- Allows a revoked member to challenge the revoke decision. <br> 
[Senior_reinstateMember](https://sepolia.arbiscan.io/address/0x57C9a89c8550fAf69Ab86a9A4e5c96BcBC270af9) - Allows seniors to accept a challenge and reinstate a member. <br>  -->

## Directory Structure

```
solidity/
├── .github/                                   # GitHub configuration
├── broadcast/                                 # Deployment broadcast files
├── cache/                                     # Foundry cache
├── lib/                                       # Installed dependencies
│    ├── forge-std/                            # Forge standard library
│    └── openzeppelin-contracts/               # OpenZeppelin contracts
│
├── out/                                       # Compilation output
├── script/                                    # Deployment scripts
│    ├── DeployAlignedDao.s.sol                # Deploys the AgDao example implementation
│    └── ...                                   # Deployment contracts
│
├── src/                                       # Protocol resources
│    ├── integrations/                         # Integration implementations
│    │    └── ...                              # Integration contracts
│    │
│    ├── interfaces/                           # Protocol interfaces
│    │    ├── ILaw.sol                         # Law interface
│    │    ├── IPowers.sol                      # Powers interface
│    │    ├── LawErrors.sol                    # Law errors
│    │    ├── PowersErrors.sol                 # Powers errors
│    │    ├── PowersEvents.sol                 # Powers events
│    │    └── PowersTypes.sol                  # Powers data types
│    │
│    ├── laws/                                 # Law implementations
│    │    ├── bespoke/                         # Custom law implementations
│    │    │    ├── alignedDao/                 # Aligned DAO specific laws
│    │    │    ├── diversifiedRoles/           # Diversified roles laws
│    │    │    └── governYourTax/              # Tax-based governance laws
│    │    │        ├── RoleByTaxPaid.sol       # Role assignment based on tax
│    │    │        ├── StartGrant.sol          # Grant initiation
│    │    │        └── StopGrant.sol           # Grant termination
│    │    │
│    │    ├── electoral/                       # Electoral laws
│    │    │    ├── DelegateSelect.sol          # Role assignment via delegated votes
│    │    │    ├── DirectSelect.sol            # Single account role assignment
│    │    │    ├── ElectionCall.sol            # Election call handling
│    │    │    ├── ElectionTally.sol           # Election vote tallying
│    │    │    ├── PeerSelect.sol              # Peer-based selection
│    │    │    ├── RandomlySelect.sol          # Random role assignment
│    │    │    ├── RenounceRole.sol            # Role renunciation
│    │    │    └── SelfSelect.sol              # Self-selection for roles
│    │    │
│    │    ├── executive/                       # Executive laws
│    │    │    ├── BespokeAction.sol           # Preset contract/function calls
│    │    │    ├── OpenAction.sol              # Dynamic action execution
│    │    │    ├── PresetAction.sol            # Preset action execution
│    │    │    ├── StatementOfIntent.sol            # Proposal-only execution
│    │    │    └── SelfDestructAction.sol      # Self-destruct action
│    │    │
│    │    ├── state/                           # State management laws
│    │    │    ├── AddressesMapping.sol        # Address mapping management
│    │    │    ├── ElectionVotes.sol           # Election votes tracking
│    │    │    ├── NominateMe.sol              # Self-nomination
│    │    │    ├── StringsArray.sol            # String array management
│    │    │    └── TokensArray.sol             # Token array management
│    │    │
│    │    └── LawUtils.sol                     # Law utility functions
│    │
│    ├── Law.sol                               # Core Law contract
│    └── Powers.sol                            # Core protocol contract
│
├── test/                                      # Tests
│    ├── fuzz/                                 # Fuzz tests
│    │    └── SettingLaw_fuzz.t.sol            # Law setting fuzz tests
│    │
│    ├── mocks/                                # Mock contracts
│    │    ├── ConstitutionMock.sol             # Mock constitution
│    │    ├── DaoMock.sol                      # Mock DAO
│    │    ├── Erc20TaxedMock.sol               # Mock taxed ERC20
│    │    └── FoundersMock.sol                 # Mock founders
│    │
│    ├── unit/                                 # Unit tests
│    │    ├── Law.t.sol                        # Core Law contract tests
│    │    ├── Powers.t.sol                     # Core Powers contract tests
│    │    ├── DeployScripts.t.sol              # Deployment script tests
│    │    ├── Mocks.t.sol                      # Mock contract tests
│    │    │
│    │    └── laws/                            # Law unit tests
│    │        ├── Electoral.t.sol              # Electoral law tests
│    │        ├── Executive.t.sol              # Executive law tests
│    │        ├── State.t.sol                  # State law tests
│    │        │
│    │        └── bespoke/                     # Custom law tests
│    │            ├── AlignedDao.t.sol         # Aligned DAO law tests
│    │            ├── GovernYourTax.t.sol      # Tax governance tests
│    │            └── DiversifiedRoles.t.sol   # Diversified roles tests
│    │
│    └── TestSetup.t.sol                       # Test environment setup
│
├── .env                                       # Environment variables
├── .env.example                               # Environment variables template
├── .gitignore                                 # Git ignore rules
├── .gitmodules                                # Git submodules
├── foundry.toml                               # Foundry configuration
├── lcov.info                                  # Test coverage information
├── Makefile                                   # Build and test commands
├── README.md                                  # Project documentation
└── remappings.txt                             # Solidity import remappings

```

## Prerequisites

Foundry<br>

## Getting Started

1. Clone this repo locally and move to the solidity folder:

```sh
git clone https://github.com/7Cedars/separated-powers
cd separated-powers/solidity 
```

2. Copy `.env.example` to `.env` and update the variables.

```sh
cp env.example .env
```

3. run make. This will install all dependencies and run the tests. 

```sh
make
```

4. Run the tests without installing packages: 

```sh
forge test 
```

## Acknowledgements 
Code is derived from OpenZeppelin's Governor.sol and AccessManager contracts, in addition to Haberdasher Labs Hats protocol.




