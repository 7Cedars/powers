# Audit Scope

## Overview

This audit covers the core contracts of the Powers Protocol, a role-restricted governance protocol that provides a modular, flexible, decentralized, and efficient governance engine for on-chain organizations. The protocol is designed to be compatible with OpenZeppelin's Governor.sol, AccessManager, and the Hats protocol among others.

## In Scope

* **Scope:**

```
├── src
│   ├── Powers.sol (680 lines)
│   ├── Mandate.sol (245 lines)
│   ├── MandateUtilities.sol (320 lines)
│   └── interfaces
│       ├── IPowers.sol (236 lines)
│       ├── IMandate.sol (157 lines)
│       ├── PowersTypes.sol (94 lines)
│       ├── PowersEvents.sol (107 lines)
│       ├── PowersErrors.sol (85 lines)
│       └── MandateErrors.sol (53 lines)
```


* **Optional:**

```
├── src
│   └── mandates
│       ├── executive
│       │   ├── OpenAction.sol (71 lines)
│       │   └── StatementOfIntent.sol (70 lines)
│       ├── electoral
│       │   ├── DirectSelect.sol (105 lines)
│       │   └── DelegateSelect.sol (190 lines)
│       └── state
│           └── NominateMe.sol (129 lines)
```

* **Compatibility:**
  * Chains: Ethereum, Optimism, Base, Arbitrum, Mantle
  * Standards: ERC-165, EIP-712, OpenZeppelin Governor.sol compatibility

## Out of Scope

- All other contracts in subdirectories of `src/` (mandates/, integrations/)
- Any external dependencies or libraries
- Frontend code or deployment scripts
- Test files and mock contracts

## Invariants

### Core Protocol Invariants
- `MandateCount` should never decrease.
- Adopting a new mandate should increase mandateCount by 1. 
- An action can only be executed if it has reached the `Fulfilled` state

### Governance Invariants
- Any action that changes state outside of the powers protocol needs to be restricted with a `onlyPowers` modifier.  
- A proposal can only be executed if it has received sufficient votes to meet the quorum requirement
- An account can only vote once per proposal
- The sum of For, Against, and Abstain votes must equal the total number of votes cast

### Mandate System Invariants
- A mandate can only be executed if it is active
- The `mandateId` must be unique across all active mandates
- A mandate's conditions must be valid (e.g., `needFulfilled` mandate must exist if specified)
- A mandate cannot execute if its parent mandate (specified by `needFulfilled`) has not been fulfilled

### State Management Invariants
- The `actionId` must be unique for each combination of `mandateId`, `mandateCalldata`, and `nonce`
- State management in mandates is ring-fenced by the Powers instance that called the `initalizeMandate` function.   
- For each instance of `Executions`, `executions` and `actionIds` should be the same length
- The `roleId` must be unique for each role in the system
- An account's role assignment timestamp must be greater than 0 if the account has the role

### Access Control Invariants
- Only accounts with the appropriate role can execute functions restricted by that role
- The `onlyPowers` modifier can only be satisfied by calls from the Powers contract itself
- Only active mandates can call the `fulfill` function
- Role assignments and revocations must emit the appropriate events

### Data Integrity Invariants
- Array lengths must match between `targets`, `values`, and `calldatas` in execution calls

## Known Issues

- Documentation at some protocols is underdeveloped

## Technical Specifications

- **Solidity Version**: 0.8.26
- **License**: MIT
- **Architecture**: Modular governance with role-based access control
- **Compatibility**: OpenZeppelin Governor.sol, AccessManager, Hats Protocol
- **Key Features**: Non-weighted voting, role-restricted actions, modular mandate system

## Risk Assessment

### High Priority
- Governance manipulation through role management
- Proposal execution bypass mechanisms
- Vote counting and quorum validation
- Mandate execution authorization

### Medium Priority
- State consistency across contracts
- Gas optimization and DoS resistance
- Event emission accuracy
- Interface compliance

### Low Priority
- Code style and documentation
- Gas usage optimization
- Error message clarity
- Test coverage adequacy
