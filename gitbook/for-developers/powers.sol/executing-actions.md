# Executing actions

🚧 **This page is incomplete.** 🚧

Executing an action in the Powers protocol follows a request and callback logic. &#x20;

## Requesting an action

An account requests an action by calling the `request` function. The `request` function takes the following parameters:&#x20;

* The ID of the law that will be called. (see for details on law IDs the adopting and revoking laws sections),&#x20;
* calldata&#x20;
* a random nonce &#x20;
* a brief description (or uri to a longer description)

The very first check is if the caller has the appropriate role Id to call this law.  If this and other checks pass, the `request` function will send the calldata and nonce to the target law and emit a `ActionRequested` event.&#x20;

If the call to the law is successful, the target law will return a call to the `fulfill` function. This function can only be called by active laws and will only execute actions that have passed through the `request` function.&#x20;

If all checks pass, the `fulfill` function will attempt to execute all the actions that were included in the response from the law.

## Details&#x20;

At the moment `request` is called, the function creates an action Id by hashing lawId, lawCalldata and the random nonce. This action Id is used to track the action throughout its life cycle.

*



&#x20;\- and beyond: the action Id is also used by other laws to check on the status of specific actions. &#x20;

## Additional considerations (specific title tbi)

Highlight gothcha's that are important to realise.
