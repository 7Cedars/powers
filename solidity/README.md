<p align="center">

<br />
<div align="center">
  <a href="https://github.com/7Cedars/powers"> 
    <img src="../powers_icon_notext.svg" alt="Logo" width="300" height="300">
  </a>

<h2 align="center"> Powers protocol </h2>
  <p align="center">
    Institutional governance for on-chain organisations. 
    <br />
    <br />
    <a href="#whats-included">What's included</a> ·
    <a href="#how-it-works">How it works</a> ·
    <a href="#prerequisites">Prerequisites</a> ·
    <a href="#getting-started">Getting Started</a>
  </p>
  <br />
  <br />
</div>

## What's included
- A fully functional proof-of-concept of the Powers governance protocol (v0.4). It allows for the creation of modular and flexible rule based governance in on-chain organisations.  
- Electoral laws that enable different ways to assign roles to accounts. 
- Executive laws that enable different ways to role restrict and call external functions.
- Multi-action laws that provide flexible execution patterns for complex governance operations.
- Example constitutions and founders documents needed to initialize DAOs.
- Example implementations of DAOs building on the Powers protocol.
- Comprehensive unit, integration, fuzz and invariant tests.

## How it works
In Powers actions need to be executed through role restricted contracts, called laws. These laws give role holders the power to transform pre-defined input into executable calldata. Aside from being role restricted, execution can also be conditional on the execution of another law. This allows for the creation of checks and balances between roles, and the creation of any type of rule based governance structure.       

As such, there are several key differences between {Powers.sol} and the often used {Governor.sol}:  
- Any action needs to be encoded in role-restricted external contracts, or laws, that follow the {ILaw.sol} interface.
- Proposing, voting, cancelling and executing actions are role-restricted along the target law that is called.
- All actions need to run through the governance protocol. Calls to laws that do not need a proposal vote to be executed still need to be executed through {Powers::execute}.
- The core protocol uses a non-weighted voting mechanism: one account has one vote.
- The core protocol is minimalistic. Any complexity (timelock, delayed execution, guardian roles, weighted votes, staking, etc.) has to be integrated through laws.

Laws are role-restricted contracts that provide the following functionalities:
- Transforming a lawCalldata input into an output of targets[], values[], calldatas[] to be executed by the Powers protocol
- Adding conditions to the execution of the law. Any conditional logic can be added to a law, but the standard implementation supports the following:   
  - A vote quorum, threshold and period in case the law needs a proposal vote to pass before being executed  
  - A parent law that needs to be completed before the law can be executed
  - A parent law that needs to NOT be completed before the law can be executed
  - A vote delay: an amount of time in blocks that needs to have passed since the proposal vote ended before the law can be executed 
  - A minimum amount of blocks that need to have passed since the previous execution before the law can be executed again 

The combination of checks and execution logics allows for creating almost any type of governance infrastructure with a minimum number of laws. For example implementations, see the `/test/TestConstitutions.sol` file.

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
│    ├── DeployLaws.s.sol                      # Deploys law contracts
│    ├── DeployMocks.s.sol                     # Deploys mock contracts
│    └── HelperConfig.s.sol                    # Helper configuration
│
├── src/                                       # Protocol resources
│    ├── interfaces/                           # Protocol interfaces
│    │    ├── ILaw.sol                         # Law interface
│    │    ├── IPowers.sol                      # Powers interface
│    │    ├── LawErrors.sol                    # Law errors
│    │    ├── PowersErrors.sol                 # Powers errors
│    │    ├── PowersEvents.sol                 # Powers events
│    │    └── PowersTypes.sol                  # Powers data types
│    │
│    ├── laws/                                 # Law implementations
│    │    ├── electoral/                       # Electoral laws
│    │    │    ├── BuyAccess.sol               # Role assignment based on donations
│    │    │    ├── ElectionSelect.sol          # Role assignment via elections
│    │    │    ├── NStrikesRevokesRoles.sol    # Role revocation after strikes
│    │    │    ├── PeerSelect.sol              # Peer-based role selection
│    │    │    ├── RenounceRole.sol            # Role renunciation
│    │    │    ├── RoleByRoles.sol             # Role assignment based on other roles
│    │    │    ├── SelfSelect.sol              # Self-selection for roles
│    │    │    ├── TaxSelect.sol               # Role assignment based on tax payments
│    │    │    └── VoteInOpenElection.sol      # Voting in external elections
│    │    │
│    │    ├── executive/                       # Executive laws
│    │    │    ├── AdoptLaws.sol               # Adopt multiple laws at once
│    │    │    ├── GovernorCreateProposal.sol  # Create governance proposals
│    │    │    └── GovernorExecuteProposal.sol # Execute governance proposals
│    │    │
│    │    ├── multi/                           # Multi-action laws
│    │    │    ├── BespokeActionAdvanced.sol   # Advanced custom actions
│    │    │    ├── BespokeActionSimple.sol     # Simple custom actions
│    │    │    ├── OpenAction.sol              # Open action execution
│    │    │    ├── PresetMultipleActions.sol   # Multiple preset actions
│    │    │    ├── PresetSingleAction.sol      # Single preset action
│    │    │    └── StatementOfIntent.sol       # Statement of intent
│    │    │
│    │    ├── Law.sol                          # Core Law contract
│    │    ├── LawUtilities.sol                 # Law utility functions
│    │    ├── Powers.sol                       # Core protocol contract
│    │    └── PowersUtilities.sol              # Powers utility functions
│
├── test/                                      # Tests
│    ├── fuzz/                                 # Fuzz tests
│    │    ├── LawFuzz.t.sol                    # Law fuzz tests
│    │    ├── PowersFuzz.t.sol                 # Powers fuzz tests
│    │    └── laws/                            # Law-specific fuzz tests
│    │        ├── ElectoralFuzz.t.sol          # Electoral law fuzz tests
│    │        ├── ExecutiveFuzz.t.sol          # Executive law fuzz tests
│    │        └── MultiFuzz.t.sol              # Multi-action law fuzz tests
│    │
│    ├── integration/                          # Integration tests
│    │    ├── Powers101.t.sol                  # Powers 101 integration tests
│    │    ├── ManagedGrants_TBI.t.sol          # Managed grants tests (TBI)
│    │    ├── OpenElections_TBI.t.sol          # Open elections tests (TBI)
│    │    └── SplitGovernance_TBI.t.sol        # Split governance tests (TBI)
│    │
│    ├── mocks/                                # Mock contracts for testing
│    │    ├── Donations.sol                    # Mock donations contract
│    │    ├── Erc20DelegateElection.sol        # Mock ERC20 delegate election
│    │    ├── Erc20Taxed.sol                   # Mock taxed ERC20
│    │    ├── FlagActions.sol                  # Mock flag actions contract
│    │    ├── Nominees.sol                     # Mock nominees contract
│    │    ├── OpenElection.sol                 # Mock open election contract
│    │    ├── SimpleGovernor.sol               # Mock simple governor
│    │    └── ...                              # Additional mock contracts
│    │
│    ├── unit/                                 # Unit tests
│    │    ├── Law.t.sol                        # Core Law contract tests
│    │    ├── LawUtilities.t.sol               # Law utilities tests
│    │    ├── Powers.t.sol                     # Core Powers contract tests
│    │    ├── PowersUtilities.t.sol            # Powers utilities tests
│    │    ├── Mocks.t.sol                      # Mock contract tests
│    │    └── laws/                            # Law-specific unit tests
│    │        ├── Electoral.t.sol              # Electoral law tests
│    │        ├── Executive.t.sol              # Executive law tests
│    │        └── Multi.t.sol                  # Multi-action law tests
│    │
│    ├── TestConstitutions.sol                 # Constitution tests
│    └── TestSetup.t.sol                       # Test environment setup
│
├── .env.example                               # Environment variables template
├── .gitignore                                 # Git ignore rules
├── .gitmodules                                # Git submodules
├── foundry.toml                               # Foundry configuration
├── lcov.info                                  # Test coverage information
├── Makefile                                   # Build and test commands
└── README.md                                  # Project documentation 

```

## Prerequisites

Foundry<br>

## Getting Started

1. Clone this repo locally and move to the solidity folder:

```sh
git clone https://github.com/7Cedars/powers
cd powers/solidity 
```

2. Copy `.env.example` to `.env` and update the variables.

```sh
cp .env.example .env
```

3. Run make. This will install all dependencies and run the tests. 

```sh
make
```

4. Run the tests without installing packages: 

```sh
forge test 
```

## Acknowledgements 
Code is derived from OpenZeppelin's Governor.sol and AccessManager contracts, in addition to Haberdasher Labs Hats protocol. The Powers protocol (v0.4) represents a significant evolution in role-based governance systems for on-chain organ.




