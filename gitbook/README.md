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

<figure><img src=".gitbook/assets/image (3).png" alt=""><figcaption></figcaption></figure>

By configuring and adopting laws, it is possible to define the mechanisms through which a role is assigned, the power it has, how roles check and balance each other, and under what conditions this can change. Laws can be used to whitelist actions on a role by role basis or they can be combined in governance chains to create granular checks and balances to the power of roles to execute actions.&#x20;

For a detailed diagram of how Powers.sol and Law.sol structure governance flows in the Powers protocol, please see the page on [governance flow](for-developers/governance-flow.md).

## Use Cases&#x20;

Introducing the ability to role restrict governance flows solves several common issues in on-chain governance. Consider the following use cases.&#x20;

<details>

<summary>Managing grant programs in an existing on-chain organisation.  </summary>

**Problem:** Here description of problem.&#x20;

**Solution:** A high level description of solution.

**Implementation:** Law setup to make this work.

**Example:** link to deployed example in app.   &#x20;

</details>

<details>

<summary>Upgrading an on-chain organisation.</summary>

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

<details>

<summary>Defend against governance vote capture. </summary>

**Problem:** Here description of problem.&#x20;

**Solution:** A high level description of solution.

**Implementation:** Law setup to make this work.

**Example:** link to deployed example in app. &#x20;

</details>

## Governance sandbox

Hopefully you have a high-level sense of the particularities of role restricted governance and the Powers protocol. You can check out other pages in this documentation for more detailed information.

Also, you can use the [Powers app](https://powers-protocol.vercel.app) to play around with practical examples to get a better feel for how a role restricted protocol works.
