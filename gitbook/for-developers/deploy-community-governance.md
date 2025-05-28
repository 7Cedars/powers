---
description: Interested in creating your own Powers?
---

# Deploy your own Powers

🚧 **This page is a work in progress.** 🚧

## Deployment sequence

Deploying Powers is done in three steps.

1. Deploy Powers.sol.
2. Create a constitution adopting existing Law.sol contracts.
3. Adopt the constitution in your Powers.sol deployment.

Let us expand on these steps. All examples are build in Foundry. If you are not familiar with Foundry, please see the documentation here.

{% hint style="info" %}
You can check out your Powers by navigating to https://powers-protocol.vercel.app\[chain id here]\[address of your Powers here].

For example, a Powers implementation ('Powers 101') that is deployed on the optimism sepolia testnet can be viewed at: [https://powers-protocol.vercel.app/11155420/0x41381207E6f862CF5a3994B9d0e274530E4c3668](https://powers-protocol.vercel.app/11155420/0x41381207E6f862CF5a3994B9d0e274530E4c3668)
{% endhint %}

## Step 1: Deploy Powers.sol

Deploying the Powers contracts is straightforward. The constructor function takes two variables: a name and a uri to metadata.

```solidity
vm.startBroadcast();
Powers powers = new Powers(
    // Name of the DAO
    "My First Powers", 
    // IPFS link to metadata. See the link for an example layout of this json file. 
    "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreicwiqgcvzqub6xv7ha37ohgkc3vprvh6ihqtgs7bk235apaadnqha" 
);
vm.stopBroadcast();
```

At this stage, the Powers contract cannot do anything because it does not have any laws. We need to call the 'constitute' function to implement a constitution.

Before we can do that, we need to create the constitution of our Powers implementation.

## Step 2: Create a constitution

A constitution is an array of LawInitData structs, that is used as input for the constitute function.

{% hint style="info" %}
**IMPORTANT!**

As Powers adopts laws, each law is given an **index**. The index starts at 1, **not zero**. The first law to be adopted gets index 1, the second 2, and so on.

When referring to laws that need to be completed (`conditions.needCompleted`), can veto (`conditions.needNotCompleted`) or record state (`conditions.readStateFrom)` we need to refer to the index the law will have in your Powers deployment - not in your LawInitData array!

To avoid confusion, it is easiest to start populating the LawInitData array at position 1 as well, keeping the locations and law indices the same.
{% endhint %}

This is the LawInitData struct:

```solidity
ILaw.Conditions memory conditions;

lawInitData = new PowersTypes.LawInitData({
     nameDescription: "Name: and description of law.", // note the use of ':' to split name and description.
     targetLaw: 0x9438230c7275811a88aE1147f13eF29501CCb7Db, // the address of the law to be adopted. 
     config: abi.encode(), // optional configuration settings for adopting a law.
     // all conditions are optional. They default to 0.
     conditions: ILaw.Conditions({ // conditions that need to fulfilled before the law can be executed. 
        // role restriction: 
        allowedRole: 0, // uint256,  the role ID that an accounts needs to have (the default 0 is `ADMIN_ROLE`) 
        // voting: 
        quorum: 40, // uint8, the percentage of votes versus total role holders needed to pass. If set to 0, no vote is required.  
        votingPeriod: 1200, // uint32, Voting period in blocks. 
        succeedAt: 51, // uint8, percentage of For votes needed to pass.
        delayExecution,: 600, // uint48, number of blocks that needs to pass after end of vote before law can be executed. 
        // dependent laws:  
        needCompleted: 2, // uint16, the index of a law that needs to have been fulfilled before the law can be executed.  
        needNotCompleted, 3, // uint16, the index of a law that should NOT have been fulfilled before the law can be executed.
        readStateFrom, 4, // uint16, the index of a law that can be used as source of state data.
        // throttling execution:  
        throttleExecution, 2400 // uint48, the number of blocks that needs to have passed before the law can be executed after a prior execution. 
     });
});
```

A typical (but in this case very short) constitution will look something like this:

```solidity
// Notice that we create a conditions struct before hand, and reuse it. This to avoid 'stack to deep' errors.  
ILaw.Conditions memory conditions;
// the array of LawInitData that we will fill in below. 
lawInitData = new PowersTypes.LawInitData[](4);

//////////////////////////////////////////////////////////////////
//                       Executive laws                         // 
//////////////////////////////////////////////////////////////////
// this law allows for the execution of any action. 
// setting conditions. 
conditions.allowedRole = 1; // The role that is allowed to execute an action. 
conditions.quorum = 50; // = 50% quorum needed of role 1 holders. 
conditions.succeedAt = 77; // = 77% simple majority needed for executing an action
conditions.votingPeriod = 1200; // duration voting.
conditions.delayExecution = 500; // delayed execution.
// creating the lawInitData struct.  
lawInitData[1] = PowersTypes.LawInitData({
    nameDescription: "Execute an action: Execute an action that has been proposed by the community.",
    targetLaw: 0x7c9b4bc62A89A1b44559FA63c68C4fb6e47435CD,
    config: abi.encode(), // empty config, an open action takes address[], uint256[], bytes[] as input.             
    conditions: conditions
});
// deleting conditions struct so we can reuse it for the next law. 
delete conditions;

// etc... 

//////////////////////////////////////////////////////////////////
//                       Electoral laws                         // 
//////////////////////////////////////////////////////////////////
// This law allows accounts to nominate themselves for a role. 
// setting conditions
conditions.allowedRole = type(uint256).max; // = 'PUBLIC_ROLE': anyone.  
// creating the lawInitData struct.  
lawInitData[2] = PowersTypes.LawInitData({
    nameDescription: "Nominate me for delegate: Nominate yourself for a delegate role. You need to be a community member to use this law.",
    targetLaw: 0x9438230c7275811a88aE1147f13eF29501CCb7Db, // an instance of the NominateMe contract. 
    config: abi.encode(), // no config needed for the 'NominateMe' contract. 
    conditions: conditions
});
// deleting conditions struct so we can reuse it for the next law.   
delete conditions; 

// This law enables role selection through delegated voting using an ERC20 token
conditions.allowedRole = 0; // Role restriction: the admin calls elections
conditions.readStateFrom = 2;  // the state from NominateMe, at law index 2, is used to elect delegates. 
lawInitData[3] = PowersTypes.LawInitData({
    nameDescription: "Elect delegates: Elect delegates using delegated votes. You need to be an admin to use this law.",
    targetLaw: 0x076ed9740e2416294780737D1E1A0531F16218eF,
    config: abi.encode(
        0x2f5628002C31B9476aD20a1Ba4ECB817adFc5416, // the address to a ERC20Votes implementation
        15, // max role holders to be elected
        1 // The roleId to be elected
    ),
    conditions: conditions
});
delete conditions;

// etc..

```

## Step 3: Adopt a constitution

Call the `constitute` function in your Powers instance, using the array of LawInitData structs we just created.

```solidity
// Here we call the constitute function, which will adopt the laws. 
vm.startBroadcast();
powers.constitute(lawInitData);
vm.stopBroadcast(); 
```

Et voila! You deployed an on-chain Powers :clap:

## Example deploy scripts

to do.

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
