# Power Base Governance Reform - Analysis & Summary

## Overview

This document summarizes the analysis and reform of the Power Base governance specification to integrate the `Grant.sol` contract into the Powers protocol governance framework.

## Analysis Phase

### 1. Grant.sol Contract Analysis

**Contract Purpose:**  
A standalone grant management system with comprehensive budget controls, milestone-based payouts, and token whitelisting.

**Key Features:**
- Budget tracking for native currency and multiple ERC20 tokens
- Proposal submission with milestone-based payment schedules
- Approval/rejection workflow for grant proposals
- Block-height-based milestone releases
- Token whitelisting for security
- All critical functions are owner-only (designed for Powers.sol ownership)

**Critical Functions:**
```solidity
updateNativeBudget(uint256)
updateTokenBudget(address, uint256)
whitelistToken(address) / dewhitelistToken(address)
submitProposal(string uri, uint256[] milestoneBlocks, uint256[] milestoneAmounts, address[] tokens)
approveProposal(uint256) / rejectProposal(uint256)
releaseMilestone(uint256 proposalId, uint256 milestoneIndex)
```

**Design Pattern:**
- Uses OpenZeppelin's `Ownable` pattern
- Owner should be the Powers.sol instance
- All operations must be called through governance laws
- Uses `tx.origin` in `submitProposal()` to track actual proposer through Powers.sol

### 2. Available Laws in Powers Protocol

**Executive Laws:**
- `StatementOfIntent.sol` - For creating proposals without immediate execution
- `BespokeActionSimple.sol` - For executing specific functions on target contracts
- `PresetSingleAction.sol` - For pre-configured actions
- `AdoptLaws.sol` - For adopting new laws

**Electoral Laws:**
- `BuyAccess.sol` - Role assignment via token payments
- `RoleByRoles.sol` - Role assignment based on other roles
- `RoleByGitCommit.sol` - Role assignment based on GitHub contributions
- `DirectDeselect.sol` - Role revocation via vote

**Key Insight:**  
`BespokeActionSimple.sol` is the perfect tool for creating governance interfaces to Grant.sol functions. Each law can target a specific Grant.sol function with proper access control.

### 3. Original Specification Issues

The original specification referenced laws that don't exist yet:
- `GrantProgram.sol` - Referenced but not implemented
- `EndGrant.sol` - Referenced but not implemented
- `Erc20Budget.sol` - Referenced but not implemented

The original flow also had some conceptual gaps:
- No clear budget enforcement mechanism
- Unclear how milestone payouts would work
- No token whitelisting consideration
- Grantee role assignment unclear

## Reformed Architecture

### Key Design Decisions

**1. Three Grant.sol Instances as Separate Treasuries:**
- Three separate Grant.sol instances: DocsGrant, FrontendGrant, ProtocolGrant
- All owned by Powers.sol
- Each enforces budget constraints independently
- True separation of funds between development areas
- Prevents one area from depleting funds intended for others

**2. BespokeActionSimple for Grant Operations:**
- Clean interface between governance and Grant contract
- Each law targets a specific Grant.sol function
- Proper access control through Powers protocol
- Configuration specifies target contract and function selector

**3. Separate Grant Laws per Category:**
- Documentation, Frontend, and Protocol each have their own grant laws
- Allows each contributor group to self-govern
- Prevents conflicts between development areas
- Maintains clear accountability

**4. Removed "Grantee" Role:**
- Grant.sol tracks grantees internally via proposals
- No need for separate role in Powers protocol
- Simplifies role management

### Reformed Governance Flows

#### Budget Process
1. **Members** propose budgets for each area separately via StatementOfIntent (vote 51%/33% for each):
   - Propose Documentation Budget (token + amount)
   - Propose Frontend Budget (token + amount)
   - Propose Protocol Budget (token + amount)
2. **Funders** can veto any budget proposal via StatementOfIntent (vote 66%/50%)
3. **Admin** executes budget updates via BespokeActionSimple (one law per area):
   - Calls `DocsGrant.updateTokenBudget()` if proposal approved & not vetoed
   - Calls `FrontendGrant.updateTokenBudget()` if proposal approved & not vetoed
   - Calls `ProtocolGrant.updateTokenBudget()` if proposal approved & not vetoed
4. **Admin** can whitelist tokens on each Grant instance via BespokeActionSimple

**Note:** While budgets are proposed separately, the Member role ensures collective responsibility - all contributors and funders participate in decisions about distribution between areas.

#### Grant Process (per category: Docs/Frontend/Protocol)
1. **Public** submits proposal via BespokeActionSimple → calls `DocsGrant/FrontendGrant/ProtocolGrant.submitProposal()`
2. **Members** can veto proposal via StatementOfIntent (vote 66%/25%)
3. **Contributors** approve grant via BespokeActionSimple (vote 51%/50%) → calls corresponding Grant instance's `approveProposal()`
4. **Contributors** release milestones via BespokeActionSimple → calls corresponding Grant instance's `releaseMilestone()`
5. **Contributors** can reject grant via BespokeActionSimple (vote 51%/50%) → calls corresponding Grant instance's `rejectProposal()`

### Benefits of Reformed Architecture

**1. Security:**
- Grant.sol enforces budget limits automatically
- Failed operations revert (can't overspend)
- Token whitelisting prevents unauthorized tokens
- Milestone timing enforced by block height

**2. Transparency:**
- All grant operations on-chain and auditable
- Clear proposal → approval → release flow
- Budget status queryable from Grant contract
- Milestone-based accountability

**3. Flexibility:**
- Each development area self-governs with its own Grant instance
- Admin can adjust budgets independently per area (with governance approval)
- Token whitelist adaptable per Grant instance
- Milestone structure customizable per grant
- Easy to add/remove development areas by deploying new Grant instances

**4. Efficiency:**
- No need for custom GrantProgram/EndGrant laws
- Reuses existing BespokeActionSimple law
- Proven Grant.sol contract (no modifications needed)
- Clear separation of concerns

## Implementation Roadmap

### Phase 1: Deployment
1. Deploy three Grant.sol contract instances:
   - DocsGrant = new Grant()
   - FrontendGrant = new Grant()
   - ProtocolGrant = new Grant()
2. Deploy Powers.sol with Admin role
3. Transfer ownership of all three Grant instances to Powers.sol
4. Deploy required law contracts (if not already deployed):
   - StatementOfIntent.sol
   - BespokeActionSimple.sol
   - AdoptLaws.sol
   - Electoral laws (RoleByGitCommit, BuyAccess, RoleByRoles, DirectDeselect, StringToAddress)

### Phase 2: Constitution
1. Prepare law initialization data for all ~30 laws
2. Call Powers.sol `constitute()` with law array
3. Verify all laws adopted correctly

### Phase 3: Initial Configuration
1. Execute whitelist laws for initial ERC20 tokens on all three Grant instances
2. Execute budget setting laws for each development area (Docs, Frontend, Protocol)
3. Verify all three Grant contract configurations

### Phase 4: Testing
1. Test budget proposal flow
2. Test grant proposal/approval flow for each category
3. Test milestone release flow
4. Test veto mechanisms
5. Test role assignment flows

### Phase 5: Launch
1. Deploy to testnet
2. Community testing period
3. Deploy to mainnet
4. Transfer admin role (if desired)

## Law Count Summary

**Budget Laws:** 10
- Propose Documentation Budget
- Propose Frontend Budget
- Propose Protocol Budget
- Veto Budget Proposal (can veto any area's proposal)
- Set Documentation Budget
- Set Frontend Budget
- Set Protocol Budget
- Whitelist Token (Docs)
- Whitelist Token (Frontend)
- Whitelist Token (Protocol)

**Grant Laws:** 15 (5 per category × 3 categories)
- Submit Proposal (Doc/Frontend/Protocol)
- Veto Proposal (Doc/Frontend/Protocol)
- Approve Grant (Doc/Frontend/Protocol)
- Release Milestone (Doc/Frontend/Protocol)
- Reject Grant (Doc/Frontend/Protocol)

**Electoral Laws:** 6
- Github to EVM
- Github to Role
- Fund Development
- Apply for Membership
- Remove Role
- Veto Role Revocation

**Constitutional Laws:** 3
- Propose Law Package
- Veto Law Package
- Adopt Law Package

**Total: 34 laws** (plus law #1 for initial setup = 35 total)

## Technical Considerations

### Gas Optimization
- Grant.sol operations are gas-intensive (storage writes)
- Consider milestone release gas costs when setting budgets
- Batch operations where possible

### Upgrade Path
- Grant.sol instances are not upgradeable
- New Grant instances would require constitutional law adoption
- Could deploy new instances and migrate budgets/proposals via governance
- Independent instances allow upgrading one area without affecting others

### Security Audits
- Grant.sol should be audited before mainnet deployment
- Integration between Powers.sol and Grant.sol should be tested extensively
- Particular attention to reentrancy and access control

### Frontend Integration
- Need UI for grant proposal submission (per development area)
- Dashboard for viewing proposals and milestones across all three Grant instances
- Budget tracking visualization showing independent budgets for Docs/Frontend/Protocol
- Milestone release interface for contributors
- Area-specific views for each contributor group

## Comparison: Original vs Reformed

| Aspect | Original | Reformed |
|--------|----------|----------|
| Grant Management | Unclear, referenced non-existent laws | Three separate Grant.sol instances |
| Budget Enforcement | Vague | Automatic per Grant instance |
| Area Budget Separation | Not enforced | Three independent budgets |
| Milestone Payouts | Unclear mechanism | Block-height based in Grant.sol |
| Token Support | Assumed ERC20 | Explicit whitelist per Grant instance |
| Grantee Tracking | Separate role | Tracked in Grant.sol proposals |
| Law Count | ~20 (many not implemented) | 35 (all using existing law types) |
| Security Model | Unclear | Owner-only pattern + governance |
| Deployment Complexity | Unknown | Clear, documented steps |

## Conclusion

The reformed architecture provides a complete, secure, and implementable grant management system for Power Base. By deploying three separate `Grant.sol` instances and using the Powers protocol's `BespokeActionSimple` law, we've created a governance structure that:

1. **Fulfills the Original Mission:** Distributes funds for protocol, frontend, and documentation development
2. **Enforces Area Separation:** Three independent budgets prevent one area from depleting funds intended for others
3. **Adds Security:** Budget enforcement per area, milestone-based payouts, token whitelisting
4. **Maintains Decentralization:** Each contributor group governs their own grants with their own treasury
5. **Uses Existing Tools:** No need to develop new law contracts or modify Grant.sol
6. **Is Fully Implementable:** All components exist and are ready to deploy

The specification is now ready for implementation and testing.

