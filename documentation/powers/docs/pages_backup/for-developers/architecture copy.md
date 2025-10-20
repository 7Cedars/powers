# Architecture

The Powers protocol consists of two elements: **Powers** and **Laws**. Together they manage how **actions** are governed.

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

{% content-ref url="powers.sol/" %}
[powers.sol](powers.sol/)
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

{% content-ref url="law.sol/" %}
[law.sol](law.sol/)
{% endcontent-ref %}

### 🏛️ Powers + Laws = Governance

Together, Powers and Laws allow communities to build any governance structure that fit their needs. A community starts by deploying a Powers.sol instance, configuring laws, and adopting them in their Powers.sol instance.

The result can be something like this:

<figure><img src="../.gitbook/assets/image (8).png" alt=""><figcaption></figcaption></figure>

This DAO is deployed as [Powers 101](https://powers-protocol.vercel.app/11155420/0x96408bf4E5c6eD4C64F6B2f6677F058A0e53499D) on Optimism sepolia.

## Detailed Governance Flow

The above is possible because laws provide a modular governance layer around the Powers.sol engine. Each governance action is initiated in reference to a law, and is executed in line with its role restriction, checks and allowed actions.

The following is a  detailed diagram of the governance flow in the Powers protocol:

<figure><img src="../.gitbook/assets/image (5).png" alt=""><figcaption></figcaption></figure>
