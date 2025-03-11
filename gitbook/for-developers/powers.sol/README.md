---
description: Checking under the hood of the Powers protocol engine!
---

# Powers.sol

## What are Powers?&#x20;

This contract is the core engine of the Powers protocol. It is meant to be used in combination with implementations of Law.sol. It manages governance flows by calling on laws and executing their actions.

### State variables

The contract has a limited set of state variables to manage governance flows:&#x20;

* It saves proposals by their ID.&#x20;
* It saves adopted laws by their contract address.
* It saves role designations and amount of role holders by their role ID.&#x20;

### Governance flow restrictions

Governance flows are restricted by the following rules:&#x20;

* Executing, proposing and voting can only be done in reference to a role restricted law.
* Roles and laws can only be labelled, assigned and revoked through the execute function of the protocol itself.
* All actions, may they be subject to a vote or not, are executed via Powers' execute function in reference to a law.

The contract should be used as is, making changes to this contract should be avoided. This includes adding state variables or bypassing governance flow restrictions.  Any changes that need to be saved by a community (for instance nominees for an election, blacklisted accounts) should be saved in dedicated laws. Any changes made to governance flow show be implemented through laws.

## Powers.sol Functionalities

Having these basic rules out of the way, let us explore the functionalities of powers.sol. See each of the following subpages for more details.&#x20;

{% content-ref url="constitute-a-new-community.md" %}
[constitute-a-new-community.md](constitute-a-new-community.md)
{% endcontent-ref %}

{% content-ref url="executing-actions.md" %}
[executing-actions.md](executing-actions.md)
{% endcontent-ref %}

{% content-ref url="proposing-actions.md" %}
[proposing-actions.md](proposing-actions.md)
{% endcontent-ref %}

{% content-ref url="voting-on-proposals.md" %}
[voting-on-proposals.md](voting-on-proposals.md)
{% endcontent-ref %}

{% content-ref url="assigning-revoking-and-labelling-roles.md" %}
[assigning-revoking-and-labelling-roles.md](assigning-revoking-and-labelling-roles.md)
{% endcontent-ref %}

{% content-ref url="adopting-and-revoking-laws.md" %}
[adopting-and-revoking-laws.md](adopting-and-revoking-laws.md)
{% endcontent-ref %}
