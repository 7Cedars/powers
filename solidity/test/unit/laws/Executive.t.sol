// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";
// import { Powers } from "../../../src/Powers.sol";
// import { TestSetupExecutive } from "../../TestSetup.t.sol";
// import { Law } from "../../../src/Law.sol";
// import { LawUtilities } from "../../../src/LawUtilities.sol";
// import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
// import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";
// import { SelfDestructAction } from "../../../src/laws/executive/SelfDestructAction.sol";

// contract OpenActionTest is TestSetupExecutive {
//     using ShortStrings for *;

//     function testExecuteAction() public {
//         // prep
//         address[] memory targetsIn = new address[](1);
//         uint256[] memory valuesIn = new uint256[](1);
//         bytes[] memory calldatasIn = new bytes[](1);
//         targetsIn[0] = address(erc1155Mock);
//         valuesIn[0] = 0;
//         calldatasIn[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

//         address openAction = laws[1];
//         bytes memory lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
//         string memory description = "Execute open action to mint coins";

//         vm.prank(address(daoMock));
//         daoMock.assignRole(1, alice);

//         // act
//         vm.prank(alice);
//         Powers(daoMock).request(openAction, lawCalldata, nonce, description);

//         // assert
//         assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 123);
//     }
// }

// contract ProposalOnlyTest is TestSetupExecutive {
//     using ShortStrings for *;

//     function testExecuteProposalOnly() public {
//         // prep
//         address proposalOnly = laws[3];
//         bytes memory lawCalldata = abi.encode(Erc1155Mock.mintCoins.selector, 123);

//         vm.prank(address(daoMock));
//         Powers(payable(address(daoMock))).assignRole(1, alice);

//         // act
//         vm.prank(alice);
//         Powers(payable(address(daoMock))).request(proposalOnly, lawCalldata, nonce, "Proposal only action");

//         // assert
//         assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 0);
//     }
 
// }

// contract BespokeActionTest is TestSetupExecutive {
//     function testExecuteBespokeAction() public {
//         // prep
//         address bespokeAction = laws[2];
//         bytes memory lawCalldata = abi.encode(123); // amount of coins to mint
//         string memory description = "Bespoke action to mint coins";

//         vm.prank(address(daoMock));
//         daoMock.assignRole(1, alice);

//         // act
//         vm.prank(alice);
//         Powers(daoMock).request(bespokeAction, lawCalldata, nonce, description);
 
//         assertEq(erc1155Mock.balanceOf(address(daoMock), 0), 123);
//     }
// }

// contract SelfDestructActionTest is TestSetupExecutive {
//     function testConstructorInitialization() public {
//         // Get the SelfDestructAction contract
//         address selfDestructAction = laws[5];
        
//         // Test that the contract was initialized correctly
//         assertTrue(Powers(daoMock).getActiveLaw(selfDestructAction), "Law should be active after initialization");
//         assertEq(Law(selfDestructAction).powers(), address(daoMock), "Powers address should be set correctly");
//         assertEq(Law(selfDestructAction).allowedRole(), 0, "Allowed role should be set to ADMIN_ROLE");
//     }

//     function testSuccessfulSelfDestruct() public {
//         // prep
//         address selfDestructAction = laws[5];
//         bytes memory lawCalldata = abi.encode();
//         string memory description = "Self destruct action";

//         // Store initial state
//         bool initialLawStatus = Powers(daoMock).getActiveLaw(selfDestructAction);
//         assertTrue(initialLawStatus, "Law should be active initially");

//         vm.prank(address(daoMock));
//         daoMock.assignRole(0, alice);

//         // act
//         vm.prank(alice);
//         Powers(daoMock).request(selfDestructAction, lawCalldata, nonce, description);

//         // assert
//         assertFalse(Powers(daoMock).getActiveLaw(selfDestructAction), "Law should be inactive after self-destruct");
//     }

//     function testUnauthorizedSelfDestruct() public {
//         // prep
//         address selfDestructAction = laws[5];
//         bytes memory lawCalldata = abi.encode();
//         string memory description = "Self destruct action";

//         // Try to execute without proper role
//         vm.prank(bob);
//         vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
//         Powers(daoMock).request(selfDestructAction, lawCalldata, nonce, description);

//         // Verify law is still active
//         assertTrue(Powers(daoMock).getActiveLaw(selfDestructAction), "Law should remain active after failed attempt");
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         address selfDestructAction = laws[5];
//         bytes memory lawCalldata = abi.encode();

//         // Call handleRequest directly to verify its output
//         (
//             uint256 actionId,
//             address[] memory targets,
//             uint256[] memory values,
//             bytes[] memory calldatas,
//             bytes memory stateChange
//         ) = Law(selfDestructAction).handleRequest(address(0), lawCalldata, nonce);

//         // Verify the output
//         assertEq(targets.length, 13, "Should have thirteen targets");
//         assertEq(targets[0], address(daoMock), "Target should be the DAO");
//         assertEq(values[0], 0, "Value should be 0");
//         assertEq(calldatas[targets.length - 1], abi.encodeWithSelector(Powers.revokeLaw.selector, selfDestructAction), "Calldata should be revokeLaw");
//         assertEq(stateChange, "", "State change should be empty");
//         assertTrue(actionId != 0, "Action ID should not be 0");
//     }

//     function testSelfDestructWithCustomTargets() public {
//         // Create a new SelfDestructAction with custom targets
//         address[] memory customTargets = new address[](1);
//         uint256[] memory customValues = new uint256[](1);
//         bytes[] memory customCalldatas = new bytes[](1);
//         customTargets[0] = address(0x123);
//         customValues[0] = 100;
//         customCalldatas[0] = hex"abcd";

//         LawUtilities.Conditions memory config;
//         SelfDestructAction newLaw = new SelfDestructAction(
//             "CustomSelfDestruct",
//             "Custom self destruct law",
//             payable(address(daoMock)),
//             0,
//             config,
//             customTargets,
//             customValues,
//             customCalldatas
//         );

//         // Verify the custom targets are included in handleRequest output
//         bytes memory lawCalldata = abi.encode();
//         (
//             ,
//             address[] memory resultTargets,
//             uint256[] memory resultValues,
//             bytes[] memory resultCalldatas,
//         ) = newLaw.handleRequest(address(0), lawCalldata, nonce);

//         // Should have original target plus self-destruct target
//         assertEq(resultTargets.length, 2, "Should have two targets");
//         assertEq(resultTargets[0], customTargets[0], "First target should match custom target");
//         assertEq(resultValues[0], customValues[0], "First value should match custom value");
//         assertEq(resultCalldatas[0], customCalldatas[0], "First calldata should match custom calldata");
//         assertEq(resultTargets[1], address(daoMock), "Second target should be DAO for self-destruct");
//     }
// }

