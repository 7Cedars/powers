# AI Prompts 

## Update constants.ts after deployment new laws. 
[ the ref needs to be broadcast/DeployLaws/31337/run-latest.json]
Can you check the @run-latest.json for chains 31337, 421614, 11155111 and 11155420 and update the LAW_NAMES and LAW_ADDRESSES accordingly in @constants.ts ? You can the necessary data in "returns" in the file.  

[ the ref needs to be broadcast/DeployMocks/31337/run-latest.json]
Can you check the @run-latest.json for chains 31337, 421614, 11155111 and 11155420 and update the MOCK_NAMES and MOCK_ADDRESSES accordingly in @constants.ts ? You can the necessary data in "returns" in the file.  

## Update Docs after deployment new laws.  
[ the ref needs to be broadcast/DeployLaws/421614/run-latest.json]
Can you check the @run-latest.json for chains 421614, 11155111 and 11155420 please? 

In the run-latest.json files, there is a section "returns". For each law mentioned there, can you go to the gitbook documentation, search for the documentation on this law, and update the deployment table in the 'Current Deployments' section? Thank you! 

## Update refs in metadata json to mock contracts and treasuries.  
[ the ref needs to be broadcast/DeployMocks/421614/run-latest.json]
Can you check the @run-latest.json for chain 421614 please? We will use this file to update all the .json files in @/orgMetadatas.

There is a section "returns" in run-latest.json. Use this data to do the following: 
- Please check take the addresses with the same index as Erc20VotesMock, Erc20TaxedMock and replace the addresses in the `erc20s` field with these addresses.   
- Please check take the address with the same index as Erc721Mock and replace the addresses in the `erc721s` field with this addresses. 
- Please check take the address with the same index as Erc1155Mock and replace the addresses in the `erc1155s` field with this addresses. 

Please note: do this for each and every .json file in @/orgMetadatas. Thank you! 

## Refactor test
Please refactor the existing tests in LimitExecutionsTest in Law.t.sol according to the changes made to Law.sol and Powers.sol Please keep in mind the following: 
- You can use the DeployTest contract in the same file as an example.
- Law contracts have already been initiated through TestSetup.t.sol and the function initiateLawTestConstitution in ConstitutionsMock.sol. 
- Variables have already been initiated through the function setUpVariables() in TestSetup.t.sol

## Create Unit test 1
Please write a comprehensive unit test for HolderSelect.sol at contract HolderSelectTest in Electoral.t.sol. You can use DelegateSelect.sol as an example. Please keep in mind that all laws and mocks have been through DeployAnvilMocks.s.sol and that the test setup can be found in TestSetup.s.sol. Thank you!  

(Do not forget to put in all the context files.... )
## Create Unit test 1
Using the other tests in @State.t.sol and @Executive.t.sol as examples, can you write a comprehensive unit test for @TaxSelect.sol ? Please take into account the test setup at @TestSetup.t.sol and the deployment of laws in @ConstitutionsMock.sol . Thank you 


## Refactor Constitution. 
Can you refactor the constitution in the function 'createConstitution' in DeployBasicDao.s.sol. Please take into account the following: 
- Laws have been deployed through DeployLaws.s.sol. 
- Similar functions can be found in the initiateLawTestConstitution and initiatePowersConstitution functions of ConstitutionMock.sol. Please use these functions as example. 
- DO NOT create a new file, refactor the existing DeployBasicDao.s.sol file! please. 

## Refactor a law, after breaking changes to protocol. 
Can you create a law at HolderSelect.sol, using TaxSelect as example, that allows accounts to self select for a predefined goal, but will only assign this role if the account holds more than a specified amount of tokens. thank you

## Create law based on example + logic description. 
Can you create a law at HolderSelect.sol, using TaxSelect as example, that allows accounts to self select for a predefined goal, but will only assign this role if the account holds more than a specified amount of tokens. thank you

## Create deploy script for new Powers protocol. Using previous deploy scripts as an example. 
Using DeploySeparatedPowers.s.sol and DeployPowers101.s.sol as example, Please write a deploy script at DeployGovernedUpgrades.s.sol. It should have the following laws: 
Executive laws: 
 - A law to adopt a law. Access role = previous DAO 
 - A law to revoke a law. Access role = previous DAO 
 - A law to veto adopting a law. Access role = delegates
 - A law to veto revoking a law. Access role = delegates
 - A preset law to Exchange tokens at uniswap or sth similar chain. Access role = delegates
 - A preset law to to veto Exchange tokens at uniswap or sth similar chain veto. Access role = previous DAO.

 Electoral laws: (possible roles: previous DAO, delegates)
 - a law to nominate oneself for a delegate role. Access role: public.
 - a law to assign a delegate role to a nominated account. Access role: delegate, using delegate election vote. Simple majority vote.
 - a preset self destruct law to assign role to previous DAO. Access role = admin. 

Please take into account that laws are deployed using DeployLaws.s.sol. They do not need to be deployed in this script. 

Thank you

### additional note
Do not forget to put the mentioned files in the context. It will not load them into context automatically.  

## ... 
... 