// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol"; 
import {IPowers} from "../../interfaces/IPowers.sol"; 
import {PowersTypes} from "../../interfaces/PowersTypes.sol";
import {Powers} from "../../Powers.sol";
import {LawUtilities} from "../../libraries/LawUtilities.sol"; 
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import {BespokeActionSimple} from "../executive/BespokeActionSimple.sol";
import {TreasuryPools} from "../../helpers/TreasuryPools.sol";

/**
 * @title TreasuryPoolsGovernance
 * @notice Law B: Adopts the standard 3 governance laws (Propose, Veto, Execute Transfer) for a Treasury Pool
 * after it was created by a Law A action (e.g., via a law that calls TreasuryPools.createPool).
 * @dev Reads the poolId from the stored return data of the pool creation action (Law A).
 * @dev Reads the managerRoleId from the original input calldata of the pool creation action (Law A).
 * @dev Condition `needFulfilled` must point to the specific Law A instance.
 */
contract TreasuryPoolsGovernance is Law {

    /// @dev Configuration for this law adoption law. Includes addresses of base laws to adopt.
    struct ConfigData {
        address treasuryPools; // The TreasuryPools contract
        address statementOfIntentAddress; // Address of the deployed StatementOfIntent law contract
        address bespokeActionSimpleAddress; // Address of the deployed BespokeActionSimple law contract
        uint16 createPoolLawId; // The Law ID of the *specific instance* of the law that creates the pool
    }

    /// @dev Mapping law hash => configuration.
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;

    // --- Powers Constants ---
    uint256 public constant PUBLIC_ROLE = type(uint256).max;
    uint256 public constant MEMBER_ROLE = 5; // Assuming Role 5 is 'Members' as per PowerBase spec

    // State memory accumulator to avoid stack too deep errors
    struct Mem {
        uint256 createPoolActionId;
        uint16 sourceActionLawId;
        uint48 sourceActionFulfilledAt;
        bytes createPoolActionReturnData;
        uint256 poolId;
        bytes createPoolActionCalldata;
        uint256 managerRoleId;
        uint16 counter;
        uint16 proposeLawId;
        uint16 vetoLawId;
        uint16 executeLawId;
        string proposeName;
        string vetoName;
        string executeName;
        string[] transferInputParams;
        bytes encodedParams;
        PowersTypes.Conditions proposeCondition;
        PowersTypes.Conditions vetoCondition;
        PowersTypes.Conditions executeCondition;
        PowersTypes.LawInitData proposeLawData;
        PowersTypes.LawInitData vetoLawData;
        PowersTypes.LawInitData executeLawData;
        bytes executeConfig;
    }

    /// @notice Error if the referenced action ID is invalid or not fulfilled.
    error InvalidSourceAction();
    /// @notice Error decoding pool ID from source action return data.
    error CannotDecodePoolId();
    /// @notice Error decoding original inputs (managerRoleId) from source action calldata.
    error CannotDecodeSourceInputs();
     /// @notice Error if the law instance is not configured.
    error LawNotConfigured();

    /// @notice Standard initializer for Powers laws.
    /// @param index The unique index assigned by Powers.sol.
    /// @param nameDescription A human-readable description.
    /// @param inputParams ABI encoded string[] describing required inputs for execute.
    /// @param config Abi.encode(address treasuryPools, address soi, address bespoke, uint16 createPoolLawId).
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams, // Expected: abi.encode(string[]("uint256 createPoolActionId"))
        bytes memory config
    ) public override {
        // Ensure config data is provided
        if (config.length == 0) revert("Config required");
        (
            address treasuryPoolsAddress_,
            address statementOfIntentAddress_,
            address bespokeActionSimpleAddress_,
            uint16 createPoolLawId_
        ) = abi.decode(config, (address, address, address, uint16));

        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);

        inputParams = abi.encode("uint256 createPoolActionId"); 

        lawConfig[lawHash_] = ConfigData({
            treasuryPools: treasuryPoolsAddress_,
            statementOfIntentAddress: statementOfIntentAddress_,
            bespokeActionSimpleAddress: bespokeActionSimpleAddress_,
            createPoolLawId: createPoolLawId_
        });

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Prepares the calls to adopt the three governance laws.
    /// @param caller The original caller (not used).
    /// @param powers The address of the Powers contract instance.
    /// @param lawId The ID of this specific law instance.
    /// @param lawCalldata ABI encoded input data: abi.encode(uint256 createPoolActionId).
    /// @param nonce A unique nonce for replay protection.
    /// @return actionId Unique ID for this action proposal.
    /// @return targets Array containing the Powers address three times.
    /// @return values Array containing 0 three times.
    /// @return calldatas Array containing the three encoded calls to Powers.adoptLaw.
    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata, // Contains createPoolActionId
        uint256 nonce
    ) public view override returns (
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) {
        bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
        ConfigData memory config_ = lawConfig[lawHash_];
        if(config_.treasuryPools == address(0)) revert LawNotConfigured();
        Mem memory m;

        (m.createPoolActionId) = abi.decode(lawCalldata, (uint256));

        // --- Fetch and Validate Source Action (Pool Creation Action) ---
        (m.sourceActionLawId, , , m.sourceActionFulfilledAt, , , ) = IPowers(powers).getActionData(m.createPoolActionId);

        // Check if action exists, is fulfilled, and came from the correct law type
        if (
            m.sourceActionLawId != config_.createPoolLawId ||
            m.sourceActionFulfilledAt == 0 
        ) {
            revert InvalidSourceAction();
        }

        // --- Decode necessary data ---
        m.createPoolActionReturnData = IPowers(powers).getActionReturnData(m.createPoolActionId, 0);
        (m.poolId) = abi.decode(m.createPoolActionReturnData, (uint256));
        if(m.poolId == 0) revert CannotDecodePoolId();

        m.createPoolActionCalldata = IPowers(powers).getActionCalldata(m.createPoolActionId);
        (,,m.managerRoleId) = abi.decode(m.createPoolActionCalldata, (address, uint256, uint256));


        // --- Predict the upcoming Law IDs ---
        m.counter = Powers(payable(powers)).lawCounter();
        m.proposeLawId = m.counter;
        m.vetoLawId = m.counter + 1;
        m.executeLawId = m.counter + 2; 

        // --- Prepare LawData for the 3 new laws ---

        // 1. Propose Transfer Law (StatementOfIntent)
        m.proposeName = string.concat("Pool ", Strings.toString(m.poolId), ": Propose Transfer");
        m.transferInputParams = new string[](2);
        m.transferInputParams[0] = "address to";
        m.transferInputParams[1] = "uint256 amount";
        m.encodedParams = abi.encode(m.transferInputParams); 
        
        m.proposeCondition.allowedRole = PUBLIC_ROLE; // Anyone can propose
        m.proposeCondition.votingPeriod = 100; // Blocks, example:  
        m.proposeCondition.succeedAt = 51;        // Example: 51% needed to pass
        m.proposeCondition.quorum = 10;           // Example: 10% participation needed
 
        m.proposeLawData = PowersTypes.LawInitData({
            targetLaw: config_.statementOfIntentAddress,
            nameDescription: m.proposeName,
            config: m.encodedParams,
            conditions: m.proposeCondition
        });

        // 2. Veto Transfer Law (StatementOfIntent)
        m.vetoName = string.concat("Pool ", Strings.toString(m.poolId), ": Veto Transfer");
        m.vetoCondition.allowedRole = MEMBER_ROLE; // Members can veto
        m.vetoCondition.votingPeriod = 100; // Blocks, example
        m.vetoCondition.succeedAt = 66;        // Example: Higher threshold to veto
        m.vetoCondition.quorum = 25;           // Example: Higher quorum to veto
        m.vetoCondition.needFulfilled = m.proposeLawId; // Must fulfill the propose law first

        m.vetoLawData = PowersTypes.LawInitData({
            targetLaw: config_.statementOfIntentAddress,
            nameDescription: m.vetoName,
            config: m.encodedParams, // Same config structure as propose
            conditions: m.vetoCondition
        });

        // 3. Execute Transfer Law (BespokeActionSimple)
        m.executeName = string.concat("Pool ", Strings.toString(m.poolId), ": Execute Transfer");
        string[] memory b_inputParams = new string[](3);
        b_inputParams[0] = "uint256 poolId";
        b_inputParams[1] = "address to";
        b_inputParams[2] = "uint256 amount";

        m.executeConfig = abi.encode(
            config_.treasuryPools, 
            TreasuryPools.transfer.selector,
            b_inputParams
        );

        m.executeCondition.allowedRole = m.managerRoleId; // Use roleId from Law A's input
        m.executeCondition.needFulfilled = m.proposeLawId;    // Propose must pass
        m.executeCondition.needNotFulfilled = m.vetoLawId;     // Veto must NOT pass
  
        m.executeLawData = PowersTypes.LawInitData({
            targetLaw: config_.bespokeActionSimpleAddress,
            nameDescription: m.executeName,
            config: m.executeConfig,
            conditions: m.executeCondition
        });

        // --- Prepare the calls to Powers.adoptLaw ---
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(3);
        targets[0] = targets[1] = targets[2] = powers;
        values[0] = values[1] = values[2] = 0;
        calldatas[0] = abi.encodeWithSelector(IPowers.adoptLaw.selector, m.proposeLawData);
        calldatas[1] = abi.encodeWithSelector(IPowers.adoptLaw.selector, m.vetoLawData);
        calldatas[2] = abi.encodeWithSelector(IPowers.adoptLaw.selector, m.executeLawData);

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        // Powers.fulfill will execute these calls
        return (actionId, targets, values, calldatas);
    }

     /// @notice Retrieves the config data for a given factory law instance.
    function getConfigData(address powers, uint16 lawId) external view returns (ConfigData memory) {
         bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
         if(lawConfig[lawHash_].treasuryPools == address(0)) revert LawNotConfigured();
        return lawConfig[lawHash_];
    }
}
