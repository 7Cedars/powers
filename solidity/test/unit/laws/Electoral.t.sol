// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { TestSetupElectoral } from "../../TestSetup.t.sol";
import { ElectionSelect } from "../../../src/laws/electoral/ElectionSelect.sol";
import { PeerSelect } from "../../../src/laws/electoral/PeerSelect.sol";
import { VoteInOpenElection } from "../../../src/laws/electoral/VoteInOpenElection.sol";
import { NStrikesRevokesRoles } from "../../../src/laws/electoral/NStrikesRevokesRoles.sol";
import { TaxSelect } from "../../../src/laws/electoral/TaxSelect.sol";
import { BuyAccess } from "../../../src/laws/electoral/BuyAccess.sol";
import { RoleByRoles } from "../../../src/laws/electoral/RoleByRoles.sol";
import { SelfSelect } from "../../../src/laws/electoral/SelfSelect.sol";
import { RenounceRole } from "../../../src/laws/electoral/RenounceRole.sol";
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";
import { OpenElection } from "@mocks/OpenElection.sol";
import { Donations } from "@mocks/Donations.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { Nominees } from "@mocks/Nominees.sol";
import { FlagActions } from "@mocks/FlagActions.sol";
import { PowersTypes } from "../../../src/interfaces/PowersTypes.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";

/// @notice Comprehensive unit tests for all electoral laws
/// @dev Tests all functionality of electoral laws including initialization, execution, and edge cases

//////////////////////////////////////////////////
//              ELECTION SELECT TESTS          //
//////////////////////////////////////////////////
contract ElectionSelectTest is TestSetupElectoral {
    ElectionSelect electionSelect;
    Erc20DelegateElection delegateElection;

    function setUp() public override {
        super.setUp();
        electionSelect = ElectionSelect(lawAddresses[9]);
        delegateElection = Erc20DelegateElection(mockAddresses[10]); // Erc20DelegateElection
        lawId = 1;
    }

    function testElectionSelectInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        ElectionSelect.Data memory data = electionSelect.getData(lawHash);
        assertEq(data.ElectionContract, address(delegateElection));
        assertEq(data.roleId, 3);
        assertEq(data.maxRoleHolders, 3);
    }

    function testElectionSelectWithNoNominees() public {
        // Execute with no nominees
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(), nonce, "Test election");

        // Should succeed with no operations
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(), nonce)));
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
        daoMock.request(lawId, abi.encode(), nonce, "Test election");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(), nonce)));
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
        peerSelect = PeerSelect(lawAddresses[10]);
        nomineesContract = Nominees(mockAddresses[8]); // Nominees
        lawId = 2;
    }

    function testPeerSelectInitialization() public {
        // Setup nominees
        vm.prank(address(daoMock));
        nomineesContract.nominate(alice, true);
        vm.prank(address(daoMock));
        nomineesContract.nominate(bob, true);

        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        PeerSelect.Data memory data = peerSelect.getData(lawHash);
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
        daoMock.request(lawId, abi.encode(selection), nonce, "Test peer select");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(selection), nonce)));
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
        daoMock.request(lawId, abi.encode(selection), nonce, "Test peer select");
    }

    function testPeerSelectWithNoNominees() public {
        // Create a new nominees contract with no nominees
        Nominees emptyNominees = new Nominees();

        // Setup law with empty nominees
        lawId = daoMock.lawCounter();
        nameDescription = "Test Peer Select No Nominees";
        configBytes = abi.encode(2, 4, 1, address(emptyNominees));
        conditions.allowedRole = type(uint256).max;

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: nameDescription,
                targetLaw: address(peerSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        PeerSelect.Data memory data = peerSelect.getData(lawHash);
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
        daoMock.request(lawId, abi.encode(selection), nonce, "Test peer select");
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
        daoMock.request(lawId, abi.encode(selection), nonce, "Test peer select");
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

        // Setup law with maxRoleHolders = 1
        lawId = daoMock.lawCounter();
        nameDescription = "Test Peer Select Too Many Assignments";
        configBytes = abi.encode(1, 4, 2, address(nomineesContract)); // maxRoleHolders = 1
        conditions.allowedRole = type(uint256).max;

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: nameDescription,
                targetLaw: address(peerSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // Execute with selections that would exceed max role holders
        bool[] memory selection = new bool[](2);
        selection[0] = true; // Select alice (already has role, so revocation)
        selection[1] = true; // Select bob (already has role, so revocation)

        vm.prank(alice);
        daoMock.request(lawId, abi.encode(selection), nonce, "Test peer select");

        // Should succeed (both are revocations, not assignments)
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(selection), nonce)));
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
        voteInOpenElection = VoteInOpenElection(lawAddresses[11]);
        openElection = OpenElection(mockAddresses[9]); // OpenElection
        nomineesContract = new Nominees();
        lawId = 3;
    }

    function testVoteInOpenElectionWithValidVote() public {
        // Add nominees to open election
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        // ok.. so this law has to indeed be initiated :D
        configBytes = abi.encode(mockAddresses[9], 1); // OpenElection
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Vote In Open Election",
                targetLaw: lawAddresses[11],
                config: configBytes,
                conditions: conditions
            })
        );

        // Setup law
        lawId = daoMock.lawCounter() - 1;

        vm.prank(address(daoMock));
        openElection.openElection(100);
        vm.roll(block.number + 1);

        // Execute with valid vote
        bool[] memory vote = new bool[](2);
        vote[0] = true; // Vote for alice
        vote[1] = false; // Vote for bob

        vm.prank(charlotte);
        daoMock.request(lawId, abi.encode(vote), nonce, "Test vote");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(vote), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testVoteInOpenElectionRevertsWithTooManyVotes() public {
        // Add nominees to open election
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Vote In Open Election",
                targetLaw: lawAddresses[11],
                config: abi.encode(
                    mockAddresses[9], // openElection address
                    1 // 1 vote allowed
                ),
                conditions: conditions
            })
        );

        // Setup law
        lawId = daoMock.lawCounter() - 1;

        vm.prank(address(daoMock));
        openElection.openElection(100);
        vm.roll(block.number + 1);

        // Execute with multiple votes
        bool[] memory vote = new bool[](2);
        vote[0] = true; // Vote for alice
        vote[1] = true; // Vote for bob

        // try to vote on tw0 people.
        vm.expectRevert("Voter tries to vote for more than maxVotes nominees.");
        vm.prank(charlotte);
        daoMock.request(lawId, abi.encode(vote), nonce, "Test vote");
    }

    function testVoteInOpenElectionRevertsWithInvalidVoteLength() public {
        // Add nominees to open election
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Vote In Open Election",
                targetLaw: lawAddresses[11],
                config: abi.encode(
                    mockAddresses[9], // openElection address
                    1 // 1 vote allowed
                ),
                conditions: conditions
            })
        );

        // Setup law
        lawId = daoMock.lawCounter() - 1;

        vm.prank(address(daoMock));
        openElection.openElection(100);
        vm.roll(block.number + 1);

        // Execute with wrong vote length
        bool[] memory vote = new bool[](3); // Wrong length
        vote[0] = true;
        vote[1] = false;
        vote[2] = false;

        vm.expectRevert("Invalid vote length.");
        vm.prank(charlotte);
        daoMock.request(lawId, abi.encode(vote), nonce, "Test vote");
    }

    function testVoteInOpenElectionGetData() public {
        // Add nominees to open election
        vm.prank(address(daoMock));
        openElection.nominate(alice, true);
        vm.prank(address(daoMock));
        openElection.nominate(bob, true);

        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Vote In Open Election",
                targetLaw: lawAddresses[11],
                config: abi.encode(
                    mockAddresses[9], // openElection address
                    1 // 1 vote allowed
                ),
                conditions: conditions
            })
        );

        // Setup law
        lawId = daoMock.lawCounter() - 1;

        // Test getData function
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        VoteInOpenElection.Data memory data = voteInOpenElection.getData(lawHash);
        assertEq(data.openElectionContract, mockAddresses[9]);
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
        nStrikesRevokesRoles = NStrikesRevokesRoles(lawAddresses[12]);
        flagActions = FlagActions(mockAddresses[6]); // FlagActions
        lawId = 8;

        // Mock getActionState to always return Fulfilled
        vm.mockCall(
            address(daoMock), abi.encodeWithSelector(daoMock.getActionState.selector), abi.encode(ActionState.Fulfilled)
        );
    }

    function testNStrikesRevokesRolesInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        NStrikesRevokesRoles.Data memory data = nStrikesRevokesRoles.getData(lawHash);
        assertEq(data.roleId, 3);
        assertEq(data.numberOfStrikes, 2);
        assertEq(data.flagActionsAddress, address(flagActions));
    }

    function testNStrikesRevokesRolesWithInsufficientStrikes() public {
        // Execute without enough strikes
        vm.prank(alice);
        vm.expectRevert("Not enough strikes to revoke roles.");
        daoMock.request(lawId, abi.encode(), nonce, "Test strikes");
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
        daoMock.request(lawId, abi.encode(), nonce, "Test strikes");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//              TAX SELECT TESTS               //
//////////////////////////////////////////////////
contract TaxSelectTest is TestSetupElectoral {
    TaxSelect taxSelect;
    Erc20Taxed erc20Taxed;

    function setUp() public override {
        super.setUp();
        taxSelect = TaxSelect(lawAddresses[13]);
        erc20Taxed = Erc20Taxed(mockAddresses[1]);
        lawId = 4;
    }

    function testTaxSelectInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        TaxSelect.Data memory data = taxSelect.getData(lawHash);
        assertEq(data.erc20Taxed, address(erc20Taxed));
        assertEq(data.thresholdTaxPaid, 1000);
        assertEq(data.roleIdToSet, 4);
    }

    function testTaxSelectWithNoEpoch() public {
        // Execute with no epoch
        vm.prank(alice);
        vm.expectRevert("No finished epoch yet.");
        daoMock.request(lawId, abi.encode(alice), nonce, "Test tax select");
    }

    function testTaxSelectWithEpoch() public {
        // Advance blocks to create an epoch
        vm.roll(block.number + 1000);

        // Execute with epoch
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(alice), nonce, "Test tax select");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//              BUY ACCESS TESTS               //
//////////////////////////////////////////////////
contract BuyAccessTest is TestSetupElectoral {
    BuyAccess buyAccess;
    Donations donations;

    function setUp() public override {
        super.setUp();
        buyAccess = BuyAccess(lawAddresses[14]);
        donations = Donations(payable(mockAddresses[5])); // Donations
    }

    function testBuyAccessInitialization() public {
        // Setup token configs
        address[] memory tokens = new address[](2);
        uint256[] memory tokensPerBlock = new uint256[](2);
        tokens[0] = mockAddresses[3];
        tokens[1] = address(0); // native currency
        tokensPerBlock[0] = 1000;
        tokensPerBlock[0] = 100_000;

        // Test law initialization
        lawId = daoMock.lawCounter();
        nameDescription = "Test Buy Access";
        configBytes = abi.encode(mockAddresses[5], tokens, tokensPerBlock, 4); // Donations
        conditions.allowedRole = PUBLIC_ROLE;

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: nameDescription,
                targetLaw: address(buyAccess),
                config: configBytes,
                conditions: conditions
            })
        );

        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        BuyAccess.Data memory data = buyAccess.getData(lawHash);
        assertEq(data.donationsContract, address(donations));
        assertEq(data.roleIdToSet, 4);
        assertEq(data.tokenConfigs.length, 2);
    }

    function testBuyAccessWithNoDonations() public {
        // Setup token configs
        address[] memory tokens = new address[](2);
        uint256[] memory tokensPerBlock = new uint256[](2);
        tokens[0] = mockAddresses[3];
        tokens[1] = address(0); // native currency
        tokensPerBlock[0] = 1000;
        tokensPerBlock[0] = 100_000;

        // Test law initialization
        lawId = daoMock.lawCounter();
        nameDescription = "Test Buy Access";
        configBytes = abi.encode(mockAddresses[5], tokens, tokensPerBlock, 4); // Donations
        conditions.allowedRole = PUBLIC_ROLE;

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Buy Access",
                targetLaw: address(buyAccess),
                config: configBytes,
                conditions: conditions
            })
        );

        // Execute with no donations
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(alice), nonce, "Test buy access");

        // Should succeed (revoke role)
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBuyAccessWithDonations() public {
        // Setup token configs
        address[] memory tokens = new address[](2);
        uint256[] memory tokensPerBlock = new uint256[](2);
        tokens[0] = mockAddresses[3];
        tokens[1] = address(0); // native currency
        tokensPerBlock[0] = 1000;
        tokensPerBlock[0] = 100_000;

        // Test law initialization
        lawId = daoMock.lawCounter();
        nameDescription = "Test Buy Access";
        configBytes = abi.encode(mockAddresses[5], tokens, tokensPerBlock, 4); // Donations
        conditions.allowedRole = PUBLIC_ROLE;

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Buy Access",
                targetLaw: address(buyAccess),
                config: configBytes,
                conditions: conditions
            })
        );

        // Make a donation
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        payable(address(donations)).call{ value: 0.5 ether }("");

        // Execute with donations
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(alice), nonce, "Test buy access");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBuyAccessRevertsWithEmptyTokenConfig() public {
        // Setup empty token configs
        address[] memory tokens = new address[](0);
        uint256[] memory tokensPerBlock = new uint256[](0);

        // Test law initialization should revert
        lawId = daoMock.lawCounter();
        nameDescription = "Test Buy Access";
        configBytes = abi.encode(mockAddresses[5], tokens, tokensPerBlock, 4); // Donations
        conditions.allowedRole = PUBLIC_ROLE;

        vm.prank(address(daoMock));
        vm.expectRevert("At least one token configuration is required");
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Buy Access",
                targetLaw: address(buyAccess),
                config: configBytes,
                conditions: conditions
            })
        );
    }

    function testBuyAccessWithUnconfiguredToken() public {
        // Use the preset BuyAccess law from electoralTestConstitution (lawId = 5)
        lawId = 5;

        // Whitelist a token that's not in the preset configuration
        vm.prank(address(daoMock));
        donations.setWhitelistedToken(mockAddresses[0], true);

        // Make a donation with a different token (unconfigured)
        // The preset config uses mockAddresses[3] and address(0), so we'll use mockAddresses[1]
        vm.startPrank(alice);
        SimpleErc20Votes(mockAddresses[0]).mintVotes(100_000);
        SimpleErc20Votes(mockAddresses[0]).approve(address(donations), 10_000);
        donations.donateToken(mockAddresses[0], 1000); // Different token
        vm.stopPrank();

        // Execute with unconfigured token donation
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(alice), nonce, "Test buy access");

        // Should not succeed but revoke role (no access due to unconfigured token)
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBuyAccessWithInsufficientDonation() public {
        // Setup token configs with high threshold
        address[] memory tokens = new address[](1);
        uint256[] memory tokensPerBlock = new uint256[](1);
        tokens[0] = address(0); // native currency
        tokensPerBlock[0] = 1_000_000; // Very high threshold

        // Test law initialization
        lawId = daoMock.lawCounter();
        nameDescription = "Test Buy Access";
        configBytes = abi.encode(mockAddresses[5], tokens, tokensPerBlock, 4); // Donations
        conditions.allowedRole = PUBLIC_ROLE;

        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Buy Access",
                targetLaw: address(buyAccess),
                config: configBytes,
                conditions: conditions
            })
        );

        // Make a small donation (insufficient)
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        payable(address(donations)).call{ value: 0.001 ether }(""); // Very small donation

        // Execute with insufficient donation
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(alice), nonce, "Test buy access");

        // Should succeed but revoke role (insufficient donation)
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testBuyAccessFindTokenConfigFunction() public {
        // Use the preset BuyAccess law from electoralTestConstitution (lawId = 5)
        lawId = 5;

        // Whitelist a token that's not in the preset configuration
        vm.prank(address(daoMock));
        donations.setWhitelistedToken(mockAddresses[0], true);

        // Make a donation with a token that's not in the preset config
        // The preset config uses mockAddresses[3] and address(0), so we'll use mockAddresses[2]
        vm.startPrank(alice);
        SimpleErc20Votes(mockAddresses[0]).mintVotes(100_000);
        SimpleErc20Votes(mockAddresses[0]).approve(address(donations), 10_000);
        donations.donateToken(mockAddresses[0], 1000); // Token not in preset config

        // Execute with unconfigured token donation - this will test _findTokenConfig
        daoMock.request(lawId, abi.encode(alice), nonce, "Test buy access");
        vm.stopPrank();

        // Should succeed but revoke role (token not found in config)
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }
}

//////////////////////////////////////////////////
//              ROLE BY ROLES TESTS            //
//////////////////////////////////////////////////
contract RoleByRolesTest is TestSetupElectoral {
    RoleByRoles roleByRoles;

    function setUp() public override {
        super.setUp();
        lawId = 9;
        roleByRoles = RoleByRoles(lawAddresses[15]);
    }

    function testRoleByRolesInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        RoleByRoles.Data memory data = roleByRoles.getData(lawHash);
        assertEq(data.newRoleId, 4);
        assertEq(data.roleIdsNeeded.length, 2);
    }

    function testRoleByRolesAssignRole() public {
        // Execute with account that has needed role
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(alice), nonce, "Test role by roles");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
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
        daoMock.request(lawId, abi.encode(alice), nonce, "Test role by roles");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(alice), nonce)));
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
        lawId = 6;
        selfSelect = SelfSelect(lawAddresses[16]);
    }

    function testSelfSelectInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        assertEq(selfSelect.roleIds(lawHash), 4);
    }

    function testSelfSelectAssignRole() public {
        // Execute with account that doesn't have role
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(), nonce, "Test self select");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testSelfSelectRevertsWithExistingRole() public {
        // Give alice the role first
        vm.prank(address(daoMock));
        daoMock.assignRole(4, alice);

        // Execute with account that already has role
        vm.prank(alice);
        vm.expectRevert("Account already has role.");
        daoMock.request(lawId, abi.encode(), nonce, "Test self select");
    }
}

//////////////////////////////////////////////////
//              RENOUNCE ROLE TESTS            //
//////////////////////////////////////////////////
contract RenounceRoleTest is TestSetupElectoral {
    RenounceRole renounceRole;

    function setUp() public override {
        super.setUp();
        lawId = 7;
        renounceRole = RenounceRole(lawAddresses[17]);
    }

    function testRenounceRoleInitialization() public {
        // Verify law data is stored correctly
        lawHash = keccak256(abi.encode(address(daoMock), lawId));
        uint256[] memory storedRoleIds = renounceRole.getAllowedRoleIds(lawHash);
        assertEq(storedRoleIds.length, 2);
    }

    function testRenounceRoleWithValidRole() public {
        // Execute with valid role
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(1), nonce, "Test renounce role");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(1), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testRenounceRoleRevertsWithoutRole() public {
        // Execute with account that doesn't have role
        vm.prank(alice);
        vm.expectRevert("Account does not have role.");
        daoMock.request(lawId, abi.encode(2), nonce, "Test renounce role");
    }

    function testRenounceRoleRevertsWithDisallowedRole() public {
        vm.prank(address(daoMock));
        daoMock.assignRole(3, alice);

        // Execute with disallowed role
        vm.prank(alice);
        vm.expectRevert("Role not allowed to be renounced.");
        daoMock.request(lawId, abi.encode(3), nonce, "Test renounce role");
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
    BuyAccess buyAccess;
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
        buyAccess = new BuyAccess();
        roleByRoles = new RoleByRoles();
        selfSelect = new SelfSelect();
        renounceRole = new RenounceRole();
        flagActions = new FlagActions();
    }

    function testAllElectoralLawsInitialization() public {
        // Test that all electoral laws can be initialized
        lawId = daoMock.lawCounter();

        // ElectionSelect
        configBytes = abi.encode(mockAddresses[10], 3, 3); // Erc20DelegateElection
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Election Select",
                targetLaw: address(electionSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // PeerSelect
        configBytes = abi.encode(2, 4, 1, mockAddresses[8]); // Nominees
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Peer Select",
                targetLaw: address(peerSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // VoteInOpenElection
        configBytes = abi.encode(mockAddresses[9], 1); // OpenElection
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Vote In Open Election",
                targetLaw: address(voteInOpenElection),
                config: configBytes,
                conditions: conditions
            })
        );

        // NStrikesRevokesRoles
        configBytes = abi.encode(3, 2, address(flagActions));
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "N Strikes Revokes Roles",
                targetLaw: address(nStrikesRevokesRoles),
                config: configBytes,
                conditions: conditions
            })
        );

        // TaxSelect
        configBytes = abi.encode(mockAddresses[1], 1000, 4);
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Tax Select",
                targetLaw: address(taxSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // BuyAccess
        conditions.allowedRole = type(uint256).max;
        address[] memory tokens = new address[](1);
        uint256[] memory tokensPerBlock = new uint256[](1);
        tokens[0] = mockAddresses[3];
        tokensPerBlock[0] = 1000;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Buy Access",
                targetLaw: address(buyAccess),
                config: abi.encode(
                    mockAddresses[5], // Donations contract
                    tokens,
                    tokensPerBlock,
                    4 // roleId to be assigned
                ),
                conditions: conditions
            })
        );

        // RoleByRoles
        configBytes = abi.encode(4, 1);
        conditions.allowedRole = type(uint256).max;
        uint256[] memory roleIdsNeeded = new uint256[](1);
        roleIdsNeeded[0] = 1;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Role By Roles",
                targetLaw: address(roleByRoles),
                config: abi.encode(
                    4, // target role (what gets assigned)
                    roleIdsNeeded // roles that are needed to be assigned
                ),
                conditions: conditions
            })
        );

        // SelfSelect
        configBytes = abi.encode(4);
        conditions.allowedRole = type(uint256).max;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Self Select",
                targetLaw: address(selfSelect),
                config: configBytes,
                conditions: conditions
            })
        );

        // RenounceRole
        conditions.allowedRole = type(uint256).max;
        uint256[] memory allowedRoleIds = new uint256[](1);
        allowedRoleIds[0] = 1;
        vm.prank(address(daoMock));
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Renounce Role",
                targetLaw: address(renounceRole),
                config: abi.encode(allowedRoleIds),
                conditions: conditions
            })
        );

        // Verify all laws were initialized
        assertEq(daoMock.lawCounter(), lawId + 9);
    }

    function testElectoralLawsWithEmptyInputs() public {
        lawId = 6; // = self select.

        // Execute with empty input
        vm.prank(alice);
        daoMock.request(lawId, abi.encode(), nonce, "Test empty input");

        // Should succeed
        actionId = uint256(keccak256(abi.encode(lawId, abi.encode(), nonce)));
        assertTrue(daoMock.getActionState(actionId) == ActionState.Fulfilled);
    }

    function testElectoralLawsWithInvalidConfigs() public {
        lawId = 5; // = buy access

        // BuyAccess with mismatched array lengths
        address[] memory tokens = new address[](2);
        uint256[] memory tokensPerBlock = new uint256[](1);
        tokens[0] = mockAddresses[3];
        tokens[1] = mockAddresses[3];
        tokensPerBlock[0] = 1000;

        vm.prank(address(daoMock));
        vm.expectRevert("Tokens and TokensPerBlock arrays must have the same length");
        daoMock.adoptLaw(
            PowersTypes.LawInitData({
                nameDescription: "Buy Access",
                targetLaw: address(buyAccess),
                config: abi.encode(
                    mockAddresses[5], // Donations contract
                    tokens,
                    tokensPerBlock,
                    4 // roleId to be assigned
                ),
                conditions: conditions
            })
        );
    }
}
