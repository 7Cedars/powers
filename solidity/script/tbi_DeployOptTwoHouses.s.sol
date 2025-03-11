// <!--
//   This layout is inspired by the Optimism Collective's governance structure as of nov 2024.
//   See the intro to their governance structure here: https://gov.optimism.io/t/about-the-optimism-collective/6118
// -->

// <!--
//   Roles (max number of role holders)
//   Note, this is in addition to ADMIN_ROLE and PUBLIC_ROLE)
//  -->
// - TOKEN_REPRESENTATIVE (50)
// - CITIZEN (no max holders?)
// - DIRECTOR (1)
// - FOUNDATION_MEMBER (no max holders)
// - SEQUENCER (no max holders)

// <!-- Electoral laws -->
// - nominate and revoke nomination for TOKEN_REPRESENTATIVE role
//   - Anyone (PUBLIC_ROLE) can nominate themselves.
//   - only account themselves can revoke nomination.

// - assign & revoke TOKEN_REPRESENTATIVE
//   - by (delegate) token vote.
//   - Max amount of representatives.
//   - Anyone can call election.
//   - Max holders (+ delegated tokens) get selected.
//   - It means at all times there can be no more that max amount of representatives.

// - propose assign CITIZEN role
//   - Subjective assessment by fellow citizens
//   - On basis of citizenship eligibility.
//   - Vote. with Quorum + pass threshold.

// - can veto assign CITIZEN role
//   -  by simple vote.

// - revoke CITIZEN role + blacklisting.
//   - by vote among citizens
//   - High quorum + threshold
//   - because code of conduct has been breached.

// - revoke TOKEN_REPRESENTATIVE + blacklisting
//   - by vote among TOKEN_REPRESENTATIVE holders.
//   - High quorum + threshold
//   - because code of conduct has been breached.

// - resign CITIZEN role.
//   - Only by citizen role holder themselves.
//   - No vote needed. Direct call.

// - proposal assign DIRECTOR role
//   - _Not clarified in original docs?_
//   - FOUNDATION_MEMBER role holders vote on proposing account to DIRECTOR role.

// - assign DIRECTOR role
//   - _Not clarified in original docs?_
//   - CITIZEN role holders accept DIRECTOR proposal.
//   - by majority vote.

// - propose revoke DIRECTOR role 2
//   - by popular vote TOKEN_REPRESENTATIVE role holders.
//   - high quorum, high vote threshold.

// - accept revoke DIRECTOR role 1
//   - by popular vote CITIZEN role holders.
//   - high quorum, high vote threshold.

// - assign and revoke FOUNDATION_MEMBER
//   - by direct call DIRECTOR role holder.

// <!-- Emergence Pause & restart laws -->
// - DIRECTOR -> can pause law
//   - by direct call.

// - DIRECTOR -> can restart law
//   - by direct call.

// - CITIZEN -> can restart paused law
//   - by majority vote.

// <!-- Executive laws -->
// - DIRECTOR -> propose budget
//   -  direct call.

// - TOKEN_REPRESENTATIVE -> approve budget.
//   - popular vote, with quorum and threshold.

// - DIRECTOR -> propose adding & removing supported cryptoAssets + accounts.
//   -  _Not clarified in original docs?_
//   -  direct call.

// - TOKEN_REPRESENTATIVE -> approve adding & removing supported cryptoAssets + accounts..
//    _Not clarified in original docs?_
//   - popular vote, with quorum and threshold.

// - £todo: Treasury: Gov Fund ?
//   - Get more info on this

// - £todo: Rights Protection ?
//   - Get more info on this

//   <!-- NB: I don't know if combining them is an actual good idea. tbc -->
// - TOKEN_REPRESENTATIVE -> can do the following
//   - Protocol Revenue Allocation ||
//   - Inflation Adjustment ||
//   - Protocol Upgrades ||
//   - assign & revoke SEQUENCER Role ||
//   - adding & removing laws
//   - By vote.
//   - _combine the following actions in one law? Because all of them have a veto by CITIZEN role holders_

// - CITIZEN -> can veto
//   - Protocol Revenue Allocation ||
//   - Inflation Adjustment ||
//   - Protocol Upgrades ||
//   - assign & revoke SEQUENCER Role ||
//   - adding & removing laws
//   - by vote.

// - CITIZEN -> propose adding or removing article code of conduct
//   - by simple vote.

// - TOKEN_REPRESENTATIVE -> accept adding or removing article code of conduct
//   - by simple vote.

// - DIRECTOR -> has veto on adding or removing article code of conduct
//   - by direct call.

// - CITIZEN -> can
//   - assign funds to retroPGF fund ||
//   - Allocate retroPGF funds to accounts
//   - by vote.

// - TOKEN_REPRESENTATIVE -> can veto
//   - assign funds to retroPGF fund ||
//   - Allocate retroPGF funds to accounts
//   - by vote.
