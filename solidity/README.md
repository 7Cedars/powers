<p align="center">

<br />
<div align="center">
  <a href="https://github.com/7Cedars/separated-powers"> 
    <img src="../public/logo.png" alt="Logo" width="300" height="300">
  </a>

<h2 align="center">Separated Powers </h2>
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
.
├── lib                                         # Installed dependencies. 
│    ├── forge-std                              # Forge  
│    └── openZeppelin-contracts                 # openZeppelin contracts  
|
├── script                                      # Deployment scripts  
│    └── DeployAlignedDao.s.sol              # Deploys the AgDao example implementation of Powers. Also deploys laws that make up AgDao's governance. 
|
├── src                                         # Protocol resources
│    ├── implementations                        # AgDao example resources.
│    │    ├── daos                              # 
│    │    │    ├── aligned-grants               # An example dao that revolves around setting and enforcing community values.  
│    │    │    │    ├── aligned-grants.sol      # The core DAO contract.  
│    │    │    │    ├── Constitution.sol        # The initial laws of the DAO.  
│    │    │    │    └── Founders.sol            # The initial founders and their role assignments. 
│    │    │    ├── arb-aips                     # An example DAO that is inspired by the constitution of Arbitrum DAO. 
│    │    │    │    ├── aligned-grants.sol      # The core DAO contract.  
│    │    │    │    ├── Constitution.sol        # The initial laws of the DAO.  
│    │    │    │    └── Founders.sol            # The initial founders and their role assignments. 
│    │    │    ├── core-dao                     # A minimalistic DAO that provides all core functionality for an initial DAO and that allows for future growth. 
│    │    │    │    └── ...                     # 
│    │    │    ├── opt-two-houses               # An example DAO inspired by the two houses governance process of the Optimism Collective.   
│    │    │    │    └── ...                     #  
│    │    │    ├── nouns-dao                    # An example DAO inspired by the NounsDAO governance structure.
│    │    │    │    └── ...                     # 
│    │    │    └── ...   
│    │    │     
│    │    └── laws                              # 
│    │         ├── electoral                    # See description of laws above. 
│    │         │    ├── DelegateSelect.sol      # Assign nominated accounts to a roleId through delegated votes. Uses OpenZeppelin's ERC20Votes.sol 
│    │         │    ├── DirectSelect.sol        # Assigns a single account to a roleId.  
│    │         │    ├── RandomlySelect.sol      # Assigns nominated accounts randomly to a roleId.  
│    │         │    └── TokensSelect.sol        # Assigns nominated accounts to a roleId on the amount of tokens held. 
│    │         └── executive   
│    │              ├── BespokeAction.sol       # Preset the contract and function that can be called, takes the (abi.encoded) input of the target function as its own input.  
│    │              ├── OpenAction.sol          # Takes targets[], values[] and calldatas[] as input, and gives them as output. 
│    │              ├── PresetAction.sol        # Gives a present targets[], values[] and calldatas[] as output, following a bool 'true' input. 
│    │              └── ProposalOnly.sol        # Outputs an empty array, following any input. 
│    │   
│    ├── interfaces                             # Interfaces of the protocol. 
│    │    ├── ILaw.sol                          # Interface for Law.sol.  Includes detailed description of functions. 
│    │    ├── IPowers.sol              # Interface for Powers.sol. Includes detailed description of functions. 
│    │    ├── LawErrors.sol                     # Law.sol errors. 
│    │    ├── PowersErrors.sol         # Powerserrors.   
│    │    ├── PowersEvents.sol         # Powersevents.   
│    │    └── PowersTypes.sol          # Powers data Types. 
│    │     
│    ├── Law.sol                                # The core Law (abstract) contract. It needs to be inherited by law implementations to function. 
│    └── Powers.sol                    # The core protocol. It needs to be inherited by DAO implementations. 
|
├── test                                        # Tests 
│    ├── fuzz                                   # Fuzz tests on example implementation (wip) 
│    │    └── SettingLaw_fuzz.t.t.sol           # 
│    ├── integration-dao                        # Integration tests. 
│    │    ├── AlignedGrants.t.sol               # Integration tests using the AlignedGrants DAO example. 
|    │    ├── ArbAips.t.sol                     # Integration tests using the Arbitrum AIPs example. 
│    │    └── ...                               # 
│    ├── mocks                                  # Mocks. 
│    │    ├── ConstitutionMock.sol              # A mock constitution to initiate laws in a new DAO. 
|    │    ├── DaoMock.sol                       # A mock DAO to be used in testing. 
|    │    ├── FoundersMock.sol                  # A mock founders document to be used in initiating a DAO.
│    │    └── ...                               # 
│    ├── unit                                   # Unit tests.  
│    │    ├── AlignedGrants.t.sol               # Integration tests using the AlignedGrants DAO example. 
|    │    ├── ArbAips.t.sol                     # Integration tests using the Arbitrum AIPs example. 
│    │    └── ...                               # 
│    └── TestSetup.t.sol                        # Dynamic setup of the various tests environments. 
│ 
├── .env.example                   
├── foundry.toml                   
├── LICENSE                                     # MIT license 
├── README.md                                   # This file
├── Makefile.md                                 # Commands to deploy contracts on mainnet sepolia and optimism sepolia.  
├── remappings.txt
└── ...

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




