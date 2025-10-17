---
description: Checking under the hood of the Powers protocol engine.
---

# Powers.sol

## What are Powers?

Powers are role restricted actions. Because actions are restricted, they are plural: we can create multiple powers in one organisation, and create checks and balances between them. Role restricting actions in a governance protocol allows for the separation of powers in DAOs.

Laws are the way in which role restricted actions are encoded. As such, Powers cannot exist without laws. Powers.sol manages governance flows by calling on laws and executing actions they return.

### State variables

The contract has a limited set of state variables to manage governance flows:

* It saves actions by their ID.
* It saves adopted laws by their contract address.
* It saves role designations and amount of role holders by their role ID.
* It saves the amount, block number and accounts of deposits in native currency.

### Governance flow restrictions

Governance flows are restricted by the following rules:

* Executing, proposing and voting can only be done in reference to a role restricted law.
* Roles and laws can only be assigned and revoked through the execute function of the protocol itself.
* The same holds for labeling roles numbers.
* All actions, may they be subject to a vote or not, are executed via Powers' execute function in reference to a law.

The contract should be used as is. This includes adding state variables or bypassing governance flow restrictions. Any changes that need to be saved by a community (for instance nominees for an election, blacklisted accounts) should be saved in a dedicated law.

## Powers.sol functionalities

Having these basic rules out of the way, let us explore the functionalities of Powers.sol.

{% content-ref url="executing-actions.md" %}
[executing-actions.md](executing-actions.md)
{% endcontent-ref %}

{% content-ref url="proposing-actions.md" %}
[proposing-actions.md](proposing-actions.md)
{% endcontent-ref %}

{% content-ref url="assigning-revoking-and-labelling-roles.md" %}
[assigning-revoking-and-labelling-roles.md](assigning-revoking-and-labelling-roles.md)
{% endcontent-ref %}

{% content-ref url="adopting-and-revoking-laws.md" %}
[adopting-and-revoking-laws.md](adopting-and-revoking-laws.md)
{% endcontent-ref %}
