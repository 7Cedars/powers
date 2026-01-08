// SPDX-License-Identifier: UNLICENSED
// This setup is an adaptation from the Hats protocol test. See //
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// protocol
import { Powers } from "../src/Powers.sol";
import { PowersErrors } from "../src/interfaces/PowersErrors.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { PowersEvents } from "../src/interfaces/PowersEvents.sol";
import { Configurations } from "../script/Configurations.s.sol";
import { TestConstitutions } from "./TestConstitutions.sol";
import { console2 } from "forge-std/console2.sol";

// external contracts
import { SoulboundErc721 } from "../src/helpers/SoulboundErc721.sol";
import { Grant } from "../src/helpers/Grant.sol";
import { OpenElection } from "../src/helpers/OpenElection.sol";
import { TreasurySimple } from "../src/helpers/TreasurySimple.sol";
import { TreasuryPools } from "../src/helpers/TreasuryPools.sol";
import { FlagActions } from "../src/helpers/FlagActions.sol";
import { Nominees } from "../src/helpers/Nominees.sol";

// mocks
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";
import { PowersMock } from "./mocks/PowersMock.sol";
import { SimpleErc20Votes } from "./mocks/SimpleErc20Votes.sol";
import { Erc20Taxed } from "./mocks/Erc20Taxed.sol";

// deploy scripts
import { InitialiseHelpers } from "../script/InitialiseHelpers.s.sol";
import { InitialisePowers } from "../script/InitialisePowers.s.sol";

abstract contract TestVariables is PowersErrors, PowersTypes, PowersEvents {
    // protocol and mocks
    Powers powers;
    Configurations helperConfig;
    PowersMock daoMock;
    InitialiseHelpers initialiseHelpers;
    InitialisePowers initialisePowers;
    string[] mandateNames;
    address[] mandateAddresses;
    string[] helperNames;
    address[] helperAddresses;
    TestConstitutions testConstitutions;
    Configurations.NetworkConfig config;
    PowersTypes.Conditions conditions;
    address powersAddress;
    address[] mandates;
    

    // vote options
    uint8 constant AGAINST = 0;
    uint8 constant FOR = 1;
    uint8 constant ABSTAIN = 2;

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    bytes callData; 
    bytes data; 
    uint256 length; 
    bytes stateChange;
    bytes mandateCalldata;
    bytes mandateCalldataNominate;
    bytes mandateCalldataElect;
    string nameDescription;
    string description;
    bytes inputParams;
    uint256 nonce;
    address helper; 
    bytes localConfig;


    bool active;
    bool supportsInterface; 
    uint256 actionId;
    uint256 expectedActionId;
    uint16 mandateId;
    uint256 actionId1;
    uint256 actionId2;
    uint256 actionId3;
    bytes32 mandateHash;
    address newMandate;
    uint16 mandateCounter;
    address tokenAddress;
    uint256 mintAmount;
    uint256 nftToMint;
    uint256 tokenId;
    address testToken;
    address testToken2;
    bytes32 firstGrantCalldata;
    bytes32 secondGrantCalldata;
    uint16 firstGrantId;
    uint16 secondGrantId;
    uint256 balanceBefore;
    uint256 balanceAfter;
    uint16 roleId;
    address account;
    uint16[] mandateIds;
    address[] accounts;
    address requester;
    address executor;
    string longLabel; 
    string longString; 
    string retrievedName;
    bytes retrievedConfig;
    bytes retrievedParams;


    address nominee1;
    address nominee2;
    address newMember; 
    uint256 membersBefore;
    uint256 membersAfter;
    uint256 amountRoleHolders; 
    address recipient;
    address sender; 

    address[] nominees;
    uint256 roleCount;
    uint256 againstVote;
    uint256 forVote;
    uint256 abstainVote;

    address mandateAddress;
    uint8 quorum;
    uint8 succeedAt;
    uint32 votingPeriod;
    address needFulfilled;
    address needNotFulfilled;
    uint48 timelock;
    uint48 throttleExecution;
    bool quorumReached;
    bool voteSucceeded;
    bytes configBytes;
    bytes inputParamsBytes;
    address blacklistedAccount; 

    // roles
    uint256 constant ADMIN_ROLE = 0;
    uint256 constant PUBLIC_ROLE = type(uint256).max;
    uint256 constant ROLE_ONE = 1;
    uint256 constant ROLE_TWO = 2;
    uint256 constant ROLE_THREE = 3;
    uint256 constant ROLE_FOUR = 4;

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
    bytes CREATE2_FACTORY_BYTECODE;
}

abstract contract TestHelperFunctions is Test, TestVariables {
    function test() public { }

    function hashProposal(address targetMandate, bytes memory mandateCalldataLocal, uint256 nonceLocal)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetMandate, mandateCalldataLocal, nonceLocal)));
    }

    function hashMandate(address targetMandate, uint16 mandateId) public pure virtual returns (bytes32) {
        return keccak256(abi.encode(targetMandate, mandateId));
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
            SimpleErc20Votes(helperAddresses[0]).mintVotes(amount);
            SimpleErc20Votes(helperAddresses[0]).delegate(accountsWithVotes[i]); // delegate votes to themselves
            vm.stopPrank();
        }
    }

    function distributeNfts(
        address powersContract,
        address erc721MockLocal,
        address[] memory accounts,
        uint256 randomiser,
        uint256 density
    ) public {
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
                SoulboundErc721(erc721MockLocal).mintNft(randomiser + i, accounts[i]);
            }
        }
    }

    function voteOnProposal(
        address payable dao,
        uint16 mandateToVoteOn,
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
            if (Powers(dao).canCallMandate(voters[i], mandateToVoteOn)) {
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

    function findMandateAddress(string memory name) internal view returns (address) {
        for (uint256 i = 0; i < mandateNames.length; i++) {
            if (Strings.equal(mandateNames[i], name)) {
                return mandateAddresses[i];
            }
        }
        return address(0);
    }

    function findHelperAddress(string memory name) internal view returns (address) {
        for (uint256 i = 0; i < helperNames.length; i++) {
            if (Strings.equal(helperNames[i], name)) {
                return helperAddresses[i];
            }
        }
        return address(0);
    }
}

abstract contract BaseSetup is TestVariables, TestHelperFunctions {
    function setUp() public virtual {
        vm.roll(block.number + 10);
        setUpVariables();
        // run mandates deploy script here.
    }

    function setUpVariables() public virtual {
        nonce = 123;
        MAX_FUZZ_TARGETS = 5;
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
        initialiseHelpers = new InitialiseHelpers();
        initialisePowers = new InitialisePowers();
        (helperNames, helperAddresses) = initialiseHelpers.getDeployedHelpers();
        (mandateNames, mandateAddresses) = initialisePowers.getDeployedMandates();
        Configurations helperConfig = new Configurations();
        config = helperConfig.getConfig();

        // transfer ownership to daoMock
        vm.startPrank(SoulboundErc721(initialiseHelpers.getHelperAddress("SoulboundErc721")).owner());

        Erc20Taxed( initialiseHelpers.getHelperAddress("Erc20Taxed")).transferOwnership(address(daoMock));
        SoulboundErc721(initialiseHelpers.getHelperAddress("SoulboundErc721")).transferOwnership(address(daoMock));
        TreasuryPools(payable(initialiseHelpers.getHelperAddress("TreasuryPools"))).transferOwnership(address(daoMock));
        TreasurySimple(payable(initialiseHelpers.getHelperAddress("TreasurySimple"))).transferOwnership(address(daoMock));
        FlagActions(initialiseHelpers.getHelperAddress("FlagActions")).transferOwnership(address(daoMock));
        Grant(initialiseHelpers.getHelperAddress("Grant")).transferOwnership(address(daoMock));
        Nominees(initialiseHelpers.getHelperAddress("Nominees")).transferOwnership(address(daoMock));
        OpenElection(initialiseHelpers.getHelperAddress("OpenElection")).transferOwnership(address(daoMock));
        Erc20DelegateElection(initialiseHelpers.getHelperAddress("Erc20DelegateElection")).transferOwnership(address(daoMock));
        vm.stopPrank();

        // deploy constitutions mock
        testConstitutions = new TestConstitutions(mandateNames, mandateAddresses, helperNames, helperAddresses);
    }
}

/////////////////////////////////////////////////////////////////////
//                      TEST SETUPS PROTOCOL                       //
/////////////////////////////////////////////////////////////////////

abstract contract TestSetupPowers is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution
        (PowersTypes.MandateInitData[] memory mandateInitData_) = testConstitutions.powersTestConstitution(payable(address(daoMock)));

        console2.log("Mandate Init Data Length:"); 
        console2.logUint(mandateInitData_.length);

        // constitute daoMock.
        daoMock.constitute(mandateInitData_);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, alice);
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

abstract contract TestSetupMandate is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution
        (PowersTypes.MandateInitData[] memory mandateInitData_) = testConstitutions.mandateTestConstitution(payable(address(daoMock)));

        // constitute daoMock.
        daoMock.constitute(mandateInitData_);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

abstract contract TestSetupAsync is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate multi constitution
        (PowersTypes.MandateInitData[] memory mandateInitData_) = testConstitutions.asyncTestConstitution(payable(address(daoMock)));

        // constitute daoMock.
        daoMock.constitute(mandateInitData_);

        vm.startPrank(address(daoMock));
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

        // Setup OpenElection: add nominees and open election BEFORE constitution
        uint16 electionMandatateId = daoMock.mandateCounter();

        vm.startPrank(address(daoMock));
        OpenElection(helperAddresses[9]).nominate(alice, true);
        OpenElection(helperAddresses[9]).nominate(bob, true);
        OpenElection(helperAddresses[9]).openElection(100, electionMandatateId);
        vm.stopPrank();

        // initiate electoral constitution
        (PowersTypes.MandateInitData[] memory mandateInitData_) = testConstitutions.electoralTestConstitution(payable(address(daoMock)));

        // constitute daoMock.
        daoMock.constitute(mandateInitData_);

        vm.startPrank(address(daoMock));
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
        (PowersTypes.MandateInitData[] memory mandateInitData_) = testConstitutions.executiveTestConstitution(payable(address(daoMock)));

        // constitute daoMock.
        daoMock.constitute(mandateInitData_);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

abstract contract TestSetupIntegrations is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate multi constitution
        (PowersTypes.MandateInitData[] memory mandateInitData_) = testConstitutions.integrationsTestConstitution(payable(address(daoMock)));

        // constitute daoMock.
        daoMock.constitute(mandateInitData_);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ROLE_ONE, alice);
        daoMock.assignRole(ROLE_ONE, bob);
        daoMock.assignRole(ROLE_TWO, charlotte);
        daoMock.assignRole(ROLE_TWO, david);
        vm.stopPrank();
    }
}

/////////////////////////////////////////////////////////////////////
//                  INTEGRATION TEST SETUPS                        //
/////////////////////////////////////////////////////////////////////
 
abstract contract TestSetupHelpers is BaseSetup {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate helpers constitution
        (PowersTypes.MandateInitData[] memory mandateInitData_) = testConstitutions.helpersTestConstitution(payable(address(daoMock)));

        // constitute daoMock.
        daoMock.constitute(mandateInitData_);

        vm.startPrank(address(daoMock));
        daoMock.assignRole(ADMIN_ROLE, alice);
        vm.stopPrank();
    }
}
