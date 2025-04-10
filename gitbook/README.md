---
description: >-
  Distribute power, increase security, transparency and efficiency with role
  restricted governance
---

# 💪 Welcome to Powers protocol

🚧 **Documentation is under construction** 🚧

## What it is.

The Powers protocol is a role restricted governance protocol.

This means, simply, that all governance actions are restricted by roles that are assigned to accounts. Only accounts with a 'Senior' role can vote for senior proposals, execute actions designated for seniors, and so on.

It allows for the creation of checks and balances between roles, guard-railing specific (AI agentic) accounts and creating hybrid on- and off-chain organizations, among many other use cases.

The challenge is that actions need to be _restricted_ before they can be _role_ restricted. Role restricted governance protocols only work with external contracts that define which actions a specific role can do under what conditions. These type of protocols become very complex, very quickly.

The Powers protocol provides a minimalist, but very powerful, proof of concept of a role restricted governance protocol.

## Quick links

* [The Github repository](https://github.com/7Cedars/powers)
* [The Powers app](https://powers-protocol.vercel.app/#usecases)

## The protocol

The Powers protocol consists of two elements: Powers and Laws.

### ⚡ Powers

`Powers.sol` is the engine of the protocol that manages governance flows. It should be deployed as is and has the following functionalities:

* Executing actions.
* Proposing actions.
* Voting on proposals.
* Assigning, revoking and labelling roles.
* Adopting and revoking laws.

In addition there is a `constitute` function that allows adopting multiple laws at once. This function can only be called by the admin, and only once.

The governance flow is defined by the following restrictions:

* All actions are executed via Powers' execute function in reference to a law. There are no exceptions.&#x20;
* Executing, proposing and voting can only be done in reference to a role restricted law.
* Roles and laws can only be assigned and revoked through the execute function of the protocol itself.

{% content-ref url="for-developers/powers.sol/" %}
[powers.sol](for-developers/powers.sol/)
{% endcontent-ref %}

### 📜 Laws

Laws define under which conditions a role is allowed to execute what actions.

Example:

> Any account that has been assigned a 'senior' role can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of all seniors vote in favour.

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol` and only have to be deployed once: they can be re-used by Powers.sol instances.&#x20;

Laws have the following functionalities:

* They are role restricted by a single role.
* They are linked to a single `Powers.sol` deployment.
* They have multiple (optional) checks.
* They have a function `executeLaw` that can only be called by their `Powers.sol` deployment.
* They can save a state.
* They can return three arrays to the Powers contract: targets laws, values and function calls.

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

Together, Powers and Laws allow communities to build any governance structure that fit their needs. A community starts by deploying a Powers.sol instance, configuring laws, and adopting them in their Powers.sol instance.

The result can be something like this:&#x20;

<figure><img src=".gitbook/assets/image (7).png" alt=""><figcaption></figcaption></figure>

This DAO is deployed as [Powers 101](https://powers-protocol.vercel.app/#usecases) on Arbitrum sepolia.

For a detailed diagram of how Powers.sol and Law.sol structure governance flows in the Powers protocol, please see the page on [governance flow](for-developers/governance-flow.md).

In essence, by adopting laws an on-chain community creates the legal system that will govern interactions its internal and external interactions. This legal system can be very simple, it cal also be very complex.&#x20;

## Use Cases&#x20;

Introducing the ability to role restrict governance flows solves several common issues in on-chain governance. Consider the following use cases.&#x20;

<details>

<summary>Enforcing decentralization of power.  </summary>

**Problem:** Many decision-making processes in on-chain organisations are highly centralized. Either token based voting is dominated by a small number of whales, or a multisig controls all crucial decision-making or a foundation has been set up to govern day-to-day actions for a community. It goes against one of the central aims of organizing on-chain: decentralization.      &#x20;

**Solution:** The Powers protocol allows for the creation of mechanisms that check and balance powers between roles. For example, we can create a governance chain where an action proposed by one role, can be vetoed by another and only executed by a third. This is a well known, and effective, way of addressing centralization of power in communities. The most famous example is the separation of powers between legislature, judiciary and executive in traditional countries. &#x20;

**Implementation:** Because Powers protocol creates an action ID by hashing calldata, nonce and law address, it can check if the same calldata and nonce have been executed at another law instance. As Law.sol instances conditionally return calldata to Powers.sol, we can make them conditional on the execution of another law.&#x20;

In its most basic implementation, we allow one role to only have the power to propose an action, another to only execute a (previously proposed) action and a third to veto this action. See the [Powers 101](https://powers-protocol.vercel.app/#usecases) example mentioned above.

</details>

<details>

<summary>Upgrading an on-chain organisation.</summary>

**Problem:** Any community or organisation evolves over time. It implies that governance is modular and flexible. As it stands now, most governance setups are anything but flexible. They require extensive changes to be transformed. It leads postponed transitions, which in turn leads to frustration among community members and eventual disengagement.&#x20;

**Solution:** The Powers protocol allows for modular and governed upgradability. Powers.sol does not manage the state of a community: saving the core values of a community, nominees for an election, or any other state is done in laws that can be adopted or revoked. As a community can adopt and revoke laws through its governance system, it allows communities to completely transform their governance structure.&#x20;

**Implementation:** A governance chain that allows for the adoption and revoking of laws. This chain can be setup as permissive or restrictive as needed. It can also be completely absent, which means that the governance system is immutable.

Example: See \[TBI] as an example on-chain organisation with a governed upgradable governance system. &#x20;

</details>

<details>

<summary>Managing grant programs in an existing on-chain organisation.  </summary>

**Problem:** A common issue in on-chain organisations is how to manage assets that are distributed to parties after they have been allocated. This often happens in the case of grants: a general area needs to be supported (say protocol development) and an amount of assets is set aside for this goal. But then several complexities arise: who is going to decide who can receive a grant, how to assess if recipients have created promised product, how to retract funding if not, and what to do with money that has not been spent? &#x20;

**Solution:** A high level description of solution.

**Implementation:** Law setup to make this work.

**Example:** link to deployed example in app.   &#x20;

</details>

<details>

<summary>Defend against governance vote capture. </summary>

**Problem:** Here description of problem.&#x20;

**Solution:** A high level description of solution.

**Implementation:** Law setup to make this work.

**Example:** link to deployed example in app. &#x20;

</details>

<details>

<summary>Combining on- and off-chain governance.</summary>

**Problem:** Here description of problem.&#x20;

**Solution:** A high level description of solution.

**Implementation:** Law setup to make this work.

**Example:** link to deployed example in app. &#x20;

</details>

<details>

<summary>Ring fencing AI agents powers in managing assets.</summary>

**Problem:** Here description of problem.&#x20;

**Solution:** A high level description of solution.

**Implementation:** Law setup to make this work.

**Example:** link to deployed example in app. &#x20;

</details>



## Governance sandbox

Hopefully you have a high-level sense of the particularities of role restricted governance and the Powers protocol. You can check out other pages in this documentation for more detailed information.

Also, you can use the [Powers app](https://powers-protocol.vercel.app) to play around with practical examples to get a better feel for how a role restricted protocol works.
