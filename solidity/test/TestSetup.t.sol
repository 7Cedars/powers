// SPDX-License-Identifier: UNLICENSED
// This setup is an adaptation from the Hats protocol test. See //
pragma solidity ^0.8.26;

import "forge-std/Test.sol";

// protocol
import { Powers } from "../src/Powers.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersErrors } from "../src/interfaces/PowersErrors.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { PowersEvents } from "../src/interfaces/PowersEvents.sol";
import { LawErrors } from "../src/interfaces/LawErrors.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";

import { PresetSingleAction } from "../src/laws/multi/PresetSingleAction.sol";

// external contracts
import { SimpleErc1155 } from "@mocks/SimpleErc1155.sol";
import { SoulboundErc721 } from "@mocks/SoulboundErc721.sol";
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { Erc20Taxed } from "@mocks/Erc20Taxed.sol";
import { Grant } from "@mocks/Grant.sol";

import { TestConstitutions } from "./TestConstitutions.sol";
import { PowersMock } from "./mocks/PowersMock.sol";
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";
import { OpenElection } from "@mocks/OpenElection.sol";
import { Donations } from "@mocks/Donations.sol";
import { FlagActions } from "@mocks/FlagActions.sol";
import { Nominees } from "@mocks/Nominees.sol";

// deploy scripts
import { DeployMocks } from "../script/DeployMocks.s.sol";
import { DeployLaws } from "../script/DeployLaws.s.sol";

abstract contract TestVariables is PowersErrors, PowersTypes, PowersEvents, LawErrors {

    // protocol and mocks
    Powers powers;
    HelperConfig helperConfig;
    PowersMock daoMock;
    DeployMocks deployMocks;
    DeployLaws deployLaws;
    string[] lawNames;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;
    TestConstitutions testConstitutions;
    HelperConfig.NetworkConfig config;
    PowersTypes.Conditions conditions;
    address[] laws;

    // vote options
    uint8 AGAINST;
    uint8 FOR;
    uint8 ABSTAIN;

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    bytes stateChange;
    bytes lawCalldata;
    bytes lawCalldataNominate;
    bytes lawCalldataElect;
    string nameDescription;
    string description;
    bytes inputParams;
    uint256 nonce;
    bool active;
    uint256 actionId;
    uint16 lawId; 
    bytes32 lawHash;
    address newLaw;
    uint16 lawCount;
    address tokenAddress;
    address testToken;
    address testToken2;
    bytes32 firstGrantCalldata;
    bytes32 secondGrantCalldata;
    uint16 firstGrantId;
    uint16 secondGrantId;
    uint16 roleId;
    address account;
    uint16[] lawIds; 
    address[] accounts; 
    address requester;
    address executor;

    address nominee1;
    address nominee2;

    address[] nominees;
    uint256 roleCount;
    uint256 againstVote;
    uint256 forVote;
    uint256 abstainVote;

    address lawAddress;
    uint8 quorum;
    uint8 succeedAt;
    uint32 votingPeriod;
    address needCompleted;
    address needNotCompleted;
    uint48 delayExecution;
    uint48 throttleExecution;
    bool quorumReached;
    bool voteSucceeded;
    bytes configBytes;
    bytes inputParamsBytes;

    // roles
    uint256 ADMIN_ROLE;
    uint256 PUBLIC_ROLE;
    uint256 ROLE_ONE;
    uint256 ROLE_TWO;
    uint256 ROLE_THREE;
    uint256 ROLE_FOUR;

    // users
    address alice;
    address bob;
    address charlotte;
    address david;
    address eve;
    address frank;
    address gary;
    address helen;
    address ian;
    address jacob;
    address kate;
    address lisa;
    address oracle;
    address[] users;

    // list of dao names
    string[] daoNames;

    // loop variables.
    uint256 i;
    uint256 j;

    uint256 taxPaid;
    mapping(address => uint256) taxLogs;
    mapping(address => uint256) votesReceived;
    mapping(address => bool) hasVoted;

    // Common test variables to reduce stack usage
    // uint256[] milestoneDisbursements;
    uint256[] milestoneDisbursements1;
    uint256[] milestoneDisbursements2;
    address[] targetsIn;
    uint256[] valuesIn;
    bytes[] calldatasIn;
    address[] targets1;
    uint256[] values1;
    bytes[] calldatas1;
    address[] targets2;
    uint256[] values2;
    bytes[] calldatas2;
    string uriProposal;
    string uriProposal1;
    string uriProposal2;
    string supportUri;
    Grant.Milestone milestone;
    uint256[] actionIds;
    string[] testStrings;

    // Fuzz test variables
    uint256 MAX_FUZZ_TARGETS;
    uint256 MAX_FUZZ_CALLDATA_LENGTH;
}

abstract contract TestStandalone is Test, TestVariables {
    function test() public {}

    function hashProposal(address targetLaw, bytes memory lawCalldataLocal, uint256 nonceLocal)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldataLocal, nonceLocal)));
    }

    function hashLaw(address targetLaw, uint16 lawId) public pure virtual returns (bytes32) {
        return keccak256(abi.encode(targetLaw, lawId));
    }

    function distributeERC20VoteTokens(address[] memory accountsWithVotes, uint256 randomiser) public {
        uint256 currentRandomiser;
        for (i = 0; i < accountsWithVotes.length; i++) {
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            uint256 amount = (currentRandomiser % 10_000) + 1;
            vm.startPrank(accountsWithVotes[i]);
            SimpleErc20Votes(mockAddresses[0]).mintVotes(amount);
            SimpleErc20Votes(mockAddresses[0]).delegate(accountsWithVotes[i]); // delegate votes to themselves
            vm.stopPrank();
        }
    }

    function distributeNFTs(address powersContract, address erc721MockLocal, address[] memory accounts, uint256 randomiser, uint256 density)
        public
    {
        uint256 currentRandomiser;
        randomiser = bound(randomiser, 10, 100 * 10 ** 18);
        for (i = 0; i < accounts.length; i++) {
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            bool getNft = (currentRandomiser % 100) < density;
            if (getNft) {
                vm.prank(powersContract);
                SoulboundErc721(erc721MockLocal).mintNFT(randomiser + i, accounts[i]);
            }
        }
    }

    function voteOnProposal(
        address payable dao,
        uint16 lawToVoteOn,
        uint256 actionIdLocal,
        address[] memory voters,
        uint256 randomiser,
        uint256 passChance // in percentage
    )
        public
        returns (uint256 roleCountLocal, uint256 againstVoteLocal, uint256 forVoteLocal, uint256 abstainVoteLocal)
    {
        uint256 currentRandomiser;
        for (i = 0; i < voters.length; i++) {
            // set randomiser..
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            // vote
            if (Powers(dao).canCallLaw(voters[i], lawToVoteOn)) {
                roleCountLocal++;
                if (currentRandomiser % 100 >= passChance) {
                    vm.prank(voters[i]);
                    Powers(dao).castVote(actionIdLocal, 0); // = against
                    againstVoteLocal++;
                } else if (currentRandomiser % 100 < passChance) {
                    vm.prank(voters[i]);
                    Powers(dao).castVote(actionIdLocal, 1); // = for
                    forVoteLocal++;
                } else {
                    vm.prank(voters[i]);
                    Powers(dao).castVote(actionIdLocal, 2); // = abstain
                    abstainVoteLocal++;
                }
            }
        }
    }
}

abstract contract BaseSetup is TestVariables, TestStandalone {
    function setUp() public virtual {
        vm.roll(block.number + 10);
        setUpVariables();
        // run laws deploy script here.
    }

    function setUpVariables() public virtual {
        // votes types
        AGAINST = 0;
        FOR = 1;
        ABSTAIN = 2;

        // roles
        ADMIN_ROLE = 0;
        PUBLIC_ROLE = type(uint256).max;
        ROLE_ONE = 1;
        ROLE_TWO = 2;
        ROLE_THREE = 3;
        ROLE_FOUR = 4;

        nonce = 123;
        MAX_FUZZ_TARGETS = 20;
        MAX_FUZZ_CALLDATA_LENGTH = 2000;

        // users
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlotte = makeAddr("charlotte");
        david = makeAddr("david");
        eve = makeAddr("eve");
        frank = makeAddr("frank");
        gary = makeAddr("gary");
        helen = makeAddr("helen");
        ian = makeAddr("ian");
        jacob = makeAddr("jacob");
        kate = makeAddr("kate");
        lisa = makeAddr("lisa");
        oracle = makeAddr("oracle");

        // assign funds
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlotte, 10 ether);
        vm.deal(david, 10 ether);
        vm.deal(eve, 10 ether);
        vm.deal(frank, 10 ether);
        vm.deal(gary, 10 ether);
        vm.deal(helen, 10 ether);
        vm.deal(ian, 10 ether);
        vm.deal(jacob, 10 ether);
        vm.deal(kate, 10 ether);
        vm.deal(lisa, 10 ether);
        vm.deal(oracle, 10 ether);

        users = [alice, bob, charlotte, david, eve, frank, gary, helen, ian, jacob, kate, lisa];

        // deploy mock powers
        daoMock = new PowersMock();

        // deploy external contracts
        deployMocks = new DeployMocks();
        deployLaws = new DeployLaws();
        (mockNames, mockAddresses) = deployMocks.run();
        (lawNames, lawAddresses) = deployLaws.run();

        // transfer ownership to daoMock
        vm.startPrank(SoulboundErc721(mockAddresses[2]).owner());
        Erc20Taxed(mockAddresses[1]).transferOwnership(address(daoMock));
        SoulboundErc721(mockAddresses[2]).transferOwnership(address(daoMock));
        FlagActions(mockAddresses[6]).transferOwnership(address(daoMock));
        Grant(mockAddresses[7]).transferOwnership(address(daoMock));
        Nominees(mockAddresses[8]).transferOwnership(address(daoMock));
        OpenElection(mockAddresses[9]).transferOwnership(address(daoMock));
        Erc20DelegateElection(mockAddresses[10]).transferOwnership(address(daoMock));
        vm.stopPrank();        

        // deploy constitutions mock
        testConstitutions = new TestConstitutions();
    }
}

/////////////////////////////////////////////////////////////////////
//                      TEST SETUPS PROTOCOL                       //
/////////////////////////////////////////////////////////////////////

abstract contract TestSetupPowers is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution  
        (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.powersTestConstitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_);

        vm.startPrank(address(daoMock));
        daoMock.setPayableEnabled(true);
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }  
}

abstract contract TestSetupLaw is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution  
        (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.lawTestConstitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_);

        vm.startPrank(address(daoMock));
        daoMock.setPayableEnabled(true);
        daoMock.assignRole(ROLE_ONE, alice); 
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

abstract contract TestSetupUtilities is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution  
        (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.utilitiesTestConstitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_);

        vm.startPrank(address(daoMock));
        daoMock.setPayableEnabled(true);
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

abstract contract TestSetupElectoral is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate electoral constitution  
        (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.electoralTestConstitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_); 

        vm.startPrank(address(daoMock));
        daoMock.setPayableEnabled(true);
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

abstract contract TestSetupExecutive is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate executive constitution  
        (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.executiveTestConstitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_);

        vm.startPrank(address(daoMock));
        daoMock.setPayableEnabled(true);
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

abstract contract TestSetupMulti is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate multi constitution  
        (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.multiTestConstitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_); 

        vm.startPrank(address(daoMock));
        daoMock.setPayableEnabled(true);
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

/// NB ASYNC LAWS UNIT TESTING TO BE IMPLEMENTED

// abstract contract TestSetupAsync is BaseSetup {
//     function setUpVariables() public override {
//         super.setUpVariables();

//         // transfer ownership of erc721Mock to daoMock
//         vm.startPrank(SoulboundErc721(mockAddresses[2]).owner());
//         SoulboundErc721(mockAddresses[2]).transferOwnership(address(daoMock));
//         vm.stopPrank();

//         // initiate constitution  
//         (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.utilitiesTestConstitution(
//             lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
//         );

//         // constitute daoMock.
//         daoMock.constitute(lawInitData_);

//         // assign initial roles for testing
//         vm.startPrank(address(daoMock));
//         daoMock.assignRole(ROLE_ONE, alice);
//         daoMock.assignRole(ROLE_ONE, bob);
//         daoMock.assignRole(ROLE_TWO, charlotte);
//         daoMock.assignRole(ROLE_TWO, david);
//         vm.stopPrank();
//     }
// }


/////////////////////////////////////////////////////////////////////
//                 TEST SETUPS ORGANISATIONS                       //
/////////////////////////////////////////////////////////////////////

abstract contract TestSetupPowers101 is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate multi constitution  
        (PowersTypes.LawInitData[] memory lawInitData_) = testConstitutions.powers101Constitution(
            lawNames, lawAddresses, mockNames, mockAddresses, payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_); 

        vm.startPrank(address(daoMock));
        daoMock.setPayableEnabled(true);
        daoMock.assignRole(ADMIN_ROLE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_ONE, charlotte);
        daoMock.assignRole(ROLE_ONE, david);
        daoMock.assignRole(ROLE_ONE, eve);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        daoMock.assignRole(ROLE_TWO, eve);
        daoMock.assignRole(ROLE_TWO, frank);
        vm.stopPrank();
    }
}