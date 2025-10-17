# Organisation name

## Organisational Structure & Context

### *Vision & Mission*

Powers Labs is the non-profit on-chain organisation that shepherds the development of the Powers protocol. 

### *Treasury Management*

Its principle task is to distribute funding into four development areas: protocol, frontend, documentation and marketing. It does this through allocating grants in these areas by the people that are active in these areas themselves. Decisions on how to distribute available funds *between* these four areas are taken collectively.

### *Funding Policy*

The funding policy outlines the distribution of grants across four key development areas: protocol, frontend, documentation, and marketing. Decisions regarding the allocation of available funds between these areas are made collectively by active participants.

## Roles

| *Role Id* | *Role name* | *Selection criteria.*  |
| :---- | :---- | :---- |
| 0 | Admin | Admin role assigned at deployment.  |
| 1 | Contributor | An account that holds roles 2, 3, 4 or 5\.  |
| 2 | Protocol | An account that has made a contribution to the protocol folder in the Powers repo during the last 90 days.   |
| 3 | Frontend | An account that has made a contribution to the frontend folder in the Powers repo during the last 90 days.   |
| 4 | Documentation | An account that has made a contribution to the documentation folder in the Powers repo during the last 90 days.   |
| 5 | Marketing | An account that has made a contribution to the marketing folder in the Powers repo during the last 90 days.   |
| 6 | Funder | An account that has transferred funds in either native currency or whitelisted token during the last 90 days.  |
| 7 | Applicant | An account that has applied to receive a grant from Powers Labs |
| 8 | Grantee | An account that received a grant from Powers Labs.    |
| … | Public | Everyone.  |

## 

## On-chain Laws

### *Executive Laws (executing actions)* 

| *Role* | *Name & Description* | *Base contract* | *User Input* | *Executable Output* | *Conditions* |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Contributor | Propose budget: Create a Statement of Intent for adapting the grants budget | statementOfIntent.sol | "uint16 lawId", "address TokenAddress", "uint256 Budget" | none | Majority vote, period 7 days, quorum 33 percent.   |
| Funder | Veto budget: Veto the proposal to adapt the grants budget  | statementOfIntent.sol | "uint16 lawId", "address TokenAddress", "uint256 Budget" | none |  |
| Admin | Set budget: Set the budget for the grants  | bespokeAction.sol | "uint16 lawId", "address TokenAddress", "uint256 Budget" |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |
|  |  |  |  |  |  |

### *Electoral Laws (assigning roles)* 

| *Name* | *User Input* | *Executable Output* | *Conditions* |
| :---- | :---- | :---- | :---- |
| Assign Funder Role |  |  |  |
| Assign Contributor Role |  |  |  |
|  |  |  |  |

### *Constitutional Laws (adopting and revoking laws)* 

| *Name* | *User Input* | *Executable Output* | *Conditions* |
| :---- | :---- | :---- | :---- |
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

## Off-chain Operations

### *Dispute Resolution*

What happens if a law's condition is ambiguous, or a role-holder acts maliciously (within the rules)?

### *Code of Conduct / Ethics*

Non-enforceable social norms and expectations for role-holders (e.g., Contributor, Admin).

### *Communication Channels*

Where official proposals, discussions, and votes take place (e.g., Discord, Forum, Snapshot).

## 

## Description governance

A human readable summary of the above. 

* Remit   
* Roles & how the are assigned  
* Executive paths  
* Summary, reiterating links between remit, roles and executive paths.   

 

## Governance Flow Diagram

Here mermaid diagram.   
