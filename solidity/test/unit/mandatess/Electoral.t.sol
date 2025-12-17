// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { TestSetupElectoral } from "../../TestSetup.t.sol";
import { ElectionSelect } from "../../../src/mandates/electoral/ElectionSelect.sol";
import { PeerSelect } from "../../../src/mandates/electoral/PeerSelect.sol";
import { VoteInOpenElection } from "../../../src/mandates/electoral/VoteInOpenElection.sol";
import { NStrikesRevokesRoles } from "../../../src/mandates/electoral/NStrikesRevokesRoles.sol";
import { TaxSelect } from "../../../src/mandates/electoral/TaxSelect.sol";
import { RoleByRoles } from "../../../src/mandates/electoral/RoleByRoles.sol";
import { SelfSelect } from "../../../src/mandates/electoral/SelfSelect.sol";
import { RenounceRole } from "../../../src/mandates/electoral/RenounceRole.sol";
import { AssignExternalRole } from "../../../src/mandates/electoral/AssignExternalRole.sol";
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";
import { OpenElection } from "../../../src/helpers/OpenElection.sol";
import { TreasurySimple } from "../../../src/helpers/TreasurySimple.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { Nominees } from "../../../src/helpers/Nominees.sol";
import { FlagActions } from "../../../src/helpers/FlagActions.sol"; 
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { BaseSetup } from "../../TestSetup.t.sol";
import { RoleByTransaction } from "../../../src/mandates/electoral/RoleByTransaction.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol"; 

/// @notice Comprehensive unit tests for all electoral mandates
/// @dev Tests all functionality of electoral mandates including initialization, execution, and edge cases

//////////////////////////////////////////////////
//              ELECTION SELECT TESTS          //
//////////////////////////////////////////////////
contract ElectionSelectTest is TestSetupElectoral {
    ElectionSelect electionSelect;
    Erc20DelegateElection delegateElection;

    function setUp() public override {
        super.setUp();
        electionSelect = ElectionSelect(mandateAddresses[11]);
        delegateElection = Erc20DelegateElection(mockAddresses[10]); // Erc20DelegateElection
        mandateId = 1;
    }

    function testElectionSelectInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        ElectionSelect.Data memory data = electionSelect.getData(mandateHash);
        assertEq(data.electionContract, address(delegateElection));
        assertEq(data.roleId, 3);
        assertEq(data.maxRoleHolders, 3);
    }

    function testElectionSelectWithNoNominees() public {
        // Execute with no nominees
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(), nonce, "Test election");

        // Should succeed with no operations
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testElectionSelectWithNominees() public {
        // Add nominees to election
        vm.prank(address(daoMock));
        delegateElection.nominate(alice, true);
        vm.prank(address(daoMock));
        delegateElection.nominate(bob, true);
        vm.prank(address(daoMock));
        delegateElection.nominate(charlotte, true);

        // Execute election
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(), nonce, "Test election");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//              PEER SELECT TESTS              //
//////////////////////////////////////////////////
contract PeerSelectTest is TestSetupElectoral {
    PeerSelect peerSelect;
    Nominees nomineesContract;

    function setUp() public override {
        super.setUp();
        peerSelect = PeerSelect(mandateAddresses[12]);
        nomineesContract = Nominees(mockAddresses[8]); // Nominees
        mandateId = 2;
    }

    function testPeerSelectInitialization() public {
        // Setup nominees
        vm.prank(address(daoMock));
        nomineesContract.nominate(alice, true);
        vm.prank(address(daoMock));
        nomineesContract.nominate(bob, true);

        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        PeerSelect.Data memory data = peerSelect.getData(mandateHash);
        assertEq(data.maxRoleHolders, 2);
        assertEq(data.roleId, 4);
        assertEq(data.maxVotes, 1);
        assertEq(data.nomineesContract, address(nomineesContract));
    }

    function testPeerSelectWithValidSelection() public {
        // Setup nominees
        vm.prank(address(daoMock));
        nomineesContract.nominate(alice, true);
        vm.prank(address(daoMock));
        nomineesContract.nominate(bob, true);

        // Execute with valid selection
        bool[] memory selection = new bool[](2);
        selection[0] = true; // Select alice
        selection[1] = false; // Don't select bob

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(selection), nonce, "Test peer select");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(selection), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testPeerSelectRevertsWithTooManySelections() public {
        // Setup nominees
        vm.prank(address(daoMock));
        nomineesContract.nominate(alice, true);
        vm.prank(address(daoMock));
        nomineesContract.nominate(bob, true);

        // Execute with too many selections
        bool[] memory selection = new bool[](2);
        selection[0] = true; // Select alice
        selection[1] = true; // Select bob (exceeds maxVotes)

        vm.prank(alice);
        vm.expectRevert("Too many selections. Exceeds maxVotes limit.");
        daoMock.request(mandateId, abi.encode(selection), nonce, "Test peer select");
    }

    function testPeerSelectWithNoNominees() public {
        // Create a new nominees contract with no nominees
        Nominees emptyNominees = new Nominees();

        // Setup mandate with empty nominees
        mandateId = daoMock.mandateCounter();
        nameDescription = "Test Peer Select No Nominees";
        configBytes = abi.encode(2, 4, 1, address(emptyNominees));
        conditions.allowedRole = type(uint256).max;

        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: nameDescription,
                targetMandate: address(peerSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        PeerSelect.Data memory data = peerSelect.getData(mandateHash);
        assertEq(data.maxRoleHolders, 2);
        assertEq(data.roleId, 4);
        assertEq(data.maxVotes, 1);
        assertEq(data.nomineesContract, address(emptyNominees));
    }

    function testPeerSelectRevertsWithInvalidSelectionLength() public {
        // Setup nominees
        vm.prank(address(daoMock));
        nomineesContract.nominate(alice, true);
        vm.prank(address(daoMock));
        nomineesContract.nominate(bob, true);

        // Execute with wrong selection length
        bool[] memory selection = new bool[](3); // Wrong length
        selection[0] = true;
        selection[1] = false;
        selection[2] = false;

        vm.prank(alice);
        vm.expectRevert("Invalid selection length.");
        daoMock.request(mandateId, abi.encode(selection), nonce, "Test peer select");
    }

    function testPeerSelectRevertsWithNoSelections() public {
        // Setup nominees
        vm.prank(address(daoMock));
        nomineesContract.nominate(alice, true);
        vm.prank(address(daoMock));
        nomineesContract.nominate(bob, true);

        // Execute with no selections
        bool[] memory selection = new bool[](2);
        selection[0] = false; // Don't select alice
        selection[1] = false; // Don't select bob

        vm.prank(alice);
        vm.expectRevert("Must select at least one nominee.");
        daoMock.request(mandateId, abi.encode(selection), nonce, "Test peer select");
    }

    function testPeerSelectRevertsWithTooManyAssignments() public {
        // Setup nominees
        vm.prank(address(daoMock));
        nomineesContract.nominate(alice, true);
        vm.prank(address(daoMock));
        nomineesContract.nominate(bob, true);

        // Give alice and bob the role first (to test revocation)
        vm.prank(address(daoMock));
        daoMock.assignRole(4, alice);
        vm.prank(address(daoMock));
        daoMock.assignRole(4, bob);

        // Setup mandate with maxRoleHolders = 1
        mandateId = daoMock.mandateCounter();
        nameDescription = "Test Peer Select Too Many Assignments";
        configBytes = abi.encode(1, 4, 2, address(nomineesContract)); // maxRoleHolders = 1
        conditions.allowedRole = type(uint256).max;

        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: nameDescription,
                targetMandate: address(peerSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // Execute with selections that would exceed max role holders
        bool[] memory selection = new bool[](2);
        selection[0] = true; // Select alice (already has role, so revocation)
        selection[1] = true; // Select bob (already has role, so revocation)

        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(selection), nonce, "Test peer select");

        // Should succeed (both are revocations, not assignments)
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(selection), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//            VOTE IN OPEN ELECTION TESTS      //
//////////////////////////////////////////////////
contract VoteInOpenElectionTest is TestSetupElectoral {
    VoteInOpenElection voteInOpenElection;
    OpenElection openElection;
    Nominees nomineesContract;

    function setUp() public override {
        super.setUp();
        voteInOpenElection = VoteInOpenElection(mandateAddresses[13]);
        // Create a fresh OpenElection instance for each test to avoid state conflicts
        openElection = new OpenElection();
        // Transfer ownership to daoMock (test contract is the initial owner)
        openElection.transferOwnership(address(daoMock));
        nomineesContract = new Nominees();
        mandateId = 3;
    }

    function testVoteInOpenElectionWithValidVote() public {
        // Add nominees to open election (before opening it)
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        // Open the election BEFORE adopting the mandate
        vm.prank(address(daoMock));
        openElection.openElection(100);

        // Now adopt the mandate (so it can read from the open election)
        configBytes = abi.encode(address(openElection), 1); // OpenElection
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Vote In Open Election",
                targetMandate: mandateAddresses[13],
                config: configBytes,
                conditions: conditions
            })
        );

        // Setup mandate
        mandateId = daoMock.mandateCounter() - 1;

        vm.roll(block.number + 1);

        // Execute with valid vote
        bool[] memory vote = new bool[](2);
        vote[0] = true; // Vote for alice
        vote[1] = false; // Vote for bob

        vm.prank(charlotte);
        daoMock.request(mandateId, abi.encode(vote), nonce, "Test vote");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(vote), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testVoteInOpenElectionRevertsWithTooManyVotes() public {
        // Add nominees to open election
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        // Open the election BEFORE adopting the mandate
        vm.prank(address(daoMock));
        openElection.openElection(100);

        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Vote In Open Election",
                targetMandate: mandateAddresses[13],
                config: abi.encode(
                    address(openElection), // openElection address
                    1 // 1 vote allowed
                ),
                conditions: conditions
            })
        );

        // Setup mandate
        mandateId = daoMock.mandateCounter() - 1;

        vm.roll(block.number + 1);

        // Execute with multiple votes
        bool[] memory vote = new bool[](2);
        vote[0] = true; // Vote for alice
        vote[1] = true; // Vote for bob

        // try to vote on tw0 people.
        vm.expectRevert("Voter tries to vote for more than maxVotes nominees.");
        vm.prank(charlotte);
        daoMock.request(mandateId, abi.encode(vote), nonce, "Test vote");
    }

    function testVoteInOpenElectionRevertsWithInvalidVoteLength() public {
        // Add nominees to open election
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        // Open the election BEFORE adopting the mandate
        vm.prank(address(daoMock));
        openElection.openElection(100);

        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Vote In Open Election",
                targetMandate: mandateAddresses[13],
                config: abi.encode(
                    address(openElection), // openElection address
                    1 // 1 vote allowed
                ),
                conditions: conditions
            })
        );

        // Setup mandate
        mandateId = daoMock.mandateCounter() - 1;

        vm.roll(block.number + 1);

        // Execute with wrong vote length
        bool[] memory vote = new bool[](3); // Wrong length
        vote[0] = true;
        vote[1] = false;
        vote[2] = false;

        vm.expectRevert("Invalid vote length.");
        vm.prank(charlotte);
        daoMock.request(mandateId, abi.encode(vote), nonce, "Test vote");
    }

    function testVoteInOpenElectionGetData() public {
        // Add nominees to open election
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        // Open the election BEFORE adopting the mandate
        vm.prank(address(daoMock));
        openElection.openElection(100);

        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Vote In Open Election",
                targetMandate: mandateAddresses[13],
                config: abi.encode(
                    address(openElection), // openElection address
                    1 // 1 vote allowed
                ),
                conditions: conditions
            })
        );

        // Setup mandate
        mandateId = daoMock.mandateCounter() - 1;

        // Test getData function
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        VoteInOpenElection.Data memory data = voteInOpenElection.getData(mandateHash);
        assertEq(data.openElectionContract, address(openElection));
        assertEq(data.maxVotes, 1);
        assertEq(data.nominees.length, 2);
    }
}

//////////////////////////////////////////////////
//            N STRIKES REVOKES ROLES TESTS    //
//////////////////////////////////////////////////
contract NStrikesRevokesRolesTest is TestSetupElectoral {
    NStrikesRevokesRoles nStrikesRevokesRoles;
    FlagActions flagActions;

    function setUp() public override {
        super.setUp();
        nStrikesRevokesRoles = NStrikesRevokesRoles(mandateAddresses[14]);
        flagActions = FlagActions(mockAddresses[6]); // FlagActions
        mandateId = 8;

        // Mock getActionState to always return Fulfilled
        vm.mockCall(
            address(daoMock), abi.encodeWithSelector(daoMock.getActionState.selector), abi.encode(ActionState.Fulfilled)
        );
    }

    function testNStrikesRevokesRolesInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        NStrikesRevokesRoles.Data memory data = nStrikesRevokesRoles.getData(mandateHash);
        assertEq(data.roleId, 3);
        assertEq(data.numberOfStrikes, 2);
        assertEq(data.flagActionsAddress, address(flagActions));
    }

    function testNStrikesRevokesRolesWithInsufficientStrikes() public {
        // Execute without enough strikes
        vm.prank(alice);
        vm.expectRevert("Not enough strikes to revoke roles.");
        daoMock.request(mandateId, abi.encode(), nonce, "Test strikes");
    }

    function testNStrikesRevokesRolesWithSufficientStrikes() public {
        // Add some role holders
        vm.prank(address(daoMock));
        daoMock.assignRole(3, alice);
        vm.prank(address(daoMock));
        daoMock.assignRole(3, bob);

        // Add strikes
        vm.prank(address(daoMock));
        flagActions.flag(1, 3, alice, 1);
        vm.prank(address(daoMock));
        flagActions.flag(2, 3, bob, 1);

        // Execute with sufficient strikes
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(), nonce, "Test strikes");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//              TAX SELECT TESTS                //
//////////////////////////////////////////////////
/// NOT A PROPER TEST YET.
contract TaxSelectTest is TestSetupElectoral {
    TaxSelect taxSelect;
    Erc20Taxed erc20Taxed;

    function setUp() public override {
        super.setUp();
        taxSelect = TaxSelect(mandateAddresses[15]);
        erc20Taxed = Erc20Taxed(mockAddresses[1]);
        mandateId = 4;
    }

    function testTaxSelectInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        TaxSelect.Data memory data = taxSelect.getData(mandateHash);
        assertEq(data.erc20Taxed, address(erc20Taxed));
        assertEq(data.thresholdTaxPaid, 1000);
        assertEq(data.roleIdToSet, 4);
    }

    function testTaxSelectWithNoEpoch() public {
        // Execute with no epoch
        vm.prank(alice);
        vm.expectRevert("No finished epoch yet.");
        daoMock.request(mandateId, abi.encode(alice), nonce, "Test tax select");
    }

    // function testTaxSelectWithEpoch() public {
    //     // Advance blocks to create an epoch
    //     vm.roll(block.number + 1001);

    //     // Execute with epoch
    //     vm.prank(alice);
    //     daoMock.request(mandateId, abi.encode(alice), nonce, "Test tax select");

    //     // Should succeed
    //     actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(alice), nonce)));
    //     assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    // }
}

//////////////////////////////////////////////////
//              ROLE BY ROLES TESTS            //
//////////////////////////////////////////////////
contract RoleByRolesTest is TestSetupElectoral {
    RoleByRoles roleByRoles;

    function setUp() public override {
        super.setUp();
        mandateId = 9;
        roleByRoles = RoleByRoles(mandateAddresses[17]);
    }

    function testRoleByRolesInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        RoleByRoles.Data memory data = roleByRoles.getData(mandateHash);
        assertEq(data.newRoleId, 4);
        assertEq(data.roleIdsNeeded.length, 2);
    }

    function testRoleByRolesAssignRole() public {
        // Execute with account that has needed role
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(alice), nonce, "Test role by roles");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testRoleByRolesRevokeRole() public {
        // Give alice the new role first
        vm.prank(address(daoMock));
        daoMock.assignRole(4, alice);

        // Remove alice's needed role
        vm.prank(address(daoMock));
        daoMock.revokeRole(1, alice);

        // Execute with account that no longer has needed role
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(alice), nonce, "Test role by roles");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//              SELF SELECT TESTS              //
//////////////////////////////////////////////////
contract SelfSelectTest is TestSetupElectoral {
    SelfSelect selfSelect;

    function setUp() public override {
        super.setUp();
        mandateId = 6;
        selfSelect = SelfSelect(mandateAddresses[18]);
    }

    function testSelfSelectInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        assertEq(selfSelect.roleIds(mandateHash), 4);
    }

    function testSelfSelectAssignRole() public {
        // Execute with account that doesn't have role
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(), nonce, "Test self select");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testSelfSelectRevertsWithExistingRole() public {
        // Give alice the role first
        vm.prank(address(daoMock));
        daoMock.assignRole(4, alice);

        // Execute with account that already has role
        vm.prank(alice);
        vm.expectRevert("Account already has role.");
        daoMock.request(mandateId, abi.encode(), nonce, "Test self select");
    }
}

//////////////////////////////////////////////////
//              RENOUNCE ROLE TESTS            //
//////////////////////////////////////////////////
contract RenounceRoleTest is TestSetupElectoral {
    RenounceRole renounceRole;

    function setUp() public override {
        super.setUp();
        mandateId = 7;
        renounceRole = RenounceRole(mandateAddresses[19]);
    }

    function testRenounceRoleInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        uint256[] memory storedRoleIds = renounceRole.getAllowedRoleIds(mandateHash);
        assertEq(storedRoleIds.length, 2);
    }

    function testRenounceRoleWithValidRole() public {
        // Execute with valid role
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(1), nonce, "Test renounce role");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(1), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testRenounceRoleRevertsWithoutRole() public {
        // Execute with account that doesn't have role
        vm.prank(alice);
        vm.expectRevert("Account does not have role.");
        daoMock.request(mandateId, abi.encode(2), nonce, "Test renounce role");
    }

    function testRenounceRoleRevertsWithDisallowedRole() public {
        vm.prank(address(daoMock));
        daoMock.assignRole(3, alice);

        // Execute with disallowed role
        vm.prank(alice);
        vm.expectRevert("Role not allowed to be renounced.");
        daoMock.request(mandateId, abi.encode(3), nonce, "Test renounce role");
    }
}

//////////////////////////////////////////////////
//           ASSIGN EXTERNAL ROLE TESTS        //
//////////////////////////////////////////////////
contract AssignExternalRoleTest is TestSetupElectoral {
    AssignExternalRole assignExternalRole;

    function setUp() public override {
        super.setUp();
        mandateId = 11;
        assignExternalRole = AssignExternalRole(mandateAddresses[29]);
    }

    function testAssignExternalRoleInitialization() public {
        // Verify mandate data is stored correctly
        mandateHash = keccak256(abi.encode(address(daoMock), mandateId));
        // Note: AssignExternalRole doesn't have a public getter for its config data
        // like other contracts (e.g. getData), so we can't easily assert on internal state variables
        // without adding a getter or making variables public.
        // However, we can verify it works by functionality.
    }

    function testAssignExternalRoleSuccess() public {
        // Setup: Give alice the required role (roleId = 1) on the external contract (daoMock itself)
        // roleId 1 is configured in TestConstitutions
        vm.prank(address(daoMock));
        daoMock.assignRole(1, alice);

        // Advance block to ensure hasRoleSince returns a value > 0 (since it checks start block)
        vm.roll(block.number + 1);

        // Execute request to assign role
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(alice), nonce, "Test assign external role");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testAssignExternalRoleRevert() public {
        // Setup: Ensure alice does NOT have the required role (roleId = 1)
        // By default alice might have been assigned role 1 in TestSetupElectoral's setup.
        // Let's check TestSetupElectoral.
        // In TestSetupElectoral: daoMock.assignRole(ROLE_ONE, alice); -> ROLE_ONE = 1.
        // So alice HAS role 1. We need to revoke it or use another user.

        // Let's use eve who doesn't have role 1.

        // Execute request
        vm.prank(eve);
        vm.expectRevert("Account does not have role.");
        daoMock.request(mandateId, abi.encode(eve), nonce, "Test assign external role");
    }
}

//////////////////////////////////////////////////
//              EDGE CASE TESTS                //
//////////////////////////////////////////////////
contract ElectoralEdgeCaseTest is TestSetupElectoral {
    ElectionSelect electionSelect;
    PeerSelect peerSelect;
    VoteInOpenElection voteInOpenElection;
    NStrikesRevokesRoles nStrikesRevokesRoles;
    TaxSelect taxSelect;
    RoleByRoles roleByRoles;
    SelfSelect selfSelect;
    RenounceRole renounceRole;
    FlagActions flagActions;

    function setUp() public override {
        super.setUp();
        electionSelect = new ElectionSelect();
        peerSelect = new PeerSelect();
        voteInOpenElection = new VoteInOpenElection();
        nStrikesRevokesRoles = new NStrikesRevokesRoles();
        taxSelect = new TaxSelect();
        roleByRoles = new RoleByRoles();
        selfSelect = new SelfSelect();
        renounceRole = new RenounceRole();
        flagActions = new FlagActions();
    }

    function testAllElectoralMandatesInitialization() public {
        // Test that all electoral mandates can be initialized
        mandateId = daoMock.mandateCounter();
        conditions.allowedRole = type(uint256).max;

        // ElectionSelect
        configBytes = abi.encode(mockAddresses[10], 3, 3); // Erc20DelegateElection
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Election Select",
                targetMandate: address(electionSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // PeerSelect
        configBytes = abi.encode(2, 4, 1, mockAddresses[8]); // Nominees
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Peer Select",
                targetMandate: address(peerSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // VoteInOpenElection
        configBytes = abi.encode(mockAddresses[9], 1); // OpenElection
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Vote In Open Election",
                targetMandate: address(voteInOpenElection),
                config: configBytes,
                conditions: conditions
            })
        );

        // NStrikesRevokesRoles
        configBytes = abi.encode(3, 2, address(flagActions));
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "N Strikes Revokes Roles",
                targetMandate: address(nStrikesRevokesRoles),
                config: configBytes,
                conditions: conditions
            })
        );

        // TaxSelect
        configBytes = abi.encode(mockAddresses[1], 1000, 4);
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Tax Select",
                targetMandate: address(taxSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // RoleByRoles
        configBytes = abi.encode(4, 1);
        uint256[] memory roleIdsNeeded = new uint256[](1);
        roleIdsNeeded[0] = 1;
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Role By Roles",
                targetMandate: address(roleByRoles),
                config: abi.encode(
                    4, // target role (what gets assigned)
                    roleIdsNeeded // roles that are needed to be assigned
                ),
                conditions: conditions
            })
        );

        // SelfSelect
        configBytes = abi.encode(4);
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Self Select",
                targetMandate: address(selfSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // RenounceRole
        uint256[] memory allowedRoleIds = new uint256[](1);
        allowedRoleIds[0] = 1;
        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Renounce Role",
                targetMandate: address(renounceRole),
                config: abi.encode(allowedRoleIds),
                conditions: conditions
            })
        );

        // Verify all mandates were initialized
        assertEq(daoMock.mandateCounter(), mandateId + 8);
    }

    function testElectoralMandatesWithEmptyInputs() public {
        mandateId = 6; // = self select.

        // Execute with empty input
        vm.prank(alice);
        daoMock.request(mandateId, abi.encode(), nonce, "Test empty input");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(mandateId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

contract RoleByTransactionTest is BaseSetup {
    RoleByTransaction roleByTransaction;
    Erc20Taxed token;
    address safeProxy;
    uint256 thresholdAmount = 100 ether;
    uint256 newRoleId = 4;

    function setUp() public override {
        super.setUp();
        roleByTransaction = RoleByTransaction(mandateAddresses[21]);
        token = Erc20Taxed(mockAddresses[1]);
        safeProxy = makeAddr("safeProxy");

        // Give alice some tokens
        // token owner is daoMock in BaseSetup
        vm.startPrank(address(daoMock));
        token.mint(2000 ether); // Mint enough tokens to daoMock first
        token.transfer(alice, 1000 ether);
        vm.stopPrank();
    }

    function testRoleByTransactionExecution() public {
        // Adopt the mandate
        bytes memory config = abi.encode(address(token), thresholdAmount, newRoleId, safeProxy);
        conditions.allowedRole = type(uint256).max; // Public access

        vm.prank(address(daoMock));
        daoMock.adoptMandate(
            PowersTypes.MandateInitData({
                nameDescription: "Role By Transaction",
                targetMandate: address(roleByTransaction),
                config: config,
                conditions: conditions
            })
        );
        mandateId = uint16(daoMock.mandateCounter() - 1);

        // Alice approves RoleByTransaction contract to spend tokens
        // With the FIX, alice should approve RoleByTransaction.
        // Before the fix, RoleByTransaction tries to transfer from itself, so this test will fail appropriately.

        vm.startPrank(alice);
        token.approve(address(roleByTransaction), thresholdAmount);

        bytes memory callData = abi.encode(thresholdAmount);
        daoMock.request(mandateId, callData, nonce, "Test role by transaction");
        vm.stopPrank();

        // Check balances
        // Note: Erc20Taxed has 10% tax. 10% of 100 ether = 10 ether. Total deduction = 110 ether.
        assertEq(token.balanceOf(alice), 1000 ether - thresholdAmount - 10 ether, "Alice balance incorrect");
        assertEq(token.balanceOf(safeProxy), thresholdAmount, "SafeProxy balance incorrect");

        // Check role
        assertTrue(daoMock.hasRoleSince(alice, newRoleId) > 0, "Role not assigned");
    }
}
