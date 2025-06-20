---
description: Interested in creating your own Powers?
---

# Deploy your own Powers

🚧 **This page is a work in progress.** 🚧

## Deployment sequence

At the moment, a no-code solution to deploying Powers does not exist. It is scheduled for inclusion in v0.4 of the protocol. &#x20;

Currently, deploying Powers is done in three steps.

1. Deploy Powers.sol.
2. Create a constitution adopting existing Law.sol contracts.
3. Adopt the constitution in your Powers.sol deployment.

Let us expand on these steps. All examples are build in Foundry. If you are not familiar with Foundry, please [see the documentation here](https://book.getfoundry.sh/).

{% hint style="info" %}
You can check out your Powers by navigating to https://powers-protocol.vercel.app\[chain id here]\[address of your Powers here].

For example, a Powers implementation ('Powers 101') that is deployed on the optimism sepolia testnet can be viewed at: [https://powers-protocol.vercel.app/11155420/0x1978d642224e047487DFFAb77FAD3B17f068eB79](https://powers-protocol.vercel.app/11155420/0x96408bf4E5c6eD4C64F6B2f6677F058A0e53499D)
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

The deploy scripts for several example Powers implementations can be found at:&#x20;

* Powers101: [https://github.com/7Cedars/powers/blob/main/solidity/script/DeployPowers101.s.sol](https://github.com/7Cedars/powers/blob/main/solidity/script/DeployPowers101.s.sol)
* Separated Powers: [https://github.com/7Cedars/powers/blob/main/solidity/script/DeploySeparatedPowers.s.sol](https://github.com/7Cedars/powers/blob/main/solidity/script/DeploySeparatedPowers.s.sol)
* Managed Grants: [https://github.com/7Cedars/powers/blob/main/solidity/script/DeployManagedGrants.s.sol](https://github.com/7Cedars/powers/blob/main/solidity/script/DeployManagedGrants.s.sol)
* Governed Upgrades: [https://github.com/7Cedars/powers/blob/main/solidity/script/DeployGovernedUpgrades.s.sol](https://github.com/7Cedars/powers/blob/main/solidity/script/DeployGovernedUpgrades.s.sol)
