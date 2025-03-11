// <!--
//   This layout is inspired by the Arbitrum DAO and its constitution as of nov 2024.
//   See the intro to their governance structure here: https://docs.arbitrum.foundation/dao-constitution
// -->

// <!--
//   Roles (max number of role holders)
//   Note, this is in addition to ADMIN_ROLE and PUBLIC_ROLE)
//  -->
// - TOKEN_HOLDER (no max)
// - TOKEN_REPRESENTATIVE (150)
// - SECURITY_COUNCIL_MEMBER (12)
// - CHAIN_OWNER (one per chain. Note, these can be multisig accounts)

// <!-- Electoral laws -->
// - nominate and revoke nomination for TOKEN_REPRESENTATIVE role
//   - Anyone (PUBLIC_ROLE) can nominate themselves.
//   - Only account themselves can revoke nomination.

// - assign & revoke TOKEN_REPRESENTATIVE
//   - by (delegate) token vote.
//   - Max amount of representatives.
//   - Anyone can call election.
//   - Max holders (+ delegated tokens) get selected.
//   - It means at all times there can be no more that max amount of representatives.

// - pause TOKEN_REPRESENTATIVE elections.
//   - law above can be temporarily disabled during duration of AIP votes. See below.

// - assign SECURITY_COUNCIL_MEMBER roles
//   - by vote among TOKEN_REPRESENTATIVE
//   - every x period.
//   - See Section 4 of constitution. Timed process.
//   - OR when a SECURITY_COUNCIL_MEMBER resigned.

// - resign SECURITY_COUNCIL_MEMBER role.
//   - Only by citizen role holder themselves.
//   - No vote needed. Direct call.

// - (re)assign CHAIN_OWNER
//   <!-- develop later -->
//   - full governance cycle. see below

// - assign TOKEN_HOLDER role.
//   - anyone (PUBLIC_ROLE) can call this law
//   - if the account owns more than x tokens, it will be assigned TOKEN_HOLDER role.

// - revoke TOKEN_HOLDER role
//   - anyone (PUBLIC_ROLE) can call this law
//   - takes any account address.
//   - checks the account address if it has fewer that X tokens + if it holds TOKEN_HOLDER role.
//   - If both are true, revokes role.

// <!-- Emergence Pause & restart laws -->
// - SECURITY_COUNCIL_MEMBER role holders -> can pause law
//   - multiple laws can be stopped at once.
//   - 9 out of 12 have to vote in favour of pausing.

// -  SECURITY_COUNCIL_MEMBER -> can restart law
//   - needs to restart the exact same laws as were paused.
//   - simple majority vote, quorum of 80%
//   - _this is not specified as such in constitution_

// <!-- Executive laws: propose, vote on and implement Arbitrum Improvement Proposals (AIPs) -->
// - TOKEN_HOLDER -> propose Arbitrum Improvement Proposals
//   -  by majority vote.
//   -  if it passes, assigning of TOKEN_REPRESENTATIVE is paused for a specified period of time.
//   -  Assigns proposal 'constitutional' or 'non-constitutional'
//   -  Labels what chain(s) is/are impacted
//   -  Constitutional:
//      - Process
//      - Software update
//      - Core: Note: `Takes any action that requires "chain owner" permission on any chain`
//      - New Chain Approval
//   -  Non-constitutional
//      - Funding
//      - Informational

// - TOKEN_REPRESENTATIVE -> approve constitutional Arbitrum Improvement Proposal
//   - popular vote,  and threshold = 50% .
//   - at least 5% of all Votable Tokens have casted votes either "in favor" or "abstain".
//   - There is delay in implementation. (see details in constitution, phase 4)

// - TOKEN_REPRESENTATIVE -> approve constitutional Arbitrum Improvement Proposal
//   - popular vote, and threshold = 50% .
//   - at least 3% of all Votable Tokens have casted votes either "in favor" or "abstain"
//   - There is delay in implementation. (see details in constitution, phase 4)

// - AIP goes through multiple delays in its implementation to give agents time to react to impending changes.
//   - No implemented (yet) in this protocol.
//   - multi-chain interaction still to be implemented.
