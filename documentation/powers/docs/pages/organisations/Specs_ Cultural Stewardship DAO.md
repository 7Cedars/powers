# Cultural Stewardship DAO Specification

| WARNING: Cultural Stewardship DAO is under development. The organisational specs and deployment addresses are subject to change. This document serves as an initial specification based on the ecosystem architecture. |
| :---- |

## Organisational Structure & Context 

### *Vision & Mission* 

The Cultural Stewardship DAO is a multi-layered ecosystem designed to foster an interplay between  ideational concepts, physical spaces, and digital manifestations. Its primary aim is to act as a steward for cultural assets through a "Layered Approach", ensuring a clear separation between different activities while facilitating their interactions to foster cultural activities.

### *Architecture: Parent & Sub-DAOs* 

The organisation operates through a **Parent Organisation** and three distinct types of **Sub-DAOs**:

1. **Parent DAO**: The central governance body holding the Treasury (Safe). It can create new ‘ideational’ DAOs and confirms the creation of ‘physical’ DAOs. It has the power to deactivate both types of sub-DAOs. It also (re)assigns allowances to its ‘digital’ DAO and its ‘physical' DAOs. It does not manage any of the organization’s activities directly.   
2. **Sub-DAO type \#1 (Digital)**: Manages code repositories, commits, and digital representation of the organisation and its sub-DAOs. From here on referred to as ‘**Digital DAO**’. The parent DAO holds some veto powers over this DAO.  
3. **Sub-DAO type \#2 (Ideational)**: : Manages concepts, digital interfaces, and its own legislative frameworks. It has the power to initiate the creation of a Physical DAO. This type of sub-DAO is from here on referred to as ‘**Ideas DAO**’. It does not have an allowance at the parent DAO. In return, the Parent DAO holds very little Veto power over these types of Sub-DAOs.   
4. **Sub-DAO type \#3 (Physical)**: Manages physical manifestations (e.g., access to spaces, rent, legal logs). From here on referred to as ‘**Physical DAO**’. It has an allowance at the parent DAO. 

### *Treasury Management*

* **Centralised Treasury**: The Parent DAO’s Safe acts as the central treasury for the whole organisation. Physical DAOs and the Digital DAO are assigned allowances at time of creation that they can spend from the central treasury at the moment of their creation.  
* **Fund Flow**: Physical DAOs and the Digital DAO can request additional allowances on the parent organisation’s Safe. The Parent Organisation processes these requests through a governance flow involving Executive execution and Member vetoes.

Multiple instances of Ideas DAOs and Physical DAOs can exist at the same time. They can be spawned and closed. In contrast, only a single instance of a Digital DAO can exist at any one time. It cannot be spawned or closed.

## Parent DAO

### *Roles*

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | Admin   | Assigned at deployment; (re-)assigns among themselves. |
| 1 | Members  | Membership in Sub-DAO \#1, \#2, or \#3. (Not activity-based). |
| 2 | Executives | Elected every N-months from among Members. |
| 3 | Physical DAO | Assigned at creation of a DAO. Can be removed by ideational DAO \+ executives.  |
| 4 | Ideas DAO | Assigned at creation of a DAO. Can be removed by executives.  |
| 5 | Digital DAO | Assigned at creation of a DAO. Only 1 member at all times.  |
| … | Public | Everyone. |

### *Executive Mandates* 

#### Create and revoke Ideas DAO

Member retain the right to initiate new Ideas DAOs, while each idea has to be ok-ed by elected executives. 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Members | Initiate Ideas DAO creation | StatementOfIntent.sol | "string name, string uri" | none | Initiates creation proposal. Vote, normal threshold.  |
| Executives | Execute Ideas DAO creation | BespokeActionSimple.sol | (same as above) | Creates Ideas DAO | Vote \+ proposal exists (No allowance assigned) |
| Executives | Assign role Id to Ideas DAO | BespokeActionOnReturnValue.sol | (same as above) | Assigns role to return value of previous mandate.  | None. Any executive can execute. |
| Members | Veto revoking Ideas DAO | StatementOfIntent.sol | (same as above) | none | Vote, high threshold.   |
| Executives | Revoke Ideas DAO (Role) | BespokeActionOnReturnValue.sol | (same as above) | Revokes roleId from DAO.  | DAO creation should have executed, members should not have vetoed.  |

#### Create and revoke Physical DAO

The Ideas-DAO that creates the Physical-DAO will be assigned a role in the created DAO  

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Members | Initiate Physical DAO Creation | StatementOfIntent.sol | "string name, string uri" | none | Vote, low threshold.  |
| Members | Veto Physical DAO creation  | StatementOfIntent.sol | (same as above) | none | Vote, high threshold & quorum. |
| Executives | Execute Physical DAO Creation | BespokeActionSimple.sol | (same as above) | Creates Physical DAO | Proposal exists, veto does not exist  |
| Executives | Assign role Id to Physical DAO | BespokeActionOnReturnValue.sol | (same as above) | Assigns role to return value of previous mandate.  | Any executive can execute. Previous action executed.  |
| Executives | Assign allowance to Physical DAO | BespokeActionOnReturnValue.sol | (same as above) | Assigns allowance to return value of previous mandate.  | (Not implemented). |
| Members | Veto revoking Physical DAO | StatementOfIntent.sol | (same as above) | none | Vote, high threshold.   |
| Executives | Revoke Physical DAO | BespokeActionOnReturnValue.sol | (same as above) | Revokes roleId.  | DAO creation should have executed, members should not have vetoed.  |

#### Assign additional allowances to Physical DAO or Digital DAO  

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Physical DAO | Veto additional allowance | StatementOfIntent.sol | "address DigitalDAO, address Token, uint96 allowanceAmount, uint16 resetTimeMin, uint32 resetBaseMin" | none | Vote, high threshold.  |
| Physical DAO | Request additional allowance | StatementOfIntent.sol | (same as above) | none | Initiates allowance proposal.  Note: NOT a vote: any physical DAO can submit. |
| Executives | Grant Allowance to Physical DAO | SafeAllowance_Action.sol | (same as above) | Safe.approve(subDao, amount) | Proposal exists, vote, no Physical DAO veto.  |
| Digital DAO | Request additional allowance | StatementOfIntent.sol | (same as above) | none | Initiates allowance proposal.  |
| Executives | Grant Allowance to Digital DAO | SafeAllowance_Action.sol | (same as above) | Safe.approve(subDao, amount) | Proposal exists, vote, no Physical DAO veto. |

#### Update uri

The URI contains all the metadata of the organisation, including designations of sub- and parent-DAOs needed in the front end. In other words, to show new sub-DAOs in the frontend, the URI needs to be updated separately. 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Members | Veto update URI | StatementOfIntent.sol | "string new URI" | none | Vote.  |
| Executives | Update URI | BespokeAction.sol | (same as above) | setUri call | Ideas DAOs did not veto, timelock.  |

#### Mint NFTs Ideas DAO \- ERC 1155 

The token Id that is minted, is the uin256 representation of the caller. This means that every DAO mints a unique token Id. 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Ideas DAO | Mint token | BespokeActionSimple.sol | ‘address to’ | Mint function ERC 1155  | None.  |

#### Mint NFTs Physical DAO \- ERC 1155 

The token Id that is minted, is the uin256 representation of the caller. This means that every DAO mints a unique token Id. 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Physical DAO | Mint token | BespokeActionSimple.sol | ‘address to’ | Mint function ERC 1155  | None.  |

#### Transfer tokens to treasury

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Executive | Transfer tokens to treasury | Safe\_RecoverTokens.sol | None | Goes through whitelisted tokens, and if DAO has any, transfers them to the treasury | None, absolutely anyone can call this mandate and pay for the transfer.  |

### *Electoral Mandates* 

#### Claim membership Parent DAO

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Executives | Veto claim | StatementOfIntent.sol | ‘address Account, uint256 roleId’ | None | None \- any executive can veto.  |
| Public | Parent membership through Sub DAO | BespokeActionSimple.sol | (same as above) | Assign role | The action needs to have been executed in the sub-DAO, any account can try and request.  |

#### Elect Executives

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| Executives | Call election | OpenElectionStart.sol | None  | Creates an election vote list  | Throttled: every N blocks, for the rest none: any executive can call the mandate.   |
| Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any member can vote. This mandate ONLY appear by calling call election.  |
| Members | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any Member can call this.  |

### *Reform Mandates* 

#### Adopt mandate

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Executives | Initiate mandate adoption | StatementOfIntent.sol | \`address\[\] mandates, uint256\[\] roleids\`  | None | None. Any Executive can initiate call for mandate reform.  |
| Members | Veto Adoption | StatementOfIntent.sol | (same as above) | None | Vote, high threshold \+ quorum |
| Physical DAO | Ok adoption | StatementOfIntent.sol | (same as above) | None | Vote, low threshold \+ quorum. Veto should not have passed.  |
| Ideas DAO | Ok adoption | StatementOfIntent.sol | (same as above) | None | Vote, low threshold \+ quorum.  |
| Digital DAO | Ok adoption | StatementOfIntent.sol | (same as above) | None | Vote, low threshold \+ quorum.  |
| Executives | Execute mandate Adoption | AdoptMandates.sol | (same as above) | mandate is adopted.  | Vote, high threshold \+ quorum.  |

## 

## Digital DAO 

### *Roles*

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | Admin   | Revoked at setup |
| 1 | Members  | Proof of Activity \- role by git commit  |
| 2 | Conveners | Elected every N-months from among Members. |
| 3 | Parent DAO | Assigned at creation. Can only be single address.  |
| …  | Etc | Additional roles can be created by sub-DAO.  |
| … | Public | Everyone. |

### *Executive Mandates*

#### Payment of receipts

Meant for expenses that have already been made. Payment after completion.

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Submit receipt | StatementOfIntent.sol | \`address Token, uint256 Amount, address PayableTo\` | None | None. Anyone (also non-members) can submit a receipt.  |
| Conveners | Ok-receipt | StatementOfIntent.sol | (Same as above) | None | None. Any convener can ok a receipt.  |
| Conveners | Execute payment | SafeAllowance_Transfer.sol | (Same as above) | Call to safe allowance module: transfer | Vote, ok-receipt executed, no veto should have been cast.  |

#### Payment of projects

Meant for expenses that will be made in future. Payment before completion.

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Member | Submit project | StatementOfIntent.sol  | (Same as above) | None | Vote. Low threshold and quorum,  |
| Conveners | Execute payment | SafeAllowance_Transfer.sol | (Same as above) | Call to safe allowance module: transfer | Vote, project should have been submitted.  |

#### Update uri

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Conveners | Update URI | BespokeAction.sol | "string new URI" | setUri call | Vote, high threshold and quorum. |

#### Transfer tokens to treasury

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Executive | Transfer tokens to treasury | Safe\_RecoverTokens.sol | None | Goes through whitelisted tokens, and if DAO has any, transfers them to the treasury | None, absolutely anyone can call this mandate and pay for the transfer.  |

### 

### *Electoral Mandates*

#### Assign membership 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Claim member role by git commit | ClaimRoleWithGitSig.sol | Hash, roleId | None | None \- anyone can call. Will not pass if hash does not appear in correct folder for repo.  |
| Public | Assign member role | AssignRoleWithGitSig.sol | (Same as above) | Assigns role.  | Previous mandate needs to have passed.  |

#### Elect Conveners

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| Conveners | Call election | OpenElectionStart.sol | None  | Creates an election vote list  | Throttled: every N blocks, for the rest none: any convener can call the mandate.   |
| Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any member can vote. This mandate ONLY appear by calling call election.  |
| Members | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any Member can call this.  |

### *Reform Mandates*

#### Adopt mandate

Note 1: no veto from outside parties. Ideas DAOs can create their own mandates and roles. Because they do not control any funds, they can be very freewheeling.

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Members | Initiate Adoption | StatementOfIntent.sol | \`address mandateAddress\` | None | Vote, high threshold \+ quorum |
| Parent DAO | Veto Adoption | StatementOfIntent.sol | (same as above) | None | none |
| Executives | Execute mandate Adoption | BespokeActionSimple.sol | (same as above) | mandate is adopted.  | Vote, high threshold  \+ quorum, timelock. No veto |

## 

## Ideas DAO

### *Roles*

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | Admin   | Revoked at setup |
| 1 | Members  | Proof of Activity \- through proof of on-chain interaction  |
| 2 | Conveners | Elected every N-months from among Members. |
| …  | Etc | Additional roles can be created by sub-DAO.  |
| … | Public | Everyone. |

### *Executive Mandates*

#### Mint activity token

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Mint activity NFT | BespokeActionSimple.sol | None | Mints Ideas DAO specific token Id  at Parent DAO, and sends to the caller.  | Throttled. For the rest nothing  |

#### Update uri

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Conveners | Update URI | BespokeAction.sol | "string new URI" | setUri call | Vote, high threshold and quorum. |

#### Transfer tokens to treasury

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Executive | Transfer tokens to treasury | Safe\_RecoverTokens.sol | None | Goes through whitelisted tokens, and if DAO has any, transfers them to the treasury | None, absolutely anyone can call this mandate and pay for the transfer.  |

### 

### 

### *Electoral Mandates*

#### Assign membership 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Claim Member role | MemberRoleByOrgNFT.sol | None | Assigns role | The caller needs to own N amount of (soulbound) NFTs, minted within the last N blocks and minted via the org.  |

#### Elect Conveners

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| Members | Call election | OpenElectionStart.sol | None  | Creates an election vote list  | Throttled: every N blocks, for the rest none: any member can call the mandate.   |
| Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any member can vote. This mandate ONLY appear by calling call election.  |
| Members | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any member can call this.  |

### *Reform mandates*

#### Adopt mandate

Note: no veto from outside parties. Ideas DAOs can create their own mandates and roles. Because they do not control any funds, they can be very freewheeling. 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Members | Veto Adoption | StatementOfIntent.sol | (same as above) | None | Vote, high threshold \+ quorum |
| Executives | Execute mandate Adoption | BespokeActionSimple.sol | (same as above) | mandate is adopted.  | Vote, high threshold  \+ quorum, timelock.  |

## Physical DAO

### *Roles*

| Role Id | Role name | Selection criteria |
| :---- | :---- | :---- |
| 0 | Admin   | Revoked at setup |
| 1 | Members  | Proof of Activity \- POAP  |
| 2 | Conveners | Elected every N-months from among Members. |
|  | HasAccess | A role to denote who has access to physical space.  |
| 3 | Ideas DAO | The Ideas-DAO that spawned the Physical DAO. This can potentially be expanded to include multiple DAOs. |
| 4 | Parent DAO | Speaks for itself.  |
| …  | Etc | Additional roles can be created by sub-DAO.  |
| … | Public | Everyone. |

### *Executive Mandates*

#### Mint POAPS

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Convener | Mint POAP | BespokeActionSimple.sol | \`address Account\`  | Mints Ideas DAO specific token Id  at Parent DAO, and sends to the account.  | Any convener can mint POAPS.  |

#### Payment of receipts

Meant for expenses that have already been made. Payment after completion.

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Submit receipt | StatementOfIntent.sol | \`address token,  uint256 Amount, string uri\` | None | None. Anyone (also non-members) can submit a receipt.  |
| Conveners | Ok-receipt | StatementOfIntent.sol | (Same as above) | None | None. Any convener can ok a receipt.  |
| Conveners | Execute payment | SafeAllowanceExecute.sol | (Same as above) | Call to safe allowance module: transfer | Vote, ok-receipt executed, no veto should have been cast.  |

#### Payment of projects

Meant for expenses that will be made in future. Payment before completion.

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Member | Submit project | StatementOfIntent.sol  | \`address token,  uint256 Amount, string uri\` | None | Vote. Low threshold and quorum,  |
| Conveners | Execute payment | SafeAllowanceExecute.sol | (Same as above) | Call to safe allowance module: transfer | Vote, project should have been submitted, no veto should have been cast.  |

#### Update uri

Note that the URI includes all metadata of the organisation. In this case this will also include references to any legal (rental, etc) documents. 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Conveners | Update URI | BespokeAction.sol | "string new URI" | setUri call | Vote, high threshold and quorum. |

#### Transfer tokens to treasury

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Executive | Transfer tokens to treasury | Safe\_RecoverTokens.sol | None | Goes through whitelisted tokens, and if DAO has any, transfers them to the treasury | None, absolutely anyone can call this mandate and pay for the transfer.  |

### 

#### 

### *Electoral Mandates* 

#### Assign membership 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Public | Claim Member role | MemberRoleByOrgNFT.sol | None | Assigns role | The caller needs to own N amount of (soulbound) POAPs, minted within the last N blocks and minted via the org.  |

#### Elect Conveners

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Member | Nominate | BespokeActionSimple.sol | (bool, nominateMe) | Nomination logged at Nominees.sol helper contract | None, any member can nominate |
| Members | Call election | OpenElectionStart.sol | None  | Creates an election vote list  | Throttled: every N blocks, for the rest none: any member can call the mandate.   |
| Member | Vote in Election | OpenElectionVote.sol | (bool\[\]. vote\] | Logs a vote | None, any member can vote. This mandate ONLY appear by calling call election.  |
| Members | Tally election | OpenElectionEnd.sol | None | Counts vote, revokes and assigns role accordingly | OpenElectionStart needs to have been executed. Any member can call this.  |

#### Assign and revoke physical access: what addresses have physical access to space?

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Convener | Assign hasAccess role | BespokeActionSimple.sol | \`address Account\`  | Calls assign role function | Vote |
| Convener | Revokes hasAccess role | BespokeActionSimple.sol | (same as above) | Calls revoke role function | Vote |

### *Reform Mandates*

#### Adopt mandate

Note: no veto from outside parties. Ideas DAOs can create their own mandates and roles. Because they do not control any funds, they can be very freewheeling. 

| Role | Name & Description | Base contract | User Input | Executable Output | Conditions |
| :---- | :---- | :---- | :---- | :---- | :---- |
| Members | Initiate Adoption | StatementOfIntent.sol | \`address mandateAddress\` | None | Vote, high threshold \+ quorum |
| Parent DAO | Veto Adoption | StatementOfIntent.sol | (same as above) | None | none |
| Executives | Execute mandate Adoption | BespokeActionSimple.sol | (same as above) | mandate is adopted.  | Vote, high threshold  \+ quorum, timelock. No veto |

## 

## Off-chain Operations

### *Dispute Resolution*

Disputes regarding ambiguous mandate conditions or malicious actions by role-holders will be addressed through community discussion in the official communication channels. Final arbitration lies with the **Admin role** of the Parent Organisation if consensus cannot be reached.

### *Code of Conduct*

All participants are expected to act in good faith to further the mission of the Cultural Stewardship DAO. The ecosystem relies on the harmonic interaction between the physical, ideational, and digital layers; disruption in one layer may affect the others.

### *Communication Channels*

Official proposals, discussions, and announcements take place on the DAO's Discord server and community forum. Note: Sub-DAOs may maintain their own specific channels for "Physical" (Space logistics), "Ideational" (Brainstorming), and "Digital" (Code reviews).

## Description of Governance

The Cultural Stewardship DAO implements a federated governance model.

* **Remit**: To manage a shared treasury (Parent) while empowering specialised Sub-DAOs to operate with autonomy in their respective domains (Physical, Ideational, Digital).  
* **Separation of Powers**:  
  * **Financial Control**: Centralised at the Parent level to ensure security.  
  * **Operational Control**: Decentralised to Sub-DAOs to ensure agility.  
  * **Checks and Balances**: Most Sub-DAO actions (like mandates or physical access) are executable by local Conveners but subject to Veto by the Parent Executives.  
* **Executive Paths**:  
  * **Funding**: Sub-DAOs do not hold funds. They act as "cost centres" that request payment execution from the Parent.  
  * **Legislation**: Sub-DAOs can create their own internal mandates and roles, provided they are not vetoed by the Parent DAO.  
* **Summary**: This structure allows for a "Physical manifestation DAO" to worry about rent and keys, while a "Digital manifestation DAO" worries about commits and code, all bound by a common economic and constitutional framework.

## Risk Assessment

### *Role Collision*

Because roles can be dynamically assigned by Sub-DAOs, there is a risk of overlapping roles creating security vulnerabilities. The system mitigates this by using an **ERC-1155 contract** to ensure unique identification across the ecosystem.

### *Dependency Chains*

The "Digital DAO" (\#3) relies on the recognition of Sibling DAOs (\#1 & \#2) to execute payments. If recognition logic fails or desynchronises, operations may stall.
