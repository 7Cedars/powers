Compiler run successful with warnings:
Warning (2072): Unused local variable.
  --> src/mandates/electoral/OpenElectionStart.sol:50:9:
   |
50 |         bytes memory voteConfig = abi.encode(electionContract_, uint256(1));
   |         ^^^^^^^^^^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
  --> src/mandates/electoral/OpenElectionStart.sol:76:9:
   |
76 |         address caller,
   |         ^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
  --> src/mandates/electoral/RoleByTransaction.sol:58:44:
   |
58 |     function handleRequest(address caller, address powers, uint16 mandateId, bytes memory mandateCalldata, uint256 nonce)
   |                                            ^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
  --> src/mandates/electoral/RoleByTransaction.sol:63:36:
   |
63 |         returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
   |                                    ^^^^^^^^^^^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
  --> src/mandates/electoral/RoleByTransaction.sol:63:62:
   |
63 |         returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
   |                                                              ^^^^^^^^^^^^^^^^^^^^^^^

Warning (2072): Unused local variable.
  --> src/mandates/electoral/RoleByTransaction.sol:66:10:
   |
66 |         (uint256 amount) = abi.decode(mandateCalldata, (uint256));
   |          ^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> test/TestConstitutions.sol:281:37:
    |
281 |     function asyncTestConstitution( address payable daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
    |                                     ^^^^^^^^^^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> test/TestConstitutions.sol:430:85:
    |
430 |     function executiveTestConstitution( address payable daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
    |                                                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> test/TestConstitutions.sol:616:44:
    |
616 |     function integrationsTestConstitution( address payable daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
    |                                            ^^^^^^^^^^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> test/TestConstitutions.sol:616:88:
    |
616 |     function integrationsTestConstitution( address payable daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
    |                                                                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> test/TestConstitutions.sol:674:39:
    |
674 |     function helpersTestConstitution( address payable daoMock ) external returns (PowersTypes.MandateInitData[] memory mandateInitData) {
    |                                       ^^^^^^^^^^^^^^^^^^^^^^^

Warning (2072): Unused local variable.
    --> test/unit/Helpers.t.sol:2441:9:
     |
2441 |         uint256 expectedTax = (transferAmount * token.taxRate()) / token.DENOMINATOR();
     |         ^^^^^^^^^^^^^^^^^^^

Warning (2072): Unused local variable.
   --> test/unit/Mandate.t.sol:580:13:
    |
580 |             address[] memory returnedTargets,
    |             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Warning (2072): Unused local variable.
   --> test/unit/Mandate.t.sol:581:13:
    |
581 |             uint256[] memory returnedValues,
    |             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Warning (2072): Unused local variable.
   --> test/unit/Mandate.t.sol:582:13:
    |
582 |             bytes[] memory returnedCalldatas
    |             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Warning (2072): Unused local variable.
   --> test/unit/Mandate.t.sol:613:13:
    |
613 |             uint256 actionId,
    |             ^^^^^^^^^^^^^^^^

Warning (2072): Unused local variable.
   --> test/unit/Powers.t.sol:387:13:
    |
387 |         (,, uint256 voteEnd, uint32 againstVotes, uint32 forVotes, uint32 abstainVotes) =
    |             ^^^^^^^^^^^^^^^

Warning (2018): Function state mutability can be restricted to pure
  --> src/mandates/executive/AdoptMandates.sol:31:5:
   |
31 |     function handleRequest(
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to pure
  --> src/mandates/executive/RevokeMandates.sol:30:5:
   |
30 |     function handleRequest(
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to pure
  --> src/mandates/integrations/SafeSetup.sol:53:5:
   |
53 |     function handleRequest(
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
    --> test/unit/Helpers.t.sol:1047:5:
     |
1047 |     function testConstructor() public {
     |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
    --> test/unit/Helpers.t.sol:2659:5:
     |
2659 |     function testIsApprovedForAll() public {
     |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
    --> test/unit/Helpers.t.sol:2673:5:
     |
2673 |     function testSupportsInterface() public {
     |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
    --> test/unit/Helpers.t.sol:2818:5:
     |
2818 |     function testSupportsInterface() public {
     |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
    --> test/unit/Helpers.t.sol:2824:5:
     |
2824 |     function testURI() public {
     |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to pure
   --> test/unit/MandateUtilities.t.sol:128:5:
    |
128 |     function testArrayifyBoolsEmptyArrayPasses(uint256 numBools) public {
    |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
  --> test/unit/Powers.t.sol:25:5:
   |
25 |     function testDeployPowersMock() public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
   --> test/unit/Powers.t.sol:985:5:
    |
985 |     function testGetRoleHoldersWithEmptyArray() public {
    |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
   --> test/unit/Powers.t.sol:991:5:
    |
991 |     function testGetActionStateNonExistent() public {
    |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
  --> test/unit/PowersUtilities.t.sol:39:5:
   |
39 |     function testGetConditions() public {
   |     ^ (Relevant source part starts here and spans across multiple lines).

Warning (2018): Function state mutability can be restricted to view
  --> test/unit/PowersUtilities.t.sol:81:5:
   |
81 |     function testGetConditionsForNonExistentMandate() public {
   |     ^ (Relevant source part starts here and spans across multiple lines).
