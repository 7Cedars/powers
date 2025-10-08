# Power Base Implementation Summary

## Executive Summary

Power Base is a decentralized organization for governing the development of the Powers protocol. This document provides a concise overview of the reformed governance specification.

## Core Architecture

### Three Independent Treasuries

```
┌─────────────────────────────────────────┐
│          Powers.sol (Owner)             │
│         Governance Layer                │
└─────────────┬───────────────────────────┘
              │
       ┌──────┴──────┐
       │             │
   ┌───▼───┐   ┌────▼────┐   ┌─────▼─────┐
   │ Docs  │   │Frontend │   │ Protocol  │
   │Grant  │   │ Grant   │   │  Grant    │
   │.sol   │   │  .sol   │   │   .sol    │
   └───────┘   └─────────┘   └───────────┘
```

### Why Three Separate Instances?

**Problem:** A single Grant contract would allow any area to exhaust the entire budget, contradicting the mission to "distribute funds *between* these three areas."

**Solution:** Three separate Grant.sol instances, each with independent budgets:
- **DocsGrant** - For documentation development
- **FrontendGrant** - For frontend development
- **ProtocolGrant** - For protocol development

**Benefits:**
- True budget separation between areas
- Each area self-governs with guaranteed funding
- One area cannot deplete another's budget
- Easy to audit per-area spending
- Flexible: can adjust one area without affecting others

## Governance Flows

### 1. Budget Allocation Flow

**Participants:** Members propose, Funders veto, Admin executes

**Process:**
1. Members propose three separate budgets:
   - Propose Docs Budget: "Token X, 10,000"
   - Propose Frontend Budget: "Token X, 15,000"
   - Propose Protocol Budget: "Token X, 20,000"
2. Each proposal goes through vote (51% success, 33% quorum, 7 days)
3. Optional: Funders can veto any proposal (66% success, 50% quorum, 3 days)
4. For each approved and not-vetoed proposal:
   - Admin executes law #6 → `DocsGrant.updateTokenBudget(tokenX, 10000)`
   - Admin executes law #7 → `FrontendGrant.updateTokenBudget(tokenX, 15000)`
   - Admin executes law #8 → `ProtocolGrant.updateTokenBudget(tokenX, 20000)`

**Result:** Three independent budgets set (can be set independently or together)

**Note:** While proposals are separate, all Members (contributors + funders) vote on all three, maintaining collective responsibility for budget distribution between areas.

### 2. Grant Lifecycle Flow (per area)

**Example: Documentation Grant**

**Participants:** Public submits, Members veto, Doc Contributors approve & manage

**Process:**
1. Anyone submits proposal → `DocsGrant.submitProposal(uri, milestones, amounts, tokens)`
2. Optional: Members can veto (66% success, 25% quorum, 3 days)
3. Doc Contributors vote to approve (51% success, 50% quorum, 7 days)
4. If approved: Doc Contributors execute → `DocsGrant.approveProposal(proposalId)`
5. When milestone block reached: Doc Contributors execute → `DocsGrant.releaseMilestone(proposalId, milestoneIndex)`
6. Repeat step 5 for each milestone

**Same flow applies to:**
- Frontend grants (using FrontendGrant instance)
- Protocol grants (using ProtocolGrant instance)

### 3. Role Assignment Flow

**Automatic role assignment based on contributions:**

1. **GitHub Contributor Roles:**
   - Link GitHub username to EVM address
   - Chainlink Functions checks commit history
   - Auto-assigns Doc/Frontend/Protocol Contributor role based on activity

2. **Funder Role:**
   - Transfer tokens to Powers.sol
   - Auto-assigns Funder role (time-limited based on amount)

3. **Member Role:**
   - Automatically assigned if you have Funder, Doc, Frontend, or Protocol role
   - Acts as aggregate role for governance participation

## Law Breakdown

### Total: 35 Laws

**Law #1: Initial Setup**
- Assigns role labels
- Self-destructs after execution

**Laws #2-11: Budget Management (10 laws)**
- #2: Propose Documentation Budget
- #3: Propose Frontend Budget
- #4: Propose Protocol Budget
- #5: Veto Budget Proposal (can veto any area)
- #6: Set Documentation Budget
- #7: Set Frontend Budget
- #8: Set Protocol Budget
- #9: Whitelist Token (Docs)
- #10: Whitelist Token (Frontend)
- #11: Whitelist Token (Protocol)

**Laws #12-26: Grant Management (15 laws = 5 × 3 areas)**

Per area (Docs, Frontend, Protocol):
- Submit grant proposal
- Veto grant proposal  
- Approve grant
- Release milestone
- Reject grant

**Laws #27-32: Electoral (6 laws)**
- #27: GitHub to EVM address mapping
- #28: GitHub commits to contributor roles
- #29: Fund development (get Funder role)
- #30: Auto-assign Member role
- #31: Remove role (voted)
- #32: Veto role removal

**Laws #33-35: Constitutional (3 laws)**
- #33: Propose law package
- #34: Veto law package
- #35: Adopt law package

## Technical Specifications

### Grant.sol Key Functions

```solidity
// Budget Management
updateNativeBudget(uint256 budget)
updateTokenBudget(address token, uint256 budget)
whitelistToken(address token)

// Grant Lifecycle
submitProposal(string uri, uint256[] milestoneBlocks, uint256[] amounts, address[] tokens) returns (uint256 proposalId)
approveProposal(uint256 proposalId)
rejectProposal(uint256 proposalId)
releaseMilestone(uint256 proposalId, uint256 milestoneIndex)

// View Functions
getProposal(uint256 proposalId) returns (Proposal)
canReleaseMilestone(uint256 proposalId, uint256 milestoneIndex) returns (bool)
getRemainingTokenBudget(address token) returns (uint256)
```

### BespokeActionSimple Configuration

Each law targeting Grant.sol is configured with:
```typescript
config: {
  targetContract: DocsGrant | FrontendGrant | ProtocolGrant,
  targetFunction: bytes4(keccak256("functionName(params)")),
  params: ["string[] paramNames"]
}
```

## Deployment Sequence

### 1. Deploy Contracts
```
DocsGrant = new Grant()
FrontendGrant = new Grant()
ProtocolGrant = new Grant()
Powers = new Powers(adminAddress)
```

### 2. Transfer Ownership
```
DocsGrant.transferOwnership(Powers.address)
FrontendGrant.transferOwnership(Powers.address)
ProtocolGrant.transferOwnership(Powers.address)
```

### 3. Constitute Powers
```
Powers.constitute([
  law1InitData,   // Initial setup
  law2InitData,   // Propose Docs Budget
  law3InitData,   // Propose Frontend Budget
  law4InitData,   // Propose Protocol Budget
  // ... all 35 laws
])
```

### 4. Initial Configuration
```
Execute law #1 (initial setup - assigns labels)
Execute laws #9-11 (whitelist initial tokens on all three Grant instances)
Execute laws #2-8 (propose and set initial budgets for all three areas)
```

## Security Model

### Access Control Layers

**Layer 1: Grant.sol (Owner-only)**
- All critical functions restricted to Powers.sol via Ownable
- Budget enforcement automatic
- Milestone timing enforced by block height

**Layer 2: Powers.sol (Role-based)**
- Laws restrict who can call which functions
- Conditions enforce voting requirements
- needFulfilled/needNotFulfilled enforce dependencies

**Layer 3: Voting (Democratic)**
- Contributor groups vote on their area's grants
- Members vote on budgets and vetoes
- Funders can veto major decisions

### Attack Surface Analysis

**Potential Risks:**
1. **Admin Key Compromise** - Admin can execute approved actions
   - Mitigation: Multi-sig admin, time delays on execution
   
2. **Grant.sol Budget Bypass** - Could malicious proposal exceed budget?
   - Mitigation: Grant.sol enforces limits automatically, operations revert if over budget
   
3. **Voting Manipulation** - Could attacker gain contributor roles?
   - Mitigation: GitHub verification via Chainlink, time-bounded roles
   
4. **Cross-Area Attacks** - Could one area affect another?
   - Mitigation: Complete separation via independent Grant instances

## Key Metrics

### Budget Transparency

Each Grant instance tracks:
- Total budget per token
- Total spent per token
- Remaining budget per token
- All queryable on-chain

### Grant Accountability

Each grant tracks:
- Proposer address (via tx.origin)
- Milestone block heights
- Milestone amounts and tokens
- Released vs pending milestones
- Approval/rejection status

## Future Enhancements

### Possible Additions

1. **Marketing/Community Area**
   - Deploy 4th Grant instance
   - Add corresponding laws
   - No changes to existing areas needed

2. **Budget Rebalancing**
   - Allow transferring unspent budget between areas
   - Requires new law + vote

3. **Grant Templates**
   - Predefined milestone structures
   - Reduces proposal complexity

4. **Delegation**
   - Contributors delegate voting power
   - Increases participation efficiency

5. **Reporting Requirements**
   - On-chain progress reports
   - Linked to milestone releases

## Conclusion

Power Base's reformed governance architecture provides:

✅ **Clear Budget Separation** - Three independent treasuries  
✅ **Proven Technology** - Uses existing Grant.sol (unmodified)  
✅ **Decentralized Governance** - Each area self-governs  
✅ **Security** - Multi-layer access control  
✅ **Transparency** - All operations on-chain  
✅ **Flexibility** - Easy to extend or modify  
✅ **Ready to Deploy** - All components exist and are documented  

The specification is complete and ready for implementation.

