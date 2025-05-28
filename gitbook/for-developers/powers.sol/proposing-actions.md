# Proposing and voting on actions

The Powers protocol provides a governance mechanism for actions that require community consensus. This is implemented through a proposal and voting system, similar to other governance protocols but with key differences in role-based access control and law-specific validation.

## When to Use Proposals

Proposals should be used when:
- An action requires community consensus
- The law's conditions specify a quorum > 0
- The action needs to be transparent and auditable
- Multiple stakeholders need to vote on the action

## Proposal Flow

### 1. Creating a Proposal

A user creates a proposal by calling the `propose` function in Powers.sol with:
- `lawId`: The ID of the law that will be called
- `lawCalldata`: The encoded function call data
- `nonce`: A random nonce to ensure uniqueness
- `uriAction`: A description or URI to proposal details

The function:
- Verifies the law is active
- Checks if the caller has the appropriate role
- Validates that the law requires voting (quorum > 0)
- Creates a unique `actionId` by hashing `lawId`, `lawCalldata`, and `nonce`
- Stores the proposal details in the `_actions` mapping
- Sets the voting period based on the law's conditions
- Emits a `ProposedActionCreated` event

### 2. Voting Period

Once created, the proposal enters a voting period where:
- The voting period is determined by the law's `votingPeriod` condition
- Voting starts at the block where the proposal was created
- Voting ends at `voteStart + voteDuration`
- During this period, eligible voters can cast their votes

### 3. Casting Votes

Voters can cast votes in two ways:
1. `castVote(actionId, support)`: Simple vote
2. `castVoteWithReason(actionId, support, reason)`: Vote with explanation

Where `support` can be:
- `0`: Against
- `1`: For
- `2`: Abstain

The voting process:
- Verifies the proposal is active
- Checks if the voter has the appropriate role
- Ensures the voter hasn't voted before
- Records the vote in the proposal's state
- Emits a `VoteCast` event

### 4. Proposal Resolution

A proposal can end in several states:

#### Success
- Voting period has ended
- Quorum has been reached (`_quorumReached` returns true)
- Required threshold of "For" votes has been met (`_voteSucceeded` returns true)
- State changes to `Succeeded`

#### Defeat
- Voting period has ended
- Either quorum wasn't reached or required threshold wasn't met
- State changes to `Defeated`

#### Cancellation
- Original proposer can cancel the proposal using `cancel`
- State changes to `Cancelled`

## Important Considerations

### 1. Role-Based Access
- Only accounts with the appropriate role can propose
- Only accounts with the appropriate role can vote
- Role checks happen at both proposal creation and voting

### 2. Quorum and Thresholds
- Quorum is defined in the law's conditions
- Success threshold is defined in the law's conditions
- Both are expressed as percentages of total role holders

### 3. Gas Optimization
- Votes are stored as uint32 (not uint256) since they're not weighted
- Proposal data is stored on-chain for transparency
- Failed proposals still consume gas up to the point of failure

### 4. Common Pitfalls
- Proposals cannot be modified after creation
- Votes cannot be changed once cast
- Proposals cannot be re-submitted if cancelled
- The same action with the same nonce cannot be proposed twice
- Voting period is fixed and cannot be extended

### 5. Security Considerations
- Role assignments should be carefully managed
- Law conditions should be well-thought-out
- Quorum and threshold values should be appropriate for the community size
- Proposal descriptions should be clear and detailed
