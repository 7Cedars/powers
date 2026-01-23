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
import { PowersFactory } from "@src/helpers/PowersFactory.sol";
import { ElectionList } from "@src/helpers/ElectionList.sol";


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
    ElectionList electionList;

    // NB: REMOVE BEFORE DEPLOYMENT! 
    address Cedars = 0x328735d26e5Ada93610F0006c32abE2278c46211; 
    // NB: REMOVE BEFORE DEPLOYMENT! 

    uint256 constitutionLength;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string[] inputParams;
    string[] dynamicParams;
    uint16 mandateCount;
    address treasury;
    uint256 constant packageSize = 10;

    function run() external {
        // step 0, setup.
        initialisePowers = new InitialisePowers(); 
        initialisePowers.run();
        helperConfig = new Configurations(); 
        config = helperConfig.getConfig(); 

        // Deploy vanilla DAOs (parent and digital) and DAO factories (for ideas and physical).  
        vm.startBroadcast();
        console2.log("Deploying Vanilla Powers contracts...");
        parentDAO = new Powers(
            "Parent DAO", // name
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreihtpfkpjxianudgvf7pdq7toccccrztvckqpkc3vfnai4x7l3zmme", // uri
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        );

        digitalDAO = new Powers(
            "Digital DAO", // name
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiemrhwiqju7msjxbszlrk73cn5omctzf2xf2jxaenyw7is2r4takm", // uri
            config.maxCallDataLength, // max call data length
            config.maxReturnDataLength, // max return data length
            config.maxExecutionsLength // max executions length
        );

        console2.log("Deploying Helper contracts...");
        soulbound1155 = new Soulbound1155("https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighx6axdemwbjara3xhhfn5yaiktidgljykzx3vsrqtymicxxtgvi");
        electionList = new ElectionList();
        
        vm.stopBroadcast();
        console2.log("Parent DAO deployed at:", address(parentDAO));
        console2.log("Digital DAO deployed at:", address(digitalDAO));
        console2.log("Soulbound1155 deployed at:", address(soulbound1155));
        console2.log("Election List deployed at:", address(electionList));

        // setup Safe treasury. 
        address[] memory owners = new address[](1);
        owners[0] = address(parentDAO);

        vm.startBroadcast();
        console2.log("Setting up Safe treasury for Parent DAO...");
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
        vm.stopBroadcast();
        console2.log("Safe treasury deployed at:", treasury);

        // Deploing Ideas and Physical DAo factories. 
        createIdeasConstitution();
        console2.log("Ideas Constitution, length:", ideasConstitution.length);

        createPhysicalConstitution();
        console2.log("Physical Constitution, length:", physicalConstitution.length);

        // dpeloying subDAO factories.
        console2.log("Deploying DAO factories...");
        vm.startBroadcast();
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
        console2.log("Ideas DAO factory deployed at:", address(ideasDaoFactory));
        console2.log("Physical DAO factory deployed at:", address(physicalDaoFactory));

        console2.log("Creating constitutions...");
        createParentConstitution();
        console2.log("Parent Constitution, length:", parentConstitution.length);
        PowersTypes.MandateInitData[] memory packedParentConstitution = packageInitData(parentConstitution, packageSize, 1); // package size 10 mandates. startId = 1.
        console2.log("Parent Packed Constitution, length:", packedParentConstitution.length);

        createDigitalConstitution();
        console2.log("Digital Constitution, length:", digitalConstitution.length); 
        PowersTypes.MandateInitData[] memory packedDigitalConstitution = packageInitData(digitalConstitution, packageSize, 1); // package size 10 mandates. startId = 1.
        console2.log("Parent Packed Constitution, length:", packedDigitalConstitution.length);

        // step 4: run constitute on vanilla DAOs. 
        vm.startBroadcast();
        console2.log("Constituting Parent DAO and Digital DAO...");
        parentDAO.constitute(packedParentConstitution, msg.sender); // set msg.sender as admin
        vm.stopBroadcast();

        vm.startBroadcast();
        digitalDAO.constitute(packedDigitalConstitution, msg.sender); // set msg.sender as admin
        vm.stopBroadcast();

        // step 5: transfer ownership of factories to parent DAO.
        vm.startBroadcast();
        console2.log("Transferring ownership of DAO factories to Parent DAO...");
        soulbound1155.transferOwnership(address(parentDAO));
        ideasDaoFactory.transferOwnership(address(parentDAO));
        physicalDaoFactory.transferOwnership(address(parentDAO));  
        vm.stopBroadcast();

        // step 6: Unpack mandates 
        uint256 numPackages = (parentConstitution.length + packageSize - 1) / packageSize;
        uint256 numPackagesDig = (digitalConstitution.length + packageSize - 1) / packageSize;

        console2.log("Unpacking %s packages...", numPackages);
        // Execute package mandates (sequentially)
        vm.startBroadcast();
        for (uint256 i = 1; i <= numPackages; i++) {
            parentDAO.request(uint16(i), "", 0, ""); 
        }
  
        for (uint256 j = 1; j <= numPackagesDig; j++) {
            digitalDAO.request(uint16(j), "", 0, ""); 
        }
        vm.stopBroadcast();


        console2.log("Success! All contracts successfully deployed, unpacked and configured.");
    }


    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                        PARENT DAO CONSTITUTION                         //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createParentConstitution() internal {
        mandateCount = 4; // resetting mandate count at 4, because there will be 4 packagedMandate Laws. 
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

        targets = new address[](14);
        values = new uint256[](14);
        calldatas = new bytes[](14);
        
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(parentDAO); 
        }
        targets[11] = treasury; // the Safe treasury address.
        targets[12] = treasury; // the Safe treasury address.

        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Executives");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Physical DAOs");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Ideas DAOs");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Digital DAOs");
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, Cedars);
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, Cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, Cedars);
        calldatas[8] = abi.encodeWithSelector(IPowers.assignRole.selector, 4, Cedars);
        calldatas[9] = abi.encodeWithSelector(IPowers.assignRole.selector, 5, Cedars);
        calldatas[10] = abi.encodeWithSelector(IPowers.setTreasury.selector, treasury);
        calldatas[11] = abi.encodeWithSelector( // cal to set allowance module to the Safe treasury.
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
        calldatas[12] = abi.encodeWithSelector( // call to set Digital DAO as delegate to the Safe treasury.
            Safe.execTransaction.selector,
            config.safeAllowanceModule, // The internal transaction's destination: the Allowance Module.
            0, // The internal transaction's value in this mandate is always 0. To transfer Eth use a different mandate.
            abi.encodeWithSignature(
                "addDelegate(address)", // == AllowanceModule.addDelegate.selector,  (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                address(digitalDAO)
                ),
            0, // operation = Call
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            signature // the signature constructed above
        );
        calldatas[13] = abi.encodeWithSelector(IPowers.revokeMandate.selector, mandateCount + 1); // revoke mandate after use.

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assigns role labels, sets up the allowance module, the treasury and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetActions_Single"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        // CREATE IDEAS DAO // 
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
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Simple"), 
            config: abi.encode(
                address(ideasDaoFactory), // calling the ideas factory
                PowersFactory.createPowers.selector, // function selector to call
                inputParams
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
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_OnReturnValue"), 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.assignRole.selector, // function selector to call
                abi.encode(4), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 1, // parent mandate id (the create Ideas DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // REVOKE IDEAS DAO //
        inputParams = new string[](1); 
        inputParams[0] = "address IdeasDAO";
        
        // Members: Veto Revoke Ideas DAO creation mandate //
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto revoke Ideas DAO: Veto the revoking of an Ideas DAO from Cultural Stewards",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Revoke Ideas DAO (revoke role Id) //  
        mandateCount++;
        conditions.allowedRole = 2; 
        conditions.quorum = 66;
        conditions.succeedAt = 51; 
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); 
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke role Id: Revoke role id 4 (Ideas DAO) from the DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Advanced"), 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.revokeRole.selector, // function selector to call
                abi.encode(4), // params before (role id 4 = Ideas DAOs) // the static params 
                inputParams, // the dynamic params (the address of the created Ideas DAO)
                abi.encode() // no args after 
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // CREATE PHYSICAL DAO //
        inputParams = new string[](2);
        inputParams[0] = "string name";
        inputParams[1] = "string uri";
        // note: an allowance is set when DAO is created. 

        // Ideas DAOs: Initiate Physical DAO creation. Any Ideas DAO can propose creating a Physical DAO. 
        mandateCount++;
        conditions.allowedRole = 4; // = Ideas DAO
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
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Simple"), 
            config: abi.encode(
                physicalDaoFactory, // calling the Physical factory
                PowersFactory.createPowers.selector, // function selector to call
                inputParams
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
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_OnReturnValue"),  
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

        // Executives: Assign Delegate status to Physical DAO //
        mandateCount++;
        conditions.allowedRole = 2; // = Any executive
        conditions.needFulfilled = mandateCount - 2; // need the Physical DAO to have been created.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Assign Delegate status: Assign delegate status at Safe treasury to the Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("Safe_ExecTransaction_OnReturnValue"),  
            config: abi.encode(
                config.safeAllowanceModule, // target contract
                bytes4(0xe71bdf41), // == AllowanceModule.addDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly here)
                abi.encode(), // params before (role id 4 = Ideas DAOs)
                inputParams, // dynamic params (the address of the created Ideas DAO)
                mandateCount - 2, // parent mandate id (the create Physical DAO mandate)
                abi.encode() // no params after
            ),
            conditions: conditions 
        }));
        delete conditions;

        // REVOKE PHYSICAL DAO //
        inputParams = new string[](2); 
        inputParams[0] = "address IdeasDAO";
        inputParams[1] = "bool removeAllowance";

        // members veto revoking physical DAO 
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto revoke Physical DAO: Veto the revoking of an Physical DAO from Cultural Stewards",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Revoke Physical DAO (Revoke Role ID) //
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        conditions.timelock = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 10 minutes timelock before execution.
        conditions.needNotFulfilled = mandateCount - 1; // need the veto to have NOT been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke Role Id: Revoke role Id 3 from Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Advanced"), 
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.revokeRole.selector, // function selector to call
                abi.encode(3), // params before (role id 3 = Physical DAOs) // the static params 
                inputParams, // the dynamic params (the address of the created Ideas DAO)
                abi.encode() // no args after 
            ),
            conditions: conditions 
        }));
        delete conditions; 

        // Executives: Revoke Physical DAO (Revoke Delegate status DAO) //  
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.needFulfilled = mandateCount - 1; // need the assign role to have been fulfilled. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke Delegate status: Revoke delegate status Physical DAO at the Safe treasury", 
            targetMandate: initialisePowers.getMandateAddress("Safe_ExecTransaction"),  
            config: abi.encode(
                inputParams,
                bytes4(0xdd43a79f), // == AllowanceModule.removeDelegate.selector (because the contracts are compiled with different solidity versions we cannot reference the contract directly
                config.safeAllowanceModule // target contract
                ),
            conditions: conditions 
        }));
        delete conditions; 

        // ASSIGN ADDITIONAL ALLOWANCE TO PHYSICAL DAO OR DIGITAL DAO //
        inputParams = new string[](5);
        inputParams[0] = "address Sub-DAO";
        inputParams[1] = "address Token";
        inputParams[2] = "uint96 allowanceAmount";
        inputParams[3] = "uint16 resetTimeMin";
        inputParams[4] = "uint32 resetBaseMin";

        // Physical DAO: Veto additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Physical DAOs
        conditions.quorum = 66; // = 66% quorum needed
        conditions.succeedAt = 66; // = 66% majority needed for veto.
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = number of blocks
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto allowance: Veto setting an allowance to either Digital DAO or a Physical DAO.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Physical DAO: Request additional allowance
        mandateCount++;
        conditions.allowedRole = 3; // = Physical DAOs. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request additional allowance: Any Physical DAO can request an allowance from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Grant Allowance to Physical DAO
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

        // Digital DAO: Request additional allowance
        mandateCount++;
        conditions.allowedRole = 5; // = Digital DAO. 
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request additional allowance: The Digital DAO can request an allowance from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Grant Allowance to Digital DAO
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

        // Members: Veto update URI
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 51; // = 51% majority
        conditions.quorum = 77; // = Note: high threshold.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto update URI: Members can veto updating the Parent DAO URI",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"), 
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Executives: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Executives
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum
        conditions.needNotFulfilled = mandateCount - 1; // the previous VETO mandate should not have been fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Cultural Stewards DAOs",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Simple"), 
            config: abi.encode(
                address(parentDAO), // calling the allowed tokens contract
                IPowers.setUri.selector, // function selector to call
                inputParams
            ),
            conditions: conditions
        }));
        delete conditions;

        // Ideas DAO: Mint Tokens Ideas DAO - ERC 1155 //
        inputParams = new string[](1);
        inputParams[0] = "address To";

        mandateCount++;
        conditions.allowedRole = 4; // = Ideas DAOs
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint token Ideas DAO: Any Ideas DAO can mint new NFTs",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_MintEncodedToken"), 
            config: abi.encode(address(soulbound1155)),
            conditions: conditions
        }));
        delete conditions;

        // Physical DAOs: Mint NFTs Physical DAO - ERC 1155 // 
        mandateCount++;
        conditions.allowedRole = 3; // = Physical DAOs
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint token Physical DAO: Any Physical DAO can mint new NFTs",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_MintEncodedToken"), 
            config: abi.encode(address(soulbound1155)),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Executives. Any executive can call this mandate.
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

        // CLAIM MEMBERSHIP PARENT DAO // -- on the basis of activity token and POAP ownership.  
        // Public: Check ownership POAPS. 
        // insert: all tokens owned.
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request Membership Step 1: 2 POAPS from physical DAO and 20 activity tokens from ideas DAOs needed that are not older than 6 months.",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_GatedAccess"),
            config: abi.encode(
                address(soulbound1155), // soulbound token contract
                type(uint256).max - 1, // assigns a nonsense role Id. This mandate is just to check ownership of tokens.
                3, // checks if token is from address that is a Physical DAO 
                daysToBlocks(180, config.BLOCKS_PER_HOUR), // look back period in blocks = 30 days. 
                2 // number of tokens required
            ),
            conditions: conditions
        }));
        delete conditions;

        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request Membership Step 2: 2 POAPS from physical DAO and 20 activity tokens from ideas DAOs needed that are not older than 6 months.",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_GatedAccess"),
            config: abi.encode(
                address(soulbound1155), // soulbound token contract
                1, // member role Id
                4, // checks if token is from address that is an Ideas DAO
                daysToBlocks(180, config.BLOCKS_PER_HOUR), // look back period in blocks = 30 days.
                20 // number of tokens required
            ),
            conditions: conditions
        }));
        delete conditions;

        // ELECT EXECUTIVES // 
        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Members: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Members (should be Executives according to MD, but code says Members)
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create an election: an election can be initiated be any member.",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Simple"),
            config: abi.encode(
                address(electionList), // election list contract
                ElectionList.createElection.selector, // selector
                inputParams 
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Nominate for Executive election 
        mandateCount++;
        conditions.allowedRole = 1; // = Members (should be Executives according to MD, but code says Members)  
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for election: any member can nominate for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                true // nominate as candidate
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members revoke nomination for Executive election.
        mandateCount++;
        conditions.allowedRole = 1; // = Members (should be Executives according to MD, but code says Members) 
        conditions.needFulfilled = mandateCount - 1; // = Nominate for election
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke nomination for election: any member can revoke their nomination for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                false // revoke nomination
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 3; // = Create election
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Open voting for election: Members can open the vote for an election. This will create a dedicated vote mandate.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_CreateVoteMandate"),
            config: abi.encode(
                address(electionList), // election list contract 
                initialisePowers.getMandateAddress("ElectionList_Vote"), // the vote mandate address
                1, // the max number of votes a voter can cast
                1 // the role Id allowed to vote (Members)
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Members: Tally election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Tally elections: After an election has finished, assign the Executive role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Tally"),
            config: abi.encode(
                address(electionList),
                2, // RoleId for Executives
                5 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: clean up election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Tally election
        parentConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Clean up election: After an election has finished, clean up related mandates.",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_OnReturnValue"),
            config: abi.encode(
                address(parentDAO), // target contract
                IPowers.revokeMandate.selector, // function selector to call
                abi.encode(), // params before
                new string[](0), // dynamic params: none (return value is used directly)
                mandateCount - 2, // parent mandate id (the open vote  mandate)
                abi.encode() // no params after
            ),
            conditions: conditions
        }));
        delete conditions;


        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////

        // ADOPT MANDATE // 
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
            targetMandate: initialisePowers.getMandateAddress("Mandates_Adopt"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions; 
    }


    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                       DIGITAL DAO CONSTITUTION                         //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createDigitalConstitution() internal {
        mandateCount = 2; // resetting mandate count. // there are 2 initial mandates already in the digital DAO.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](7);
        values = new uint256[](7);
        calldatas = new bytes[](7);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, Cedars);
        calldatas[4] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, Cedars);
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, Cedars);
        calldatas[6] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.
        
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetActions_Single"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
        
        // PAYMENT OF RECEIPTS //
        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Public: Submit a receipt (Payment Reimbursement - After Action)
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // This is a public mandate. Anyone can call it.   
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Submit a Receipt: Anyone can submit a receipt for payment reimbursement.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;
        
        // Conveners: OK Receipt (Avoid Spam)
        mandateCount++;
        conditions.allowedRole = 2; // Any convener can ok a receipt.   
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "OK a receipt: Any convener can ok a receipt for payment reimbursement.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Conveners: Approve Payment of Receipt
        mandateCount++;
        conditions.allowedRole = 2; // Conveners 
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Approve payment of receipt: Execute a transaction from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Transfer"),
            config: abi.encode(
                config.safeAllowanceModule,
                address(treasury) 
            ),
            conditions: conditions
        }));
        delete conditions;

        // PAYMENT OF PROJECTS //
        inputParams = new string[](3);
        inputParams[0] = "address Token";
        inputParams[1] = "uint256 Amount";
        inputParams[2] = "address PayableTo";

        // Members: Submit a project (Payment Before Action)
        mandateCount++;
        conditions.allowedRole = 1; // Members can propose a project.   
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 51;
        conditions.quorum = 5; // note the low quorum to encourage proposals.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Submit a project for Funding: Any member can submit a project for funding.",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Conveners: Approve Funding of Project
        mandateCount++;
        conditions.allowedRole = 2; // Conveners 
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 67;
        conditions.quorum = 50;
        conditions.needFulfilled = mandateCount - 1; // need the previous mandate to be fulfilled.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Approve funding of project: Execute a transaction from the Safe Treasury.",
            targetMandate: initialisePowers.getMandateAddress("SafeAllowance_Transfer"),
            config: abi.encode(
                config.safeAllowanceModule,
                address(treasury) 
            ),
            conditions: conditions
        }));
        delete conditions;

        // UPDATE URI // 
        inputParams = new string[](1);
        inputParams[0] = "string newUri";
        
        // Conveners: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum 
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_OnOwnPowers"), 
            config: abi.encode( 
                Powers.setUri.selector, // function selector to call
                inputParams
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners. Any convener can call this mandate.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
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
        
        // ASSIGN MEMBERSHIP // -- on the basis of contributions to website
        // TODO: needs to be configured with github repo details etc. 
        string[] memory paths = new string[](3);
        paths[0] = "documentation"; paths[1] = "frontend"; paths[2] = "solidity"; // can be anything 
        uint256[] memory roleIds = new uint256[](3);
        roleIds[0] = 2; roleIds[1] = 3; roleIds[2] = 4;

        // Public: Apply for member role 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // Public
        conditions.throttleExecution = minutesToBlocks(3, config.BLOCKS_PER_HOUR); // to avoid spamming, the law is throttled. 
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Apply for Member Role: Anyone can claim member roles based on their GitHub contributions to the DAO's repository", // crrently the path is set at Cedars/powers
            targetMandate: initialisePowers.getMandateAddress("Github_ClaimRoleWithSig"), // TODO: needs to be more configurable
            config: abi.encode(
                "develop", // branch
                paths,
                roleIds,
                "signed", // signatureString
                config.chainlinkFunctionsSubscriptionId,
                config.chainlinkFunctionsGasLimit,
                config.chainlinkFunctionsDonId
            ),
            conditions: conditions
        }));
        delete conditions;

        // Public: Claim Member Role
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // Public
        conditions.needFulfilled = mandateCount - 1; // must have applied for member role.
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Claim Member Role: Following a successful initial claim, members can get member role assigned to their account.",
            targetMandate: initialisePowers.getMandateAddress("Github_AssignRoleWithSig"),
            config: abi.encode(), // empty config
            conditions: conditions
        }));
        delete conditions;

        // ELECT CONVENERS // 
        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Members: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create an election: an election can be initiated be any member.",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Simple"),
            config: abi.encode(
                address(electionList), // election list contract
                ElectionList.createElection.selector, // selector
                inputParams 
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Nominate for Convener election 
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for election: any member can nominate for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                true // nominate as candidate
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members revoke nomination for Convener election.
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 1; // = Nominate for election
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke nomination for election: any member can revoke their nomination for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                false // revoke nomination
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 3; // = Create election
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Open voting for election: Members can open the vote for an election. This will create a dedicated vote mandate.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_CreateVoteMandate"),
            config: abi.encode(
                address(electionList), // election list contract 
                initialisePowers.getMandateAddress("ElectionList_Vote"), // the vote mandate address
                1, // the max number of votes a voter can cast
                1 // the role Id allowed to vote (Members)
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Members: Tally election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Tally elections: After an election has finished, assign the Convener role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Tally"),
            config: abi.encode(
                address(electionList),
                2, // RoleId for Conveners
                3 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: clean up election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Tally election
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Clean up election: After an election has finished, clean up related mandates.",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_OnReturnValue"),
            config: abi.encode(
                address(digitalDAO), // target contract
                IPowers.revokeMandate.selector, // function selector to call
                abi.encode(), // params before
                new string[](0), // dynamic params: none
                mandateCount - 2, // parent mandate id (the open vote mandate)
                abi.encode() // no params after
            ),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // ADOPT MANDATES // 
        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Members: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77; 
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Adopting Mandates: Members can initiate adopting new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // ParentDAO: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // ParentDAO 
        conditions.needFulfilled = mandateCount - 1;
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: ParentDAO can veto proposals to adopt new mandates", // TODO: ParentDAO actually does not have a law yet to cast a veto.. 
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needFulfilled = mandateCount - 2;
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        digitalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Conveners can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("Mandates_Adopt"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;
    }


    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                        IDEAS DAO CONSTITUTION                          //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createIdeasConstitution() internal    {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](8);
        values = new uint256[](8);
        calldatas = new bytes[](8);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO");
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, address(parentDAO)); // assign Parent DAO role to Parent DAO address. 
        calldatas[4] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, Cedars);
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, Cedars);
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, Cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.
        
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetActions_Single"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////
         
        // MINT ACTIVITY TOKENS //
        inputParams = new string[](1);
        inputParams[0] = "address To"; 

        // Public: Mint an active ideas token      
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = Public
        conditions.throttleExecution = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // note: the more people try to gain access, the harder it will be to get as supply is fixed. 
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint activity token: Anyone can mint an Active Ideas token. One token is available per 5 minutes.",
            targetMandate: initialisePowers.getMandateAddress("PowersAction_Simple"), 
            config: abi.encode(
                address(parentDAO),
                uint16(25), // = mandate Id Mint token Ideas DAO
                inputParams
                ),
            conditions: conditions
        }));
        delete conditions; 
         
        // REQUEST CREATION NEW PHYSICAL DAO
        inputParams = new string[](2);
        inputParams[0] = "string name";
        inputParams[1] = "string uri";

        // Conveners: request at Parent DAO the creation of a new physical DAO. 
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request new Physical DAO: Conveners can request creation new Physical DAO.",
            targetMandate: initialisePowers.getMandateAddress("PowersAction_Simple"),
            config: abi.encode(
                address(parentDAO), 
                uint16(11), // = mandate Id Request new Physical DAO at Parent DAO - NB! STATIC and very easy to get wrong. 
                inputParams
            ),
            conditions: conditions
        }));
        delete conditions;

        // UPDATE URI // 
        inputParams = new string[](1);
        inputParams[0] = "string newUri";
        
        // Conveners: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum 
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_OnOwnPowers"), 
            config: abi.encode( 
                Powers.setUri.selector, // function selector to call
                inputParams
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners. Any convener can call this mandate.
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
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
        // ASSIGN MEMBERSHIP // -- on the basis of collected tokens from the org. 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request Membership: Anyone can become a member if they have sufficient activity token from the DAO: N tokens during the last M days.",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_GatedAccess"),
            config: abi.encode(
                address(soulbound1155), // soulbound token contract
                1, // member role Id
                0, // checks if token is from address that holds role Id 0 (meaning the admin, which is the DAO itself). 
                5, // number of tokens required
                daysToBlocks(30, config.BLOCKS_PER_HOUR) // look back period in blocks = 30 days. 
            ),
            conditions: conditions
        }));
        delete conditions;

        // ELECT CONVENERS // 
        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Members: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create an election: an election can be initiated be any member.",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Simple"),
            config: abi.encode(
                address(electionList), // election list contract
                ElectionList.createElection.selector, // selector
                inputParams 
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Nominate for Convener election 
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for election: any member can nominate for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                true // nominate as candidate
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members revoke nomination for Convener election.
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 1; // = Nominate for election
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke nomination for election: any member can revoke their nomination for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                false // revoke nomination
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 3; // = Create election
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Open voting for election: Members can open the vote for an election. This will create a dedicated vote mandate.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_CreateVoteMandate"),
            config: abi.encode(
                address(electionList), // election list contract 
                initialisePowers.getMandateAddress("ElectionList_Vote"), // the vote mandate address
                1, // the max number of votes a voter can cast
                1 // the role Id allowed to vote (Members)
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Members: Tally election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Tally elections: After an election has finished, assign the Convener role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Tally"),
            config: abi.encode(
                address(electionList),
                2, // RoleId for Conveners
                3 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: clean up election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Tally election
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Clean up election: After an election has finished, clean up related mandates.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_CleanUpVoteMandate"),
            config: abi.encode(mandateCount - 2), // The create vote mandate)
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // Adopt mandate // 
        inputParams = new string[](2);
        inputParams[0] = "address[] mandates";
        inputParams[1] = "uint256[] roleIds";

        // Members: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = mandateCount - 1;
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: Members can veto proposals to adopt new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(inputParams),
            conditions: conditions
        }));
        delete conditions;

        // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Conveners can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("Mandates_Adopt"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions; 
    }


    ////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////// 
    //                       PHYSICAL DAO CONSTITUTION                        //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    function createPhysicalConstitution() internal {
        mandateCount = 0; // resetting mandate count.
        ////////////////////////////////////////////////////////////////////// 
        //                              SETUP                               // 
        //////////////////////////////////////////////////////////////////////
        // setup role labels //  
        targets = new address[](8);
        values = new uint256[](8);
        calldatas = new bytes[](8);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = address(digitalDAO); 
        }
        calldatas[0] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Members");
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Conveners");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Parent DAO"); 
        calldatas[3] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, address(parentDAO)); // assign Parent DAO role to Parent DAO address.
        calldatas[4] = abi.encodeWithSelector(IPowers.assignRole.selector, 1, Cedars);
        calldatas[5] = abi.encodeWithSelector(IPowers.assignRole.selector, 2, Cedars);
        calldatas[6] = abi.encodeWithSelector(IPowers.assignRole.selector, 3, Cedars);
        calldatas[7] = abi.encodeWithSelector(IPowers.revokeMandate.selector, 1); // revoke mandate 1 after use.
        
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public.
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initial Setup: Assign role labels and revokes itself after execution",
            targetMandate: initialisePowers.getMandateAddress("PresetActions_Single"), 
            config: abi.encode(targets, values, calldatas),
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                      EXECUTIVE MANDATES                          // 
        //////////////////////////////////////////////////////////////////////

        inputParams = new string[](1);
        inputParams[0] = "address To"; 
        
        // Convener: Mint POAP          
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners   
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Mint POAP: Any Convener can mint a POAP.",
            targetMandate: initialisePowers.getMandateAddress("PowersAction_Simple"), 
            config: abi.encode(
                address(parentDAO),
                uint16(26), // mandate Mint token Ideas DAO
                inputParams
                ),
            conditions: conditions
        }));
        delete conditions; 

        // UPDATE URI // 
        inputParams = new string[](1);
        inputParams[0] = "string newUri";

        // Conveners: Update URI
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR); // = 5 minutes / days 
        conditions.succeedAt = 66; // = 2/3 majority
        conditions.quorum = 66; // = 66% quorum 
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Update URI: Set allowed token for Physical DAO",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_OnOwnPowers"), 
            config: abi.encode( 
                Powers.setUri.selector, // function selector to call
                inputParams
            ),
            conditions: conditions
        }));
        delete conditions;

        // TRANSFER TOKENS INTO TREASURY //
        mandateCount++;
        conditions.allowedRole = 2; // = Conveners. Any convener can call this mandate.
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Transfer tokens to treasury: Any tokens accidently sent to the DAO can be recovered by sending them to the treasury",
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
        // ASSIGN MEMBERSHIP // -- on the basis of POAPS. 
        mandateCount++;
        conditions.allowedRole = type(uint256).max; // = public
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Request Membership: Anyone can become a member if they have sufficient activity token from the DAO: N tokens during the last M days.",
            targetMandate: initialisePowers.getMandateAddress("Soulbound1155_GatedAccess"),
            config: abi.encode(
                address(soulbound1155), // soulbound token contract
                1, // member role Id
                0, // checks if token is from address that holds role Id 0 (meaning the admin, which is the DAO itself). 
                1, // number of tokens required. Only one POAP needed for membership.
                daysToBlocks(15, config.BLOCKS_PER_HOUR) // look back period in blocks = 15 days. 
            ),
            conditions: conditions
        }));
        delete conditions;

        // ELECT CONVENERS // 
        inputParams = new string[](3);
        inputParams[0] = "string Title";
        inputParams[1] = "uint48 StartBlock";
        inputParams[2] = "uint48 EndBlock";

        // Members: create election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.throttleExecution = minutesToBlocks(120, config.BLOCKS_PER_HOUR); // = once every 2 hours
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Create an election: an election can be initiated be any member.",
            targetMandate: initialisePowers.getMandateAddress("BespokeAction_Simple"),
            config: abi.encode(
                address(electionList), // election list contract
                ElectionList.createElection.selector, // selector
                inputParams 
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Nominate for Convener election 
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Nominate for election: any member can nominate for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                true // nominate as candidate
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members revoke nomination for Convener election.
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 1; // = Nominate for election
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Revoke nomination for election: any member can revoke their nomination for an election.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Nominate"),
            config: abi.encode(
                address(electionList), // election list contract
                false // revoke nomination
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: Open Vote for election
        mandateCount++;
        conditions.allowedRole = 1; // = Members
        conditions.needFulfilled = mandateCount - 3; // = Create election
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Open voting for election: Members can open the vote for an election. This will create a dedicated vote mandate.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_CreateVoteMandate"),
            config: abi.encode(
                address(electionList), // election list contract 
                initialisePowers.getMandateAddress("ElectionList_Vote"), // the vote mandate address
                1, // the max number of votes a voter can cast
                1 // the role Id allowed to vote (Members)
            ),
            conditions: conditions 
        }));
        delete conditions;

        // Members: Tally election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Open Vote election
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Tally elections: After an election has finished, assign the Convener role to the winners.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_Tally"),
            config: abi.encode(
                address(electionList),
                2, // RoleId for Conveners
                3 // Max role holders
            ),
            conditions: conditions
        }));
        delete conditions;

        // Members: clean up election
        mandateCount++;
        conditions.allowedRole = 1; 
        conditions.needFulfilled = mandateCount - 1; // = Tally election
        ideasConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Clean up election: After an election has finished, clean up related mandates.",
            targetMandate: initialisePowers.getMandateAddress("ElectionList_CleanUpVoteMandate"),
            config: abi.encode(mandateCount - 2), // The create vote mandate)
            conditions: conditions
        }));
        delete conditions;

        ////////////////////////////////////////////////////////////////////// 
        //                        REFORM MANDATES                           // 
        //////////////////////////////////////////////////////////////////////
        
        // ADOPT MANDATES // 
        string[] memory adoptMandatesParams = new string[](2);
        adoptMandatesParams[0] = "address[] mandates";
        adoptMandatesParams[1] = "uint256[] roleIds";

        // Members: initiate Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 1; // Members
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 77;
        conditions.needFulfilled = mandateCount - 1;
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Initiate Adopting Mandates: Members can initiate adopting new mandates",
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // ParentDAO: Veto Adopting Mandates
        mandateCount++;
        conditions.allowedRole = 3; // ParentDAO 
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Veto Adopting Mandates: ParentDAO can veto proposals to adopt new mandates", // TODO: ParentDAO actually does not have a law yet to cast a veto.. 
            targetMandate: initialisePowers.getMandateAddress("StatementOfIntent"),
            config: abi.encode(adoptMandatesParams),
            conditions: conditions
        }));
        delete conditions;

        // Conveners: Adopt Mandates
        mandateCount++;
        conditions.allowedRole = 2; // Conveners
        conditions.needFulfilled = mandateCount - 2;
        conditions.needNotFulfilled = mandateCount - 1;
        conditions.votingPeriod = minutesToBlocks(5, config.BLOCKS_PER_HOUR);
        conditions.succeedAt = 66;
        conditions.quorum = 80;   
        physicalConstitution.push(PowersTypes.MandateInitData({
            nameDescription: "Adopt new Mandates: Conveners can adopt new mandates into the organization",
            targetMandate: initialisePowers.getMandateAddress("Mandates_Adopt"),
            config: abi.encode(),
            conditions: conditions
        }));
        delete conditions;
    }
}
