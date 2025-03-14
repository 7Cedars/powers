---
description: >-
  Distribute power, increase security, transparency and efficiency with role
  restricted governance
---

# 💪 Welcome to Powers Protocol

🚧 **Documentation is under construction** 🚧

## What it is.

The Powers protocol is a role restricted governance protocol.

This means, simply, that all governance actions are restricted by roles that are assigned to accounts. Only accounts with a 'Senior' role can vote for senior proposals, execute actions designated for seniors, and so on.

It allows for the creation of checks and balances between roles, guard-railing specific (AI agentic) accounts and creating hybrid on- and off-chain organizations, among many other use cases.

The challenge is that actions need to be _restricted_ before they can be _role_ restricted. Role restricted governance protocols only work with external contracts that define which actions a specific role can do under what conditions. These type of protocols become very complex, very quickly.

The Powers protocol provides a minimalist, but very powerful, proof of concept of a role restricted governance protocol.

It consists of two elements: Powers and Laws.

### ⚡ Powers

`Powers.sol` is the engine of the protocol that manages governance flows. It should be deployed as is and has the following functionalities:

* Executing actions.
* Proposing actions.
* Voting on proposals.
* Assigning, revoking and labelling roles.
* Adopting and revoking laws.

In addition there is a `constitute` function that allows adopting multiple laws at once. This function can only be called by the admin, and only once.

The governance flow is defined by the following restrictions:

* Executing, proposing and voting can only be done in reference to a role restricted law.
* Roles and laws can only be labelled, assigned and revoked through the execute function of the protocol itself.
* All actions, may they be subject to a vote or not, are executed via Powers' execute function in reference to a law.

{% content-ref url="for-developers/powers.sol/" %}
[powers.sol](for-developers/powers.sol/)
{% endcontent-ref %}

### 📜 Laws

Laws define under which conditions a role can execute what actions.

Example:

> Any account that has been assigned a 'senior' role can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of all seniors vote in favour.

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol`. Laws have the following functionalities:

* They are role restricted by a single role.
* They are linked to a single `Powers.sol` deployment.
* They have multiple (optional) checks.
* They return a function call.
* They can save a state.
* They have a function `executeLaw` that can only be called by their `Powers.sol` deployment.

Many elements of laws can be changed: the input parameters, the function call that is returned, which checks need to pass, what state (if any) is saved. Pretty much anything is possible. Laws are the meat on the bones provided by Powers engine.

What is not flexible, is how Powers interacts with a law. This is done through the `executeLaw` function. When this function is called, the function:

1. Runs the checks
2. Decodes input calldata.
3. Computes return function calls and state change. This can include running additional checks.
4. Saves any state change to the law.
5. Returns the computed function call to Powers for execution.

{% content-ref url="for-developers/law.sol/" %}
[law.sol](for-developers/law.sol/)
{% endcontent-ref %}

### 🏛️ Powers + Laws = Governance

Together, Powers and Laws allow communities to build any governance structure that fit their needs. It is possible to define the mechanisms through which a role is assigned, the power it has, how roles check and balance each other, and under what conditions this can change.

\[ here insert diagram ]&#x20;

<details>

<summary>Example A: Adopt a new law, conditional on a secondary governance check</summary>

**Law 1** allows 'members' of a community to propose adopting a new law. Law 1 is subject to a vote, and the proposal will only be accepted if more than half of the community votes in favour.

Alice, as a community member, proposes a law that allows community members to create a grant program with a budget of 500 tokens X. Other community members vote in favor. The proposal passes.

Alice calls the execute function. Now _nothing_ happens. Their proposal has been formalised but no executable call was send to the Powers protocol governing the community.

**Law 2** allows governors in the community to accept and implement new laws. Law 2 is also subject to a vote and, crucially, needs the exact same proposal to have passed at Law 1.

David, who is a senior, notices that a proposal has passed at Law 1. He puts the proposal up for a vote among other seniors. Eve and Helen, the other seniors, vote in favour.

Following the vote, David calls the execute function and the Power protocol implements the action: the new law is adopted and community members will be able to apply to the new grant program.

**Note** that this is a basic example of a governance chain: Multiple laws that are linked together through child-parent relations where a proposal needs to pass a child law before it can executed by a parent law. This chain gave members the right of initiative and governors the right of implementation, creating a balance of power between the two roles.

</details>

<details>

<summary>Example B: Assign governor roles through Liquid Democracy</summary>

**Law 1** allows 'members' of a community to nominate themselves for a 'governor' role in their community.

Alice, Bob and Charlotte each call the law through powers `execute` function and save their nomination in the law.

**Law 2** assigns governor roles to accounts saved in Law 1. It does this on the basis of delegated tokens held by accounts. Any account can call the law, triggering (and paying gas costs for) an election.

In January, David obtains a large amount of tokens and delegates them to Bob. He calls law 2 and triggers an election. Alice and Bob are elected and assigned as governors. In the following weeks, he notices that bob is not responding to messages and not voting in elections.

In February, he re-delegates his tokens Charlotte and in the next block calls an election. Alice and Charlotte win the election and are assigned as governors. Bob per immediate effect loses his governor role and all of its privileges.

**Note** that this is an example of assigning roles through what can be called Liquid Democracy. Roles can also be assigned directly, through votes among peers, a council vote or through a minimal threshold of token holdings. Pretty much anything is possible.

</details>

More examples can be found among the example communities.

## Unique strengths

In comparison to existing governance solutions, role restricted governance protocols are simpler, while being more efficient, modular and flexible. They are also different. It is important to be aware of these differences and why they make these protocols so powerful.

### Assigning roles

You always need mechanisms for assigning roles to accounts. It is not possible to assign roles to accounts outside the Powers protocol: these role allocations will not be recognised.

As any other governance mechanism, role allocation need to be encoded in laws that are adopted in the Powers.sol contract. Without laws to assign roles to accounts, community governance will not work.

### Voting power

Accounts vote with their roles, not with their tokens. This means that voting on proposals happens on a 1 account = 1 vote basis, similar to the logic of a multisig wallet. This is one of the implications of using role restricted governance, and cannot be changed.

What can be done, though, is to assign roles on the basis of (delegated) tokens. See _Example B: Assign governor roles through Liquid Democracy_ above. Through these types of electoral mechanisms, token holdings can translate to having a specific role assigned to an account.

### Governance chains

Proposal IDs are calculated by hashing the target law, calldata and description of a proposed action. This means that it is possible to use the same calldata and description across multiple target laws.

This allows for the creation of governance chains. If law A and law B require the same calldata, we can check if a proposal at law A has been executed before allowing it to go up for a vote at Law B. This allows different roles in community governance to check each others powers.

### Multi Calls&#x20;

Multi calls are supported, with a small caveat. It is only possible to call one law at a time, but each law can instruct the Powers protocol make an unlimited amount of calls.     &#x20;

### Upgradability

Any implementation of the Powers protocol that has a law to adopt new (and revoke existing) laws is upgradable. A community's governance is immutable when it does not have such a law. Note that this also implies that upgrading is modular: A governance structure can change one law at a time.

Because adopting and revoking laws needs to happen via an existing law, they are subject to existing governance checks. This means that upgrading can be very safe - or not at all. It completely depends on how the governance chain to adopt and revoke laws has been implemented.

## Governance sandbox

You made it all the way through the main page!

Hopefully you have a high-level sense of the particularities of role restricted governance and the Powers protocol. You can check out other pages in this documentation for more detailed information.

Also, you can use the [Powers app](https://separated-powers.vercel.app/) to play around with practical examples to get a better feel for how a role restricted protocol works.
