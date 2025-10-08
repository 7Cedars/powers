# Calldata Matching Solution for Budget Management

## Problem Statement

### The Technical Issue

In the Powers protocol, laws can be linked using the `needFulfilled` condition. This creates dependencies where one law can only execute if another law has been fulfilled with **the same calldata**.

**How it works:**
```solidity
actionId = hash(lawId, lawCalldata, nonce)
needFulfilled checks if actionId exists and is fulfilled
```

**The problem we encountered:**
- **Proposal Law:** Input was `(address token, uint256 docsBudget, uint256 frontendBudget, uint256 protocolBudget)`
- **Execution Laws:** Input was `(address token, uint256 budget)` for each area
- **Result:** Different calldata formats = different hashes = laws cannot be linked ❌

### Why This Matters

The original design had:
1. Members propose budgets for all three areas in one vote
2. Admin executes three separate budget updates

But step 2 can't reference step 1 because the calldata doesn't match!

## Solution: Three Separate Proposals

### Architecture

Instead of one unified proposal with three budgets, we split into three separate proposals, each with matching execution law calldata.

**Before (Broken):**
```
Law #2: Propose Budget
  Input: (address token, uint256 docs, uint256 frontend, uint256 protocol)
  
Law #3: Veto Budget  
  Input: (address token, uint256 docs, uint256 frontend, uint256 protocol)
  
Law #4: Set Docs Budget
  Input: (address token, uint256 budget)  ❌ CALLDATA MISMATCH
  needFulfilled: Law #2  ❌ WON'T WORK
```

**After (Working):**
```
Law #2: Propose Docs Budget
  Input: (address token, uint256 budget)
  
Law #3: Propose Frontend Budget
  Input: (address token, uint256 budget)
  
Law #4: Propose Protocol Budget
  Input: (address token, uint256 budget)
  
Law #5: Veto Budget Proposal
  Input: (address token, uint256 budget)
  needFulfilled: Law #2 OR #3 OR #4  ✅ CALLDATA MATCHES
  
Law #6: Set Docs Budget
  Input: (address token, uint256 budget)
  needFulfilled: Law #2  ✅ PERFECT MATCH
  needNotFulfilled: Law #5  ✅ WORKS
  
Law #7: Set Frontend Budget
  Input: (address token, uint256 budget)
  needFulfilled: Law #3  ✅ PERFECT MATCH
  needNotFulfilled: Law #5  ✅ WORKS
  
Law #8: Set Protocol Budget
  Input: (address token, uint256 budget)
  needFulfilled: Law #4  ✅ PERFECT MATCH
  needNotFulfilled: Law #5  ✅ WORKS
```

### Key Design Decision: Member Role for All Proposals

**Concern:** If proposals are separate, how do we maintain "collective decision on distribution between areas"?

**Solution:** All three proposals use the **Member role** (role #5)

**Member role composition:**
```
Member = Funder OR Doc Contributor OR Frontend Contributor OR Protocol Contributor
```

**What this means:**
- ALL contributors vote on ALL budget proposals
- ALL funders vote on ALL budget proposals
- Documentation contributors vote on frontend and protocol budgets
- Frontend contributors vote on docs and protocol budgets
- Protocol contributors vote on docs and frontend budgets
- Funders vote on all development budgets

**Result:** True collective decision-making is maintained!

## Flow Example

### Scenario: Setting Q1 Budgets

**Step 1: Off-chain Coordination**
Community discusses in Discord:
- "We need 10K USDC for docs, 15K for frontend, 20K for protocol"
- Consensus reached on distribution

**Step 2: On-chain Proposals (by any Member)**
```
Member submits Law #2: Propose Docs Budget (USDC, 10000)
Member submits Law #3: Propose Frontend Budget (USDC, 15000)
Member submits Law #4: Propose Protocol Budget (USDC, 20000)
```

**Step 3: Voting (7 days, 51% success, 33% quorum)**
All Members vote on all three proposals:
- Doc contributor votes YES on all three
- Frontend contributor votes YES on all three
- Protocol contributor votes YES on all three
- Funder votes YES on all three

**Step 4: Optional Veto Period (3 days, 66% success, 50% quorum)**
Funders can veto any proposal if they disagree:
```
Funder submits Law #5: Veto Budget (USDC, 15000)
  This vetoes the frontend budget specifically
```

**Step 5: Execution (if approved & not vetoed)**
```
Admin executes Law #6: Set Docs Budget (USDC, 10000)
  ✅ Checks: Law #2 fulfilled? YES
  ✅ Checks: Law #5 with same calldata fulfilled? NO
  ✅ Result: DocsGrant.updateTokenBudget(USDC, 10000)

Admin tries Law #7: Set Frontend Budget (USDC, 15000)
  ✅ Checks: Law #3 fulfilled? YES
  ❌ Checks: Law #5 with same calldata fulfilled? YES (was vetoed!)
  ❌ Result: BLOCKED

Admin executes Law #8: Set Protocol Budget (USDC, 20000)
  ✅ Checks: Law #4 fulfilled? YES
  ✅ Checks: Law #5 with same calldata fulfilled? NO
  ✅ Result: ProtocolGrant.updateTokenBudget(USDC, 20000)
```

**Final Result:**
- Docs: 10K USDC ✅
- Frontend: 0 (vetoed) ❌
- Protocol: 20K USDC ✅

## Advantages of This Solution

### 1. **Perfect Calldata Matching**
- Proposals and executions have identical input formats
- `needFulfilled` and `needNotFulfilled` work as designed
- No hacks or workarounds needed

### 2. **Maintains Collective Decision-Making**
- All Members vote on all budgets
- Contributors across all areas participate in budget distribution
- Funders have oversight on all spending

### 3. **Granular Control**
- Can approve docs budget but reject frontend budget
- Each area's funding can be decided independently
- Allows for nuanced governance decisions

### 4. **Uses Existing Laws**
- No custom law development needed
- All components already exist and are tested
- Faster deployment, lower risk

### 5. **Flexible**
- Can propose budgets together or separately
- Can adjust one area without reproposing all three
- Easy to modify budgets mid-period if needed

## Disadvantages & Mitigations

### Disadvantage 1: Not Atomic
**Issue:** The three budgets aren't set simultaneously - could have partial execution.

**Mitigation:**
- Social convention: propose all three together
- Off-chain coordination before proposals
- If one is vetoed, community can discuss and re-propose

### Disadvantage 2: More Proposals = More Votes
**Issue:** Members need to vote on three proposals instead of one.

**Mitigation:**
- Frontend can provide "batch voting" UI
- All three proposals can be voted on in one transaction
- Small price for maintaining flexibility

### Disadvantage 3: Governance Overhead
**Issue:** Three proposal transactions instead of one.

**Mitigation:**
- Gas costs are minimal for StatementOfIntent
- Only needs to happen periodically (quarterly/annually)
- Benefits of granular control outweigh overhead

## Alternative Solutions Considered

### Option A: Custom BudgetAllocator Law
**What:** Write a new law that takes (token, docs, frontend, protocol) as input and calls all three Grant instances.

**Pros:** Atomic execution, single proposal
**Cons:** Requires development, testing, audit of new contract

**Decision:** Rejected because we can achieve the goal with existing laws.

### Option B: BespokeActionAdvanced
**What:** Use a multi-call law with arrays of targets and calldatas.

**Pros:** Uses existing law (if available), atomic execution
**Cons:** Complex user input (arrays of encoded bytes), harder for users

**Decision:** Rejected because user experience is poor for governance participants.

### Option C: PresetSingleAction
**What:** Preset the three calls at law adoption time.

**Pros:** Simple execution
**Cons:** Still has calldata mismatch problem, inflexible (can't change amounts without adopting new law)

**Decision:** Rejected because it doesn't solve the core problem.

## Implementation Checklist

- [x] Update specification to show three separate proposal laws
- [x] Ensure all use Member role (maintains collective decision-making)
- [x] Update governance flow diagrams to show three proposals
- [x] Document off-chain coordination expectation
- [x] Update law count (33 → 35 laws total)
- [x] Update analysis documents
- [ ] Create frontend UI for batch proposal submission
- [ ] Create frontend UI for batch voting
- [ ] Add budget coordination guidelines to governance documentation
- [ ] Test calldata matching in actual deployment

## Conclusion

The three-separate-proposals solution successfully solves the calldata matching problem while maintaining the core governance principle of collective decision-making through the Member role. It uses only existing law types, is easy to understand and audit, and provides the flexibility needed for nuanced governance decisions.

The slight increase in proposal overhead is outweighed by:
1. Technical correctness (calldata matching works)
2. Governance flexibility (can decide on each area independently)
3. Development speed (no custom laws needed)
4. Security (uses proven, existing contracts)

This solution is ready for implementation.

