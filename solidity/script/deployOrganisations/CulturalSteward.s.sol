// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// scripts 
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { Configurations } from "@script/Configurations.s.sol";
import { InitialisePowers } from "@script/InitialisePowers.s.sol";
import { DeploySetup } from "./DeploySetup.s.sol";

// external protocols 
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { SafeProxyFactory } from "lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";
import { ModuleManager } from "lib/safe-smart-account/contracts/base/ModuleManager.sol";

// powers contracts
import { PowersTypes } from "@src/interfaces/PowersTypes.sol";
import { Powers } from "@src/Powers.sol";
import { IPowers } from "@src/interfaces/IPowers.sol";

// helpers
import { SimpleErc20Votes } from "@mocks/SimpleErc20Votes.sol";
import { Soulbound1155 } from "@src/helpers/Soulbound1155.sol";
import { AllowedTokens } from "@src/helpers/AllowedTokens.sol";
import { PowersFactory } from "@src/helpers/PowersFactory.sol";

/// @title Cultural Stewards DAO - Deployment Script
/// Note: all days are turned into minutes for testing purposes. These should be changed before production deployment: ctrl-f minutesToBlocks -> daysToBlocks.  
contract CulturalStewardsDAO is DeploySetup {
    InitialisePowers initialisePowers;
    Configurations helperConfig;
    Configurations.NetworkConfig public config; 
    PowersTypes.Conditions conditions;

    PowersTypes.MandateInitData[] parentConstitution;
    PowersTypes.MandateInitData[] digitalConstitution;
    PowersTypes.MandateInitData[] ideasConstitution;
    PowersTypes.MandateInitData[] physicalConstitution;

    Powers parentDAO;
    Powers digitalDAO;
    Powers ideasDAO;
    Powers physicalDAO;

    PowersFactory ideasDaoFactory;
    PowersFactory physicalDaoFactory; 
    Soulbound1155 soulbound1155;

    uint256 constitutionLength;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string[] inputParams;
    string[] dynamicParams;
    uint16 mandateCount;
    address treasury;

    function run() external {
        // step 0, setup.
        initialisePowers = new InitialisePowers(); 
        initialisePowers.run();
        helperConfig = new Configurations(); 
        config = helperConfig.getConfig(); 
        soulbound1155 = new Soulbound1155("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi");

        // Create constitutions 
        console2.log("Creating constitutions...");
        constitutionLength = createParentConstitution();
        console2.log("Parent Constitution, length:", constitutionLength);

        constitutionLength = createDigitalConstitution();
        console2.log("Digital Constitution, length:", constitutionLength);

        constitutionLength = createIdeasConstitution();
        console2.log("Ideas Constitution, length:", constitutionLength);

        constitutionLength = createPhysicalConstitution();
        console2.log("Digital Constitution, length:", constitutionLength);

        // Deploy vanilla DAOs (parent and digital) and DAO factories (for ideas and physical).  
        vm.startBroadcast();
        console2.log("Deploying Powers contracts...");
        parentDAO = new Powers(
            "Parent DAO", // name
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibnvjwah2wdgd3fhak3sedriwt5xemjlacmrabt6mrht7f24m5w3i", // uri
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        );

        digitalDAO = new Powers(
            "Digital DAO", // name
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreichqvnlmfgkw2jeqgerae2torhgbcgdomxzqxiymx77yhflpnniii", // uri
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        );

        ideasDaoFactory = new PowersFactory(
            ideasConstitution, // mandate init data
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        ); 

        physicalDaoFactory = new PowersFactory(
            physicalConstitution, // mandate init data
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        ); 
        vm.stopBroadcast();

        console2.log("Parent DAO deployed at:", address(parentDAO));
        console2.log("Digital DAO deployed at:", address(digitalDAO));
        console2.log("Ideas DAO factory deployed at:", address(ideasDaoFactory));
        console2.log("Physical DAO factory deployed at:", address(physicalDaoFactory));

        // HERE NEED TO SETUP SAFE ADDRESSES + ALLOWANCE MODULE! - NOT THROUGH LAW! 
        // step 3: setup Safe treasury + allowance module. 
        console2.log("Setting up Safe treasuries for Parent DAO and Digital DAO...");
        address[] memory owners = new address[](1);
        owners[0] = address(parentDAO);

        treasury = address(
            SafeProxyFactory(config.safeProxyFactory)
                .createProxyWithNonce(
                    config.safeL2Canonical,
                    abi.encodeWithSelector(
                        Safe.setup.selector,
                        owners,
                        1, // threshold
                        address(0), // to
                        "", // data
                        address(0), // fallbackHandler
                        address(0), // paymentToken
                        0, // payment
                        address(0) // paymentReceiver
                    ),
                    1 // = nonce
                )
        );

        // NB! DO NOT FORGET TO SET DIGITAL DAO AS A DELEGATE TO THE SAFE TREASURY!

        // step 3: run constitute on vanilla. 
        vm.startBroadcast();
        console2.log("Constituting Parent DAO and Digital DAO...");
        parentDAO.constitute(parentConstitution);
        digitalDAO.constitute(digitalConstitution);
        vm.stopBroadcast();

        // step 4: transfer ownership of factories to parent DAO.
        vm.startBroadcast();
        console2.log("Transferring ownership of DAO factories to Parent DAO...");
        ideasDaoFactory.transferOwnership(address(parentDAO));
        physicalDaoFactory.transferOwnership(address(parentDAO)); 
        vm.stopBroadcast();

        console2.log("Success! All contracts succefully deployed and configured.");
    }

    function createParentConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup calls //
        // signature for Safe module enabling call
        bytes memory signature = abi.encodePacked(
            uint256(uint160(address(parentDAO))), // r = address of the signer (powers contract)
            uint256(0), // s = 0
            uint8(1) // v = 1 This is a type 1 call. See Safe.sol for details.
        );

        targets = new address[](8);
        values = new uint256[](8);
        calldatas = new bytes[](8);
        
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(parentDAO); 
        }
        targets[6] = address(treasury); // the Safe treasury address.

        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Executives");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Physical DAOs");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Ideas DAOs");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Digital DAOs");
        calldatas[5] = abi.encodeWithSelector(IPowers.setTreasury.selector, payable(treasury));
        calldatas[6] = abi.encodeWithSelector( // cal to set allowance module to the Safe treasury.
            Safe.execTransaction.selector,
            treasury, // The internal transaction's destination
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodeWithSelector( // the call to be executed by the Safe: enabling the module.
                ModuleManager.enableModule.selector,
                config.safeAllowanceModule
            ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        calldatas[7] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.

        mandateCount++;
        conditions.allowedRole = 0; // = admin.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assigns role labels, sets up the allowance module, the treasury and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        // CREATE AND REVOKE IDEAS DAO // 
        inputParams = new string[](2);
        inputParams[0] = "string name";
        inputParams[1] = "string uri";
        // note: no allowance assigned. Ideas DAO do not control assets. 

        // Members: Initiate Ideas DAO creation
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Ideas DAO: Initiate creation of Ideas DAO",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions 
        }));
        delete conditions;

        // Executives: Execute Ideas DAO creation
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create Ideas DAO: Execute Ideas DAO creation",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                ideasDaoFactory, // calling the ideas factory
                PowersFactory.createPowers.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Assign role Id to Ideas DAO // 
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Assign role Id to DAO: Assign role id 4 (Ideas DAO) to the new DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.assignRole.selector, // function selector to call
                abi.encode(uint16(4)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 1, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // Members: Revoke Ideas DAO creation mandate //
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto revoke Ideas DAO: Veto the revoking of an Ideas DAO from Cultural Stewards",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Revoke Role ID //  
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 2; // need the previous mandate to be fulfilled.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke role Id: Revoke role id 4 (Ideas DAO) from the DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.revokeRole.selector, // function selector to call
                abi.encode(uint16(4)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 3, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // CREATE AND REVOKE PHYSICAL DAO //
        inputParams = new string[](3);
        inputParams[0] = "string name";
        inputParams[1] = "string uri";
        // note: an allowance is set when DAO is created. 

        // Members: Initiate Physical DAO creation
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Physical DAO: Initiate creation of Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions 
        }));
        delete conditions;

        // Executives: Execute Physical DAO creation
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create Physical DAO: Execute Physical DAO creation",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                physicalDaoFactory, // calling the Physical factory
                PowersFactory.createPowers.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Assign role Id to Physical DAO //  
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Assign role Id: Assign role Id 3 to Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.assignRole.selector, // function selector to call
                abi.encode(uint16(3)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 1, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Executives: delegate status to Physical DAO in Safe //
        // todo 

        // Members: Revoke Physical DAO creation mandate //
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto revoke Physical DAO: Veto the revoking of an Physical DAO from Cultural Stewards",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Revoke Role ID //
        mandateCount++;
        conditions.allowedRole = 2; 
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 10 minutes timelock before execution.
        conditions.needFulfilled = mandateCount - 2; // need the previous mandate to be fulfilled.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke Physical DAO: Revoke role Id 3 from Physical DAO"
            targetMandate: initialisePowers.getMandateAddress("BespokeActionOnReturnValue"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.revokeRole.selector, // function selector to call
                abi.encode(uint16(3)), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 4, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // TODO: Executives: Revoke Allowance DAO //  
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 5; // = 5% quorum. Note: very low quorum to encourage experimentation.
        conditions.needNotFulfilled = mandateCount - 1; // need the previous mandate to be NOT fulfilled (veto).
        conditions.needFulfilled = mandateCount - 2; // need the assign role to have been fulfilled. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke Physical DAO: PLACEHOLDER - Revoke delegate status at safe", 
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), // should be: BespokeActionOnReturnValue (tbi) 
            config: abi.encode(inputParams),
            conditions: conditions 
        }));
        delete conditions; 

        // ASSIGN ALLOWANCE TO PHYSICAL DAO OR DIGITAL DAO //
        inputParams = new string[](5);
        inputParams[0] = "address DigitalDAO";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";

        mandateCount++;
        conditions.allowedRole = 3; // = Members can veto this call.
        conditions.quorum = 66; // = 66% quorum needed
        conditions.succeedAt = 66; // = 66% majority needed for veto.
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = number of blocks
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto allowance: Veto settin an allowance to either Digital DAO or a Physical DAO.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 3; // = physical DAO. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request additional allowance: Any Physical DAO can request an allowance from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 2; // = Executives.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 2; // = the veto mandate.
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 10 minutes timelock before execution.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Set Allowance: Execute and set allowance for a Physical DAO.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Action"),
            config: abi.encode(
                inputParams,
                bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                config.safeAllowanceModule 
            ),
            conditions: conditions // everythign zero == Only admin can call directly
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 5; // = digital DAO. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request additional allowance: The Digital DAO can request an allowance from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = 2; // = Executives.
        conditions.quorum = 30; // = 30% quorum needed
        conditions.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = number of blocks
        conditions.needFulfilled = mandateCount - 1; // = the proposal mandate.
        conditions.needNotFulfilled = mandateCount - 4; // = the veto mandate.
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 10 minutes timelock before execution.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Set Allowance: Execute and set allowance for the Digital DAO.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Action"),
            config: abi.encode(
                inputParams,
                bytes4(0xbeaeb388), // == AllowanceModule.setAllowance.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                config.safeAllowanceModule 
            ),
            conditions: conditions // everythign zero == Only admin can call directly
        }));
        delete conditions;

        // UPDATE URI // 
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // members: VETO update URI
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto update URI: Members can veto updating the Parent DAO URI",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // executives: update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needNotFulfilled = mandateCount - 1; // the previous VETO mandate should not have been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Cultural Stewards DAOs",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                address(parentDAO), // calling the allowed tokens contract
                Powers.setUri.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Ideas DAOs: MINT NFTS IDEAS DAO - ERC 1155 //
        inputParams = new string[](1);
        inputParams[0] = "address To";

        mandateCount++;
        conditions.allowedRole = 4; // = Ideas DAOs
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint token Ideas DAO: Any Ideas DAO can mint new NFTs",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                address(soulbound1155), // calling the allowed tokens contract
                Soulbound1155.mint.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Physical DAOs: MINT NFTS PHYSICAL DAO - ERC 1155 // 
        mandateCount++;
        conditions.allowedRole = 3; // = Physical DAOs
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint token Physical DAO: Any Physical DAO can mint new NFTs",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                address(soulbound1155), // calling the allowed tokens contract
                Soulbound1155.mint.selector, // function selector to call
                abi.encode(inputParams) // note: same input params as Ideas DAO
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Excutives. Any executive can call this mandate.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the Parent DAO can be recovered by sending them to the treasury",
            targetMandate: initialisePowers.getMandateAddress("Safe_RecoverTokens"), 
            config: abi.encode(
                treasury, // this should be the safe treasury! 
                config.safeAllowanceModule // allowance module address
            ),
            conditions: conditions
        }));
        delete conditions;


        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        //////////////////////////////////////////////////////////////////////

        // CLAIM MEMBERSHIP PARENT DAO // 
        // todo 

        // ELECT EXECUTIVES // 
        // Members: Nominate for Executive role
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for Delegates: Members can nominate themselves for the Token Delegate role.",
            targetMandate: initialisePowers.getMandateAddress("Nominate"),
            config: abi.encode(
                address(openElection)
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Start an election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        condtiions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "Start an election: an election can be initiated be any voter.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionStart"),
            config: abi.encode(
                address(openElection),
                initialisePowers.getMandateAddress("OpenElectionVote"), // Vote mandate address
                minutesToBlocks(10, config.BLOCKS_PER_HOUR), // duration of election 
                1 // Role id that can vote = Members
            ),
            conditions: conditions
        }));
        delete conditions;

        // Mandate 4: End and Tally elections
        mandateCount++;
        conditions.allowedRole = 1; // = Member
        conditions.needFulfilled = mandateCount - 1; // = Start election
        constitution.push(PowersTypes.MandateInitData({
            nameDescription: "End and Tally elections: After an election has finished, assign the Executive role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("OpenElectionEnd"),
            config: abi.encode(
                address(openElection),
                2, // RoleId for Executives
                5 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////

        // Adopt mandate // 
        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Any executive: Propose Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Executives 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate mandate adoption: Any executive can propose adopting new mandates into the organization.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Members: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = mandateCount - 1;
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: Members can veto proposals to adopt new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Physical DAOs: Ok Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // Physical DAO
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 51;
        conditions.quorum = 20;
        conditions.needFulfilled = mandateCount - 2;  
        conditions.needNotFulfilled = mandateCount - 1;  
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Ok adopting Mandates: Ok to adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Ideas DAOs: Ok Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 4; // Ideas DAO
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 51;
        conditions.quorum = 20;
        conditions.needFulfilled = mandateCount - 1;  
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Ok adopting Mandates: Ok to adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Digital DAO: Ok Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 5; // Digital DAO
        conditions.needFulfilled = mandateCount - 1;   
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Ok adopting Mandates: Ok to adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Executives
        conditions.needFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Executives can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("AdoptMandates"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;

        return parentConstitution.length;
    }

    function createDigitalConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](4);
        values = new uint256[](4);
        calldatas = new bytes[](4);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.
        
        mandateCount++;
        conditions.allowedRole = 0; // = admin.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        
        // Payment of receipts // 


        // Payment of projects // 


        // UPDATE URI // 
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // members: VETO update URI
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto update URI: Members can veto updating the Parent DAO URI",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // conveners: update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needNotFulfilled = mandateCount - 1; // the previous VETO mandate should not have been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Cultural Stewards DAOs",
            targetMandate: initialisePowers.getMandateAddress("BespokeActionSimple"), 
            config: abi.encode(
                address(parentDAO), // calling the allowed tokens contract
                Powers.setUri.selector, // function selector to call
                abi.encode(inputParams)
            ),
            conditions: conditions
        }));
        delete conditions;

        
        // TRANSFER TOKENS INTO TREASURY //
   

        ////////////////////////////////////////////////////////////////////// 
        //                      ELECTORAL MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        
        // Assign membership // 

        // Elect Conveners // 


        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // Adopt mandate // 


        // Revoke mandate // 

        return digitalConstitution.length;

    }

    function createIdeasConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](4);
        values = new uint256[](4);
        calldatas = new bytes[](4); 
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.
        
        mandateCount++;
        conditions.allowedRole = 0; // = admin.
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;
        
        return ideasConstitution.length;
    }

    function createPhysicalConstitution() internal returns (uint256 constitutionLength) {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](4);
        values = new uint256[](4);
        calldatas = new bytes[](4);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.

        mandateCount++;
        conditions.allowedRole = 0; // = admin.
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetSingleAction"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;
        
        return physicalConstitution.length;
    }

}
