# 💪 Welcome to Powers protocol

🚧 **The Powers protocol is under development. The protocol, app and documentation are a work in progress. They can (and do!) break at any time.** 🚧

## What it is

The Powers protocol offers a role-centric governance system for on-chain organizations. It allows for the separation and distribution of decision-making power by codifying relationships between stakeholders.

Using Powers, a single decision can be guided through multiple role-restricted modules, with each their own conditional checks and voting mechanisms. Together, the create completely modular, transparent and asynchronous governance paths.

The protocol combines a governance engine, **Powers**, with role restricted and modular contracts, called **laws**, to govern **actions**.

* **Powers** manages assigning roles to addresses and governance flows.
* **Laws** define what actions can be taken by which roles under what conditions. When it passes, a law translates an action to executable targets, values and calldatas.
* **Actions** consist of calldata and a unique nonce that is send to a target law.

Crucially, Powers allows the **same action** to be send to **different laws**: the execution of law A can be conditional on the execution of the same action at law B.

## Quick links

* [The Github repository](https://github.com/7Cedars/powers)
* [The Powers app](https://powers-protocol.vercel.app/#usecases)

## Use cases

Powers allows, among others, the following key governance patterns that solve common DAO challenges:

**🔐 Grant Management**: Create accountable grant programs where council members can assign funds and grant allocators, but decisions are logged and can be challenged. All funds remain in community control, allocators can be replaced and grant programs revoked if they don't achieve intended impact.

**⚖️ Separated Powers**: Distribute decision-making across multiple roles to prevent centralization. One role can propose actions, another can veto, and a third can execute - creating checks and balances similar to legislative, judicial, and executive branches.

**🔄 DAO Upgrades**: Upgrade existing DAOs gradually without abandoning established governance. Start with minimal assets in Powers, add new roles and tasks, and transition completely when confidence grows - all while maintaining the existing DAO as a role holder.&#x20;

## The protocol

The Powers protocol consists of two elements: **Powers** and **Laws**. Together they manage how **actions** are governed.;

### ⚡ Powers

`Powers.sol` is the engine of the protocol that manages governance flows. It has the following functionalities:

* Executing actions.
* Proposing actions.
* Voting on proposals.
* Assigning, revoking and labeling roles.
* Adopting and revoking laws.

In addition there is a `constitute` function that allows adopting multiple laws at once. This function can only be called by the admin, and only once.

The governance flow is defined by the following restrictions:

* All actions are executed via Powers' execute function in reference to a law. There are no exceptions.
* Executing, proposing and voting can only be done in reference to a role restricted law.
* Roles and laws can only be assigned and revoked through the execute function of the protocol itself.

{% content-ref url="for-developers/powers.sol/" %}
[powers.sol](for-developers/powers.sol/)
{% endcontent-ref %}

### 📜 Laws

Laws define under what conditions a role is allowed to execute which actions.

Example:

> Any account that has been assigned a 'senior' role can propose to mint tokens at contract X, but the proposal will only be accepted if 20 percent of all seniors vote in favor.

Laws are contracts that follow the `ilaw.sol` interface. They can be created by inheriting `law.sol` and only have to be deployed once. One law can be adopted by multiple Powers.sol instances.

Laws have the following functionalities:

* They are role restricted by a single role.
* They have multiple (optional) checks, including if an action has passed at another law.
* They have an `initializeLaw` function, that is called when the law is adopted.
* They have an `executeLaw` function, that is called when the law executes an action.
* They can save a state.
* They can return three arrays to the Powers contract: targets laws, values and function calls.
* All functionalities are restricted along the `Powers.sol` deployment that adopted the law by calling `initializeLaw`.

Many elements of laws can be changed: the input parameters, the function call that is returned, which checks need to pass, what state (if any) is saved. All these changes are specific to the Powers protocol that adopted the law. Laws are the meat on the bones provided by Powers engine.

What is not flexible, is how Powers interacts with a law. This is done through the `executeLaw` function. When this function is called, the function:

1. Decodes the Powers deployment that calls the law.
2. Runs the checks.
3. Decodes input calldata.
4. Computes return function calls and state change. This can include running additional checks.
5. Saves any state change to the law.
6. Returns the computed function call to the Powers deployment for execution.

{% content-ref url="for-developers/law.sol/" %}
[law.sol](for-developers/law.sol/)
{% endcontent-ref %}

### 🏛️ Powers + Laws = Governance

Together, Powers and Laws allow communities to build any governance structure that fit their needs. A community starts by deploying a Powers.sol instance, configuring laws, and adopting them in their Powers.sol instance.

The result can be something like this:

<figure><img src=".gitbook/assets/image (8).png" alt=""><figcaption></figcaption></figure>

This DAO is deployed as [Powers 101](https://powers-protocol.vercel.app/11155420/0x96408bf4E5c6eD4C64F6B2f6677F058A0e53499D) on Optimism sepolia.

For a detailed diagram of how Powers.sol and Law.sol structure governance flows in the Powers protocol, please see the page on [governance flow](for-developers/powers.sol/governance-flow.md).

## Detailed use Cases

Introducing the ability to role restrict governance flows solves several common issues in on-chain governance. The following use cases highlight the use of checks and balances between roles, guard-rails for specific (AI agentic) accounts and hybrid on- and off-chain communities.

Please see [https://powers-protocol.vercel.app/#deploy](https://powers-protocol.vercel.app/#deploy) for a no-code UI to deploy several of these examples.

<details>

<summary>Manage a grant program.</summary>

**Problem**: The premise of a grant program is simple. A DAO allocates assets in support for a particular goal (say support protocol development) and it delegates the power to decide who actually gets this money to representatives of the organisation. As it stands, this means transferring the assets to a new, separate, protocol that manages asset allocation.

This brings a whole set of new challenges around accountability: how to hold DAO representatives to account if the misbehave, how to hold grant recipients to account for meeting targets and, in the most extreme case, how to stop a program and get money back if it does not achieve its intended aim? Solving these issues involves a lot of overhead and legal wrangling, not to speak of bringing back in issues around the centralization of power.

**Solution**: Use a role restricted governance protocol. Combining laws and roles, an on-chain community can manage asset allocation through multiple roles that devolve responsibilities to each other, while holding each other to account.

**Implementation**: As Powers allows to define responsibilities precisely, it is straightforward to define a 'grant' law is only accessible to council members and gives access to, say, 50 ETH. It can then be made conditional on a proposal made by an applicant and a majority vote among council members. If the grant does not have the intended impact, an executive council can revoke the grant program. Any designated ether will automatically remain in the community.

Note that this also means that all decisions made by the grant council are logged, increasing transparency. It is also possible to implement procedures to challenge grant council decisions, to create a representation of grant recipients in the DAO, and more.

**Example**: See [Managed Grants](https://powers-protocol.vercel.app/1155420/0x26ff6c8d13FC8e6619b40e4b12575ffA85826755) as an example of a grant program governed by the Powers protocol.

</details>

<details>

<summary>Create and run a specialised executive Working Group.</summary>

Coming soon!

</details>

<details>

<summary>Create verifiable links between off-chain snapshot and on-chain Agora votes.</summary>

**Problem**: Accounts do not have context, but members of a community do. This creates several concrete challenges in on-chain organisations: how to deal with the plurality of legal regimes in which community members live? How to deal with accounts that are not human, such as institutions and AI agents? How do we attest members using off-chain data? We somehow need to bring in off-chain contextualise on-chain accounts.

**Solution**: The above problems point to the use of oracles. These are services that provide off-chain data to on-chain smart contracts. The crucial challenge of these services is that they are asynchronous: they do not return data in the same block that it was requested. A seamless way to integrate asynchronous services into governance processes is needed. The Powers protocol provides exactly this.

**Implementation**: There are several implementations for different specific problems:

* We can randomize the allocation of roles to accounts. Similar to how citizens are called on for jury duty in the USA.
* We can create a law that designates roles to accounts depending on the country of residence of the human that owns the account.
* We can create a law that in which an AI agent assesses if a proposal should pass or not.

**Example**: See Beyond the Divide \[TBI] as an example of a Powers protocol implementation that includes all of the above mechanisms.

</details>

<details>

<summary>Decentralize power in an on-chain organization.</summary>

**Problem**: Many decision-making processes in on-chain organisations are highly centralized: Either token based voting is dominated by a few whales, or a multisig account controls crucial decision-making processes. This not only destroys the promise of decentralized on-chain governance but also renders governance susceptible to hostile vote capture.

**Solution**: With the Powers protocol it is possible to create mechanisms that check and balance powers between roles. For example, it is possible to create a governance chain where one role is allowed to pass (but not execute) an action, another to veto an action and a third to execute a (previously passed) action. This is a well known, and effective, way of addressing the centralization of power in communities. The most famous, but more elaborate, example is the separation between legislative, judicial and executive powers.

**Implementation**: Because the Powers protocol creates an action ID by hashing calldata, nonce and law address, it can check if another law has executed the same calldata and nonce. As Law.sol instances conditionally return calldata to Powers.sol, we can make them conditional on the execution of another law. When roles that control these different laws are assigned through divergent means, we can build a very secure and decentralised governance system.

**Example**: [Separated Powers](https://powers-protocol.vercel.app/11155420/0xA2bC87A810cf3B6B18e4Dc9Fb18bc74640207f15) is an example that balances the power to execute actions between token users, holders and developers.

</details>

<details>

<summary>Upgrade an existing DAO.</summary>

**Problem**: How to upgrade an existing DAO? Many of the most popular governance protocols are hard, if not impossible, to change. Is it possible to upgrade an existing DAO and start using the Powers protocol without having to abandon established governance mechanisms?

**Solution**: Yes. An existing DAO can start to use the Powers protocol without having to abandon its governance mechanisms. Even better, the extent that a community governs itself through its existing protocol or a new Powers deployment can be changed on a law-by-law basis. The Powers protocol provides a flexible, modular and governed process for upgrading on-chain communities. It allows for a gradual transformation of an existing DAO to one governed by Powers.

**Implementation**: First, in a newly deployed Powers protocol a role has to be designated to the existing DAO. Second, a governance chain needs to be implemented that allows for the adoption and revoking of laws. This chain can be setup as permissive or restrictive as needed, but the existing DAO should probably have the final say when adopting or revoking a law.

With this setup, it is possible to start out with very few (or no) assets in the new Powers protocol and start setting up several tasks governed by Powers. As confidence in the protocol grows, the DAO can send more assets to the protocol, and add new tasks and roles. The transition is complete when all stakeholders and tasks from the previous DAO are represented in the new Powers governance system and the DAO has transferred all its assets. The existing DAO can then be removed as a role holder.

**Example**: See [Governed Upgrades](https://powers-protocol.vercel.app/11155420/0xa42eBa397054882F651457E7816035A466A28756) as an example of an on-chain organisation with a governed upgradable governance system and a legacy DAO as role holder.

</details>

Hopefully you have a high-level sense of the particularities of role restricted governance and the Powers protocol. You can check out other pages in this documentation for more detailed information.
