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

import { PresetAction } from "../src/laws/executive/PresetAction.sol";

// mocks
import { PowersMock } from "./mocks/PowersMock.sol";
import { Erc1155Mock } from "./mocks/Erc1155Mock.sol";
import { Erc721Mock } from "./mocks/Erc721Mock.sol";
import { Erc20VotesMock } from "./mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "./mocks/Erc20TaxedMock.sol";
import { ConstitutionsMock } from "./mocks/ConstitutionsMock.sol";

// deploy scripts
import { DeployAnvilMocks } from "./mocks/DeployAnvilMocks.s.sol";
import { DeploySeparatedPowers } from "../script/DeploySeparatedPowers.s.sol";

abstract contract TestVariables is PowersErrors, PowersTypes, PowersEvents, LawErrors {
    // protocol and mocks
    Powers powers;
    HelperConfig helperConfig;
    PowersMock daoMock;
    DeployAnvilMocks deployAnvilMocks;
    string[] lawNames;
    address[] lawAddresses;
    string[] mockNames;
    address[] mockAddresses;
    ConstitutionsMock constitutionsMock;
    HelperConfig.NetworkConfig config;
    ILaw.Conditions conditions;
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
    bytes32 lawHash;
    address newLaw;
    uint16 lawId;
    uint16 lawCount; 
    address tokenAddress; 
    bytes32 firstGrantCalldata;
    bytes32 secondGrantCalldata;
    uint16 firstGrantId;
    uint16 secondGrantId;
    uint256 prevActionId;


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

    mapping(address => uint256) taxPaid;
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
    uint256[] milestones;
    uint256[] actionIds;
    string[] testStrings;
}

abstract contract TestHelpers is Test, TestVariables {
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

    function distributeERC20VoteTokens(address[] memory accounts, uint256 randomiser) public {
        uint256 currentRandomiser;
        for (i = 0; i < accounts.length; i++) {
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            uint256 amount = (currentRandomiser % 10_000) + 1;
            vm.startPrank(accounts[i]);
            Erc20VotesMock(mockAddresses[2]).mintVotes(amount);
            Erc20VotesMock(mockAddresses[2]).delegate(accounts[i]); // delegate votes to themselves
            vm.stopPrank();
        }
    }

    function distributeNFTs(address erc721MockLocal, address[] memory accounts, uint256 randomiser, uint256 density)
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
                vm.prank(accounts[i]);
                Erc721Mock(erc721MockLocal).cheatMint(randomiser + i);
            }
        }
    }

    function voteOnProposal(
        address payable dao,
        uint16 lawId,
        uint256 actionIdLocal,
        address[] memory accounts,
        uint256 randomiser,
        uint256 passChance // in percentage
    )
        public
        returns (uint256 roleCountLocal, uint256 againstVoteLocal, uint256 forVoteLocal, uint256 abstainVoteLocal)
    {
        uint256 currentRandomiser;
        for (i = 0; i < accounts.length; i++) {
            // set randomiser..
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            // vote
            if (Powers(dao).canCallLaw(accounts[i], lawId)) {
                roleCountLocal++;
                if (currentRandomiser % 100 >= passChance) {
                    vm.prank(accounts[i]);
                    Powers(dao).castVote(actionIdLocal, 0); // = against
                    againstVoteLocal++;
                } else if (currentRandomiser % 100 < passChance) {
                    vm.prank(accounts[i]);
                    Powers(dao).castVote(actionIdLocal, 1); // = for
                    forVoteLocal++;
                } else {
                    vm.prank(accounts[i]);
                    Powers(dao).castVote(actionIdLocal, 2); // = abstain
                    abstainVoteLocal++;
                }
            }
        }
    }
}

abstract contract BaseSetup is TestVariables, TestHelpers {
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

        // deploy mockk
        deployAnvilMocks = new DeployAnvilMocks();
        daoMock = new PowersMock();
        (lawNames, lawAddresses, mockNames, mockAddresses) = deployAnvilMocks.run(address(daoMock));
        constitutionsMock = new ConstitutionsMock();

    }
}

/////////////////////////////////////////////////////////////////////
//                           TEST SETUPS                           //
/////////////////////////////////////////////////////////////////////

abstract contract TestSetupPowers is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (PowersTypes.LawInitData[] memory lawInitData_) = constitutionsMock.initiatePowersConstitution(
            lawNames,
            lawAddresses,
            mockNames,
            mockAddresses,
            payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_);

        // assign Roles
        vm.roll(block.number + 4000);
        daoMock.request(
            uint16(lawInitData_.length - 1), // should be last selected law. As laws start counting at 1, this should be the last law.
            abi.encode(),
            nonce,
            "assigning roles"
        );
    }
}

abstract contract TestSetupLaw is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (PowersTypes.LawInitData[] memory lawInitData_) = constitutionsMock.initiateLawTestConstitution(
            lawNames,
            lawAddresses,
            mockNames,
            mockAddresses,
            payable(address(daoMock))
        );

        // constitute daoMock.
        daoMock.constitute(lawInitData_);

        // assign Roles
        vm.roll(block.number + 4000);
        daoMock.request(
            uint16(lawInitData_.length - 1),
            abi.encode(),
            nonce, // empty calldata
            "assigning roles"
        );
    }
}

abstract contract TestSetupElectoral is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (PowersTypes.LawInitData[] memory lawInitData_) = constitutionsMock.initiateElectoralTestConstitution(
            lawNames,
            lawAddresses,
            mockNames,
            mockAddresses,
            payable(address(daoMock))
        );
        daoMock.constitute(lawInitData_);

        // // assign Roles
        vm.roll(block.number + 4000);
        daoMock.request(
            uint16(lawInitData_.length - 1),
            abi.encode(),
            nonce,// empty calldata
            "assigning roles"
        );
    }
}

abstract contract TestSetupExecutive is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

       // initiate constitution & get founders' roles list
        (PowersTypes.LawInitData[] memory lawInitData_) = constitutionsMock.initiateExecutiveTestConstitution(
            lawNames,
            lawAddresses,
            mockNames,
            mockAddresses,
            payable(address(daoMock))
        );
        daoMock.constitute(lawInitData_);

        // // assign Roles
        vm.roll(block.number + 4000);
        daoMock.request(
            uint16(lawInitData_.length - 1),
            abi.encode(),
            nonce,// empty calldata
            "assigning roles"
        );
    }
}

abstract contract TestSetupIntegrations is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (PowersTypes.LawInitData[] memory lawInitData_) = constitutionsMock.initiateIntegrationsTestConstitution(
            lawNames,
            lawAddresses,
            mockNames,
            mockAddresses,
            payable(address(daoMock))
        );
        daoMock.constitute(lawInitData_);

        // assign Roles
        // vm.roll(block.number + 4000);
        // daoMock.request(
        //     uint16(lawInitData_.length - 1),
        //     abi.encode(),
        //     nonce,// empty calldata
        //     "assigning roles"
        // );
    }
}


abstract contract TestSetupState is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (PowersTypes.LawInitData[] memory lawInitData_) = constitutionsMock.initiateStateTestConstitution(
            lawNames,
            lawAddresses,
            mockNames,
            mockAddresses,
            payable(address(daoMock))
        );
        daoMock.constitute(lawInitData_);

        // assign Roles
        vm.roll(block.number + 4000);
        daoMock.request(
            uint16(lawInitData_.length - 1),
            abi.encode(),
            nonce,// empty calldata
            "assigning roles"
        );
    }
}

abstract contract TestSetupSeparatedPowers is BaseSetup {
    Powers separatedPowers;

    function setUpVariables() public override {
        super.setUpVariables();

        DeploySeparatedPowers deploySeparatedPowers = new DeploySeparatedPowers();
        address payable separatedPowersAddress = deploySeparatedPowers.run();
        separatedPowers = Powers(separatedPowersAddress);
    }
}

// // abstract contract TestSetupAlignedDao_fuzzIntegration is BaseSetup {
// //     Powers alignedDao;

// //     function setUpVariables() public override {
// //         super.setUpVariables();

// //         DeployAlignedDao deployAlignedDao = new DeployAlignedDao();
// //         (
// //             address payable alignedDaoAddress,
// //             address[] memory laws_,
// //             HelperConfig.NetworkConfig memory config_,
// //             address mock20votes_,
// //             address mock20taxed_,
// //             address mock721_
// //             ) = deployAlignedDao.run();
// //         laws = laws_;
// //         config = config_;

// //         erc20VotesMock = Erc20VotesMock(mock20votes_);
// //         erc20TaxedMock = Erc20TaxedMock(mock20taxed_);
// //         erc721Mock = Erc721Mock(mock721_);
// //         alignedDao = Powers(alignedDaoAddress);
// //     }
// // }

// // abstract contract TestSetupGovernYourTax_fuzzIntegration is BaseSetup {
// //     Powers governYourTax;

// //     function setUpVariables() public override {
// //         super.setUpVariables();

// //         DeployGovernYourTax deployGovernYourTax = new DeployGovernYourTax();
// //         (
// //             address payable governYourTaxAddress,
// //             address[] memory laws_,
// //             HelperConfig.NetworkConfig memory config_,
// //             address mock20Taxed_
// //             ) = deployGovernYourTax.run();
// //         laws = laws_;
// //         config = config_;

// //         erc20TaxedMock = Erc20TaxedMock(mock20Taxed_);

// //         governYourTax = Powers(governYourTaxAddress);
// //     }
// // }
