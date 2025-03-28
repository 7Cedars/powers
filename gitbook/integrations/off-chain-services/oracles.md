---
description: The powers protocol supports push oracles out of-the-box.
---

# Push oracles

## What are push oracles?

Short explanation here.&#x20;

Some example of popular push oracles are:&#x20;

* Service 1
* Service 2
* ...&#x20;

## How to integrate a push oracle

High level explanation. One or two sentences.&#x20;

See the following example:&#x20;

```javascript
// Example code to integrate a push oracle
const oracleService = require('oracle-service');

// Initialize the oracle with necessary configurations
const oracle = new oracleService({
  apiKey: 'your-api-key',
  endpoint: 'https://api.pushoracle.com/v1'
});

// Use the oracle to send a push notification
oracle.sendNotification({
  to: 'destination-device-id',
  message: 'Hello from push oracle!'
})
.then(response => console.log('Notification sent successfully:', response))
.catch(error => console.error('Error sending notification:', error));
```

## Examples&#x20;

The Powers protocol comes standard with a law that integrates a push oracle.&#x20;

{% content-ref url="../../example-laws/executive-laws/automatedaction.sol.md" %}
[automatedaction.sol.md](../../example-laws/executive-laws/automatedaction.sol.md)
{% endcontent-ref %}









