# Detailed use cases

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
