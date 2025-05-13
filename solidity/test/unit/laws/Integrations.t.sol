// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import { Powers } from "../../../src/Powers.sol";
// import { TestSetupIntegrations } from "../../TestSetup.t.sol";
// import { Law } from "../../../src/Law.sol";
// import { ILaw } from "../../../src/interfaces/ILaw.sol";
// import { LawUtilities } from "../../../src/LawUtilities.sol";
// import { GovernorCreateProposal } from "../../../src/laws/integrations/GovernorCreateProposal.sol";
// import { Governor } from "@openzeppelin/contracts/governance/Governor.sol";
// import { GovernorMock } from "../../mocks/GovernorMock.sol";
// import { Erc20VotesMock } from "../../mocks/Erc20VotesMock.sol";

// contract GovernorCreateProposalTest is TestSetupIntegrations {
//     using ShortStrings for *;

//     GovernorMock public governor;
//     Erc20VotesMock public votingToken;
//     uint256 public constant VOTING_DELAY = 25;
//     uint256 public constant VOTING_PERIOD = 50;
//     uint256 public constant QUORUM_FRACTION = 4;

//     function setUp() public virtual override {
//         super.setUp();
//         governor = GovernorMock(payable(mockAddresses[1]));
//         votingToken = Erc20VotesMock(mockAddresses[2]);
//     }

//     function testConstructorInitialization() public {
//         // Get the GovernorCreateProposal contract from the test setup
//         uint16 governorCreateProposal = 1;
//         (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
//         vm.startPrank(address(daoMock));
//         assertEq(Law(governorCreateProposalAddress).getConditions(address(daoMock), governorCreateProposal).allowedRole, ROLE_ONE, "Allowed role should be set to ROLE_ONE");
//         assertEq(Law(governorCreateProposalAddress).getExecutions(address(daoMock), governorCreateProposal).powers, address(daoMock), "Powers address should be set correctly");
//         vm.stopPrank();
//     }

//     function testCreateProposal() public {
//         // prep
//         uint16 governorCreateProposal = 1;
//         (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
//         // Create proposal data
//         address[] memory targetsIn = new address[](1);
//         uint256[] memory valuesIn = new uint256[](1);
//         bytes[] memory calldatasIn = new bytes[](1);
//         targetsIn[0] = mockAddresses[2]; // ERC20VotesMock
//         valuesIn[0] = 0;
//         calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

//         lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
//         description = "Create proposal to mint 5000 tokens";

//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         // act
//         vm.prank(alice);
//         daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

//         // assert
//         lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
//         assertEq(
//             GovernorCreateProposal(governorCreateProposalAddress).governorContracts(lawHash),
//             address(governor),
//             "Governor contract should be set correctly"
//         );
//     }

//     function testCreateAndVoteOnProposal() public {
//         // prep
//         uint16 governorCreateProposal = 1;
//         (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
//         // Create proposal data
//         address[] memory targetsIn = new address[](1);
//         uint256[] memory valuesIn = new uint256[](1);
//         bytes[] memory calldatasIn = new bytes[](1);
//         targetsIn[0] = mockAddresses[2];
//         valuesIn[0] = 0;
//         calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

//         lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
//         description = "Create proposal to mint 5000 tokens";

//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         // Create proposal
//         vm.prank(alice);
//         daoMock.request(governorCreateProposal, lawCalldata, nonce, description);

//         // Get proposal ID
//         lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
//         uint256 proposalId = governor.hashProposal(
//             targetsIn,
//             valuesIn,
//             calldatasIn,
//             keccak256(bytes(description))
//         );

//         // Mint voting tokens to alice
//         vm.prank(alice);
//         votingToken.mintVotes(1000);

//         // Fast forward past voting delay
//         vm.warp(block.timestamp + VOTING_DELAY + 1);

//         // Cast vote
//         vm.prank(alice);
//         governor.castVote(proposalId, 1); // 1 = For

//         // Fast forward past voting period
//         vm.warp(block.timestamp + VOTING_PERIOD + 1);

//         // Check vote results
//         (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
//         assertEq(forVotes, 1000, "Votes should be counted correctly");
//         assertEq(againstVotes, 0, "No against votes");
//         assertEq(abstainVotes, 0, "No abstain votes");
//     }

//     function testCreateMultipleProposals() public {
//         // prep
//         uint16 governorCreateProposal = 1;
//         (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
//         vm.prank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);

//         // First proposal
//         address[] memory targets1 = new address[](1);
//         uint256[] memory values1 = new uint256[](1);
//         bytes[] memory calldatas1 = new bytes[](1);
//         targets1[0] = mockAddresses[2];
//         values1[0] = 0;
//         calldatas1[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 1000);

//         lawCalldata = abi.encode(targets1, values1, calldatas1);
//         vm.prank(alice);
//         daoMock.request(governorCreateProposal, lawCalldata, nonce, "First proposal");
//         nonce++;

//         // Second proposal
//         address[] memory targets2 = new address[](1);
//         uint256[] memory values2 = new uint256[](1);
//         bytes[] memory calldatas2 = new bytes[](1);
//         targets2[0] = mockAddresses[2];
//         values2[0] = 0;
//         calldatas2[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 2000);

//         lawCalldata = abi.encode(targets2, values2, calldatas2);
//         vm.prank(alice);
//         daoMock.request(governorCreateProposal, lawCalldata, nonce, "Second proposal");

//         // assert
//         lawHash = LawUtilities.hashLaw(address(daoMock), governorCreateProposal);
//         assertEq(
//             GovernorCreateProposal(governorCreateProposalAddress).governorContracts(lawHash),
//             address(governor),
//             "Governor contract should be set correctly for both proposals"
//         );
//     }

//     function testHandleRequestOutput() public {
//         // prep
//         uint16 governorCreateProposal = 1;
//         (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
//         // Create proposal data
//         address[] memory targetsIn = new address[](1);
//         uint256[] memory valuesIn = new uint256[](1);
//         bytes[] memory calldatasIn = new bytes[](1);
//         targetsIn[0] = mockAddresses[2];
//         valuesIn[0] = 0;
//         calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

//         lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);

//         // act: call handleRequest directly to check its output
//         vm.prank(address(daoMock));
//         (
//             actionId,
//             targets,
//             values,
//             calldatas,
//             stateChange
//         ) = Law(governorCreateProposalAddress).handleRequest(alice, address(daoMock), governorCreateProposal, lawCalldata, nonce);

//         // assert
//         assertEq(targets.length, 1, "Should have one target");
//         assertEq(values.length, 1, "Should have one value");
//         assertEq(calldatas.length, 1, "Should have one calldata");
//         assertEq(targets[0], address(governor), "Target should be the GovernorMock");
//         assertEq(values[0], 0, "Value should be 0");
//         assertNotEq(calldatas[0], "", "Calldata should not be empty");
//         assertEq(stateChange, "", "State change should be empty");
//         assertNotEq(actionId, 0, "Action ID should not be 0");
//     }

//     function testUnauthorizedAccess() public {
//         // prep
//         uint16 governorCreateProposal = 1;
        
//         // Create proposal data
//         address[] memory targetsIn = new address[](1);
//         uint256[] memory valuesIn = new uint256[](1);
//         bytes[] memory calldatasIn = new bytes[](1);
//         targetsIn[0] = mockAddresses[2];
//         valuesIn[0] = 0;
//         calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

//         lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);

//         // Try to create proposal without proper role
//         vm.prank(helen);
//         vm.expectRevert(abi.encodeWithSignature("Powers__AccessDenied()"));
//         daoMock.request(governorCreateProposal, lawCalldata, nonce, "Unauthorized proposal creation");
//     }

//     function testProposalDescriptionFormat() public {
//         // prep
//         uint16 governorCreateProposal = 1;
//         (address governorCreateProposalAddress, , ) = daoMock.getActiveLaw(governorCreateProposal);
        
//         // Create proposal data
//         address[] memory targetsIn = new address[](1);
//         uint256[] memory valuesIn = new uint256[](1);
//         bytes[] memory calldatasIn = new bytes[](1);
//         targetsIn[0] = mockAddresses[2];
//         valuesIn[0] = 0;
//         calldatasIn[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

//         lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);

//         // act: call handleRequest directly to check its output
//         vm.prank(address(daoMock));
//         (
//             actionId,
//             targets,
//             values,
//             calldatas,
//             stateChange
//         ) = Law(governorCreateProposalAddress).handleRequest(alice, address(daoMock), governorCreateProposal, lawCalldata, nonce);

//         // assert
//         // Need to deconstruct abi.encodeWITHSELECTOR. -- I have a solution for this. Somewhere.. 
//         // bytes memory expectedDescription = abi.encodePacked(
//         //     "This is a proposal created in the Powers protocol.\n",
//         //     "To see the proposal, please visit: https://powers-protocol.vercel.app/",
//         //     Strings.toHexString(uint256(uint160(address(daoMock)))),
//         //     "/proposals/",
//         //     Strings.toString(governorCreateProposal)
//         // );

//         // // Extract the description from the calldata
//         // bytes memory proposeCalldata = calldatas[0];
//         // bytes32 descriptionHash = abi.decode(proposeCalldata[proposeCalldata.length - 32:], (bytes32));
//         // assertEq(
//         //     keccak256(abi.encodePacked(expectedDescription)),
//         //     descriptionHash,
//         //     "Proposal description should be formatted correctly"
//         // );
//     }
// } 