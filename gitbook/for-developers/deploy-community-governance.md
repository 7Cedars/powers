# Deploy Community Governance

🚧 **This page is incomplete and outdated.** 🚧

## Deployment sequence

Deploying an organization unfolds in four steps.

1. Deploy
2. Deploy any additional protocols that will be controlled by the organization.
3. Deploy multiple instances of `Law.sol`.
4. Run the `Powers::constitute` function to adopt laws deployed at step 2.

That's the short version.

## Deployment scripts (Foundry)

In reality, the sequence is a bit more complex because we always need to decide if we need to deploy additional protocols (for instance ERC20 tokens that will be controlled by laws), choose what laws to deploy and how to configure them.

The good news for Foundry users is that it is relatively straightforward to deploy a fully fledged community through a single script. See the following examples:

* [https://github.com/7Cedars/separated-powers/blob/7Cedars/solidity/script/DeployBasicDao.s.sol](../../solidity/script/DeployBasicDao.s.sol)
* [https://github.com/7Cedars/separated-powers/blob/7Cedars/solidity/script/DeployAlignedDao.s.sol](../../solidity/script/DeployAlignedDao.s.sol)
* [https://github.com/7Cedars/separated-powers/blob/7Cedars/solidity/script/DeployGovernYourTax.s.sol](../../solidity/script/DeployGovernYourTax.s.sol)

These scripts automate the following four steps.

## Step 1: Deploy `Powers.sol`

## Step 2: Deploy any additional protocols

## Step 3: Deploy multiple instances of `Law.sol`.

text here

{% content-ref url="broken-reference/" %}
[broken-reference](broken-reference/)
{% endcontent-ref %}

## Step 4: Run the SeparatedPower::constitute





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

