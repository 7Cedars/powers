---
description: Interested in creating your own Powers?
---

# Deploy Your Powers

🚧 **This page is incomplete and outdated.** 🚧

## Deployment sequence

Deploying Powers is done in three steps.

1. Deploy Powers.sol.
2. Create a constitution adopting existing Law.sol contracts.
3. Adopt the constitution in your Powers.sol deployment.

Let us expand on these steps. All examples are build in Foundry. If you are not familiar with Foundry, please see the documentation here.&#x20;

{% hint style="info" %}
You can check out your Powers by navigating to https://powers-protocol.vercel.app\[chain id here]\[address of your Powers here].&#x20;

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

## Step 2: Deploy create a constitution

A constitution is an array of LawInitData structs, that is used as input for the constitute function.

This is the LawInitData struct: &#x20;

```solidity
ILaw.Conditions memory conditions;

lawInitData = new PowersTypes.LawInitData({
     nameDescription: "Elect delegates: Elect delegates using delegated votes. You need to be an admin to use this law.",
     targetLaw: parseLawAddress(0, "DelegateSelect"),
     config: abi.encode(
     
     ),
     conditions: ILaw.Conditions({
          
     });

});
```

## Step 3: Adopt a constitution





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

