# AI Prompts 

## Refactor test
Please refactor the existing tests in LimitExecutionsTest in Law.t.sol according to the changes made to Law.sol and Powers.sol Please keep in mind the following: 
- You can use the DeployTest contract in the same file as an example.
- Law contracts have already been initiated through TestSetup.t.sol and the function initiateLawTestConstitution in ConstitutionsMock.sol. 
- Variables have already been initiated through the function setUpVariables() in TestSetup.t.sol

## Create Unit test 
Please write a comprehensive unit test for HolderSelect.sol at contract HolderSelectTest in Electoral.t.sol. You can use DelegateSelect.sol as an example. Please keep in mind that all laws and mocks have been through DeployAnvilMocks.s.sol and that the test setup can be found in TestSetup.s.sol. Thank you!  

(Do not forget to put in all the context files.... )

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