// // SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

// core protocol
import { Powers} from "../src/Powers.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { DeployLaws } from "./DeployLaws.s.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

// mocks
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

/// @notice core script to deploy a dao
/// Note the {run} function for deploying the dao can be used without changes.
/// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
/// Note the {getFounders} function for setting founders' roles.
contract DeployBasicDao is Script {
    function run()
        external
        returns (
            address payable dao,
            HelperConfig.NetworkConfig memory config,
            address payable mock20votes_
            )
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);
        vm.startBroadcast();
        Powers powers = new Powers(
            "Powers 101",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiebpc5ynyisal3ee426jgpib2vawejibzfgmopjxtmucranjy26py"
        );
        Erc20VotesMock erc20VotesMock = new Erc20VotesMock();
        vm.stopBroadcast();

        dao = payable(address(powers));
        mock20votes_ = payable(address(erc20VotesMock));
        PowersTypes.LawInitData[] memory lawInitData = createConstitution(dao, mock20votes_);

        // constitute dao.
        vm.startBroadcast();
        powers.constitute(lawInitData);
        vm.stopBroadcast();

        return (dao, config, mock20votes_);
    }

    function createConstitution(
        address payable dao_,
        address payable mock20votes_
        ) public returns (PowersTypes.LawInitData[] memory lawInitData) {
        ILaw.Conditions memory conditions;
        lawInitData = new PowersTypes.LawInitData[](8);
        DeployLaws deployLaws = new DeployLaws();
        (, address[] memory lawAddresses) = deployLaws.run();

        // dummy call for preset actions
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        // directSelect
        conditions.allowedRole = type(uint32).max;
        lawInitData[1] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[1],
            config: abi.encode(1), // role that can be assigned
            conditions: conditions,
            description: "A law to select an account to a specific role directly."
        });
        delete conditions;

        // nominateMe
        conditions.allowedRole = type(uint32).max;
        lawInitData[2] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[10],
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "A law for accounts to nominate themselves for a role."
        });
        delete conditions;

        // delegateSelect
        conditions.allowedRole = 1;
        lawInitData[3] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[0],
            config: abi.encode(
                mock20votes_,
                15, // max role holders
                2 // roleId to be elected
            ),
            conditions: conditions,
            description: "A law to select a role by delegated votes."
        });
        delete conditions;

        // proposalOnly
        string[] memory inputParams = new string[](3);
        inputParams[0] = "targets address[]";
        inputParams[1] = "values uint256[]";
        inputParams[2] = "calldatas bytes[]";

        conditions.allowedRole = 3;
        lawInitData[4] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[8],
            config: abi.encode(inputParams),
            conditions: conditions,
            description: "A law to propose a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented."
        });
        delete conditions;

        // OpenAction
        conditions.allowedRole = 2;
        conditions.quorum = 20; // = 30% quorum needed
        conditions.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members
        conditions.votingPeriod = 1200; // = number of blocks
        lawInitData[5] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[6],
            config: abi.encode(), // empty config
            conditions: conditions,
            description: "A law to execute an open action."
        });
        delete conditions;

        // PresetAction
        conditions.allowedRole = 1;
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members
        conditions.votingPeriod = 1200; // = number of blocks
        conditions.needCompleted = 3;
        lawInitData[6] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targets, values, calldatas),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;

        // PresetAction for roles
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) =
            _getRoles(dao_, 7);
        conditions.allowedRole = 0;
        lawInitData[7] = PowersTypes.LawInitData({
            targetLaw: lawAddresses[7],
            config: abi.encode(targetsRoles, valuesRoles, calldatasRoles),
            conditions: conditions,
            description: "A law to execute a preset action."
        });
        delete conditions;
    }

    function _getRoles(address payable dao_, uint16 lawId)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");
        address helen = makeAddr("helen");

        // call to set initial roles
        targets = new address[](13);
        values = new uint256[](13);
        calldatas = new bytes[](13);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }

        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, alice);
        calldatas[1] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, bob);
        calldatas[2] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, charlotte);
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, david);
        calldatas[4] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, eve);
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, frank);
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, gary);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, alice);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, bob);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, charlotte);
        calldatas[10] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, alice);
        calldatas[11] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, bob);
        // revoke law after use
        if (lawId != 0) {
            calldatas[12] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);
        }

        return (targets, values, calldatas);
    }
}
