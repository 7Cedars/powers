# AI Prompts 

## Prompt 1: Refactor test
Please refactor the existing tests in LimitExecutionsTest in Law.t.sol according to the changes made to Law.sol and Powers.sol Please keep in mind the following: 
- You can use the DeployTest contract in the same file as an example.
- Law contracts have already been initiated through TestSetup.t.sol and the function initiateLawTestConstitution in ConstitutionsMock.sol. 
- Variables have already been initiated through the function setUpVariables() in TestSetup.t.sol

## Prompt 2: Refactor Constitution. 
Can you refactor the constitution in the function 'createConstitution' in DeployBasicDao.s.sol. Please take into account the following: 
- Laws have been deployed through DeployLaws.s.sol. 
- Similar functions can be found in the initiateLawTestConstitution and initiatePowersConstitution functions of ConstitutionMock.sol. Please use these functions as example. 
- DO NOT create a new file, refactor the existing DeployBasicDao.s.sol file! please. 


... 