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

`Powers.sol` is the engine of the protocol that manages governance flows. It has the following functionalities:

* Executing actions.
* Proposing actions.
* Voting on proposals.
* Assigning, revoking and labeling roles.
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

Laws define under what conditions a role is allowed to execute which actions.

Example:

> Any account that has been assigned a 'senior' role can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of all seniors vote in favor.

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol` and only have to be deployed once. One law can be adopted by multiple Powers.sol instances.&#x20;

Laws have the following functionalities:

* They are role restricted by a single role.
* They have multiple (optional) checks.
* They have an `executeLaw` function.
* They can save a state.
* They can return three arrays to the Powers contract: targets laws, values and function calls.
* All functionalities are restricted along the `Powers.sol` deployment that adopted the law.

Many elements of laws can be changed: the input parameters, the function call that is returned, which checks need to pass, what state (if any) is saved. All these changes are specific to the Powers protocol that adopted the law. Laws are the meat on the bones provided by Powers engine.

What is not flexible, is how Powers interacts with a law. This is done through the `executeLaw` function. When this function is called, the function:

1. Decodes the Powers deployment that calls the law.&#x20;
2. Runs the checks.&#x20;
3. Decodes input calldata.
4. Computes return function calls and state change. This can include running additional checks.
5. Saves any state change to the law.
6. Returns the computed function call to the Powers deployment for execution.

{% content-ref url="for-developers/law.sol/" %}
[law.sol](for-developers/law.sol/)
{% endcontent-ref %}

### 🏛️ Powers + Laws = Governance

Together, Powers and Laws allow communities to build any governance structure that fit their needs. A community starts by deploying a Powers.sol instance, configuring laws, and adopting them in their Powers.sol instance.

The result can be something like this:&#x20;

<figure><img src=".gitbook/assets/image (7).png" alt=""><figcaption></figcaption></figure>

This DAO is deployed as [Powers 101](https://powers-protocol.vercel.app/#usecases) on Arbitrum sepolia.

For a detailed diagram of how Powers.sol and Law.sol structure governance flows in the Powers protocol, please see the page on [governance flow](for-developers/governance-flow.md).

## Use Cases&#x20;

Introducing the ability to role restrict governance flows solves several common issues in on-chain governance. Consider the following use cases.&#x20;

<details>

<summary>Decentralize power in an on-chain organization.  </summary>

**Problem:** Many decision-making processes in on-chain organisations are highly centralized. Either token based voting is dominated by a small number of whales, or a multisig controls all crucial decision-making or a foundation has been set up to govern day-to-day actions for a community. It goes against one of the central aims of organizing on-chain - decentralization - and makes governance susceptible to vote capture.&#x20;

**Solution:** The Powers protocol allows for the creation of mechanisms that check and balance powers between roles. For example, we can create a governance chain where an action proposed by one role, can be vetoed by another and only executed by a third. This is a well known, and effective, way of addressing centralization of power in communities. The most famous example is the separation of powers between legislature, judiciary and executive in traditional countries. &#x20;

**Implementation:** Because Powers protocol creates an action ID by hashing calldata, nonce and law address, it can check if the same calldata and nonce have been executed at another law instance. As Law.sol instances conditionally return calldata to Powers.sol, we can make them conditional on the execution of another law.&#x20;

In its most basic implementation, we allow one role to only have the power to propose an action, another to only execute a (previously proposed) action and a third to veto this action. See the [Powers 101](https://powers-protocol.vercel.app/#usecases) example mentioned above. &#x20;

</details>

<details>

<summary>Upgrade an existing DAO.</summary>

**Problem:** How to upgrade an existing DAO? Many of the most popular governance protocols are hard, if not impossible, to adapt. Is it possible to integrate the Powers protocol into existing governance flow of a DAO?&#x20;

**Solution:** Yes. The Powers protocol can be integrated into existing DAOs. Even better, the extent that a community is governed through an existing protocol or Powers can be changed over time by adopting and revoking laws. In other words, the Powers protocol provides a flexible, modular and governed process for upgrading on-chain communities. This ability also allows for a gradual transformation of an existing DAO to one governed by Powers.

**Implementation:** Two things are needed. First, a role has to be designated to the existing DAO. Second, a governance chain needs to be implemented that allows for the adoption and revoking of laws. This chain can be setup as permissive or restrictive as needed, but the existing DAO should probably have the final say if a law will or will not be revoked or adopted.&#x20;

With this setup, it is possible to start out with very few (or no) assets in the new Powers protocol and start setting up a number of tasks governed by Powers. As confidence in the protocol grows, more assets can be sent to the protocol, and new tasks and roles can be added. The transition is complete when all stakeholders and tasks from the previous DAO are represented in the new Powers governance system and all assets have been transferred. The existing DAO can then be removed as role holder.&#x20;

**Example:** See \[TBI] as an example of an on-chain organisation with a governed upgradable governance system and a legacy DAO as role holder. &#x20;

</details>

<details>

<summary>Manage a grant program.   </summary>

**Problem:** A common issue in on-chain organisations is how to decentralize powers without weakening accountability. A classic example of this are grant programs: A DAO decides to allocate assets in support for a particular goal (say support protocol development), but the power to decide who actually gets this money is left with several representatives of the organisation. As it stands, this means transferring the assets to a new, separate, protocol that manages the allocation of assets.&#x20;

This brings a whole set of new challenges around accountability: how to hold DAO representatives to account if the misbehave, how to hold grant recipients to account for meeting targets and, in the most extreme case, how to stop a program and get money back if it is clear that it does not achieve its intended aim? Solving these issues involves a lot of overhead and legal wrangling because, as it stands now, these different tasks are managed by different protocols. Also, many solutions bring in a serious centralization of power. See for instance the Hats protocol. &#x20;

**Solution:** Use a role restricted governance protocol. Combining laws and roles, asset allocation can be managed within a DAO, or with full oversight by a DAO.&#x20;

**Implementation:** As Powers allows to define responsibilities precisely, it is straightforward to define a 'grant' law is only accessible to council members and gives access to, say, 50 ETH. It can then be made conditional on a proposal made by an applicant and a majority vote among council members. If the grant does not have the intended impact, the law can be revoked. Any designated ether will automatically remain in the community.&#x20;

Note that this also means that all decisions made by the grant council will be logged, increasing transparency greatly. It is also possible to implement procedures to challenge grant council decisions, to create representation of grant recipients in the DAO, and more. &#x20;

**Example:** See \[TBI] as an example of a grant program governed by the Powers protocol. &#x20;

</details>

<details>

<summary>Integrate off-chain context into on-chain accounts.  </summary>

**Problem:** Accounts do not have context, but members of a community do. This creates several concrete challenges in on-chain organisations: how to deal with the plurality of legal regimes in which community members live? How to deal with accounts that are not human, such as institutions and AI agents? How do we attest members using off-chain data? We somehow need to bring in off-chain context to realize the promises of on-chain governance.    &#x20;

**Solution:** The above problems point to the use of oracles: these are a type of service used to bring off-chain data into on-chain smart contracts. The crucial challenge of these services is that they are asynchronous: the do not return data in the same block that it was requested. What is needed, in short, is a seamless way to integrate asynchronous services into governance processes.

The Powers protocol supports async services out of the box.  &#x20;

**Implementation:** There are several implementations for different specific problems:

* We can randomize the allocation of roles to accounts. Similar to how citizens are called on for jury duty in the USA. &#x20;
* We can create a law that designates roles to accounts depending on the country of residence of the human that owns the account.
* We can create a law that in which an AI agent assesses if a proposal should pass or not.  &#x20;

**Example:** See \[TBI] as an example of a grant program governed by the Powers protocol. &#x20;

</details>

## Governance sandbox

Hopefully you have a high-level sense of the particularities of role restricted governance and the Powers protocol. You can check out other pages in this documentation for more detailed information.

Also, you can use the [Powers app](https://powers-protocol.vercel.app) to play around with practical examples to get a better feel for how a role restricted protocol works.
