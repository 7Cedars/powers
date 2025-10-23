// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol"; 
import {IPowers} from "../../interfaces/IPowers.sol"; 
import {PowersTypes} from "../../interfaces/PowersTypes.sol";
import {Powers} from "../../Powers.sol";
import {LawUtilities} from "../../libraries/LawUtilities.sol"; 
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AlloRPFGGovernance
 * @notice Law B: Adopts the standard 3 governance laws (Propose, Veto, Execute Payout) for an EasyRPGF pool
 * after it was created by a Law A action (e.g., via CreateEasyRPGFPool.sol).
 * @dev Reads the poolId from the stored return data of the pool creation action (Law A).
 * @dev Reads the managerRoleId from the original input calldata of the pool creation action (Law A).
 * @dev Condition `needFulfilled` must point to the specific Law A instance.
 */
contract AlloRPFGGovernance is Law {

    /// @dev Configuration for this law adoption law. Includes addresses of base laws to adopt.
    struct ConfigData {
        address allo; // Needed to configure AlloDistribute
        address statementOfIntentAddress; // Address of the deployed StatementOfIntent law contract
        address alloDistributeAddress; // Address of the deployed AlloDistribute law contract
        uint16 createPoolLawId; // The Law ID of the *specific instance* of CreateEasyRPGFPool this corresponds to
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
        uint16 managerRoleId;
        uint16 counter;
        uint16 proposeLawId;
        uint16 vetoLawId;
        uint16 executeLawId;
        string proposeName;
        string vetoName;
        string executeName;
        string[] payoutInputParams;
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
    /// @param config Abi.encode(address allo, address soi, address alloDistribute, uint16 createPoolLawId).
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams, // Expected: abi.encode(string[]("uint256 createPoolActionId"))
        bytes memory config
    ) public override {
        // Ensure config data is provided
        if (config.length == 0) revert("Config required");
        (
            address alloAddress_,
            address statementOfIntentAddress_,
            address alloDistributeAddress_,
            uint16 createPoolLawId_
        ) = abi.decode(config, (address, address, address, uint16));

        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);

        inputParams = abi.encode("address token", "uint256 amount", "uint16 managerRoleId"); 

        lawConfig[lawHash_] = ConfigData({
            allo: alloAddress_,
            statementOfIntentAddress: statementOfIntentAddress_,
            alloDistributeAddress: alloDistributeAddress_,
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
        if(config_.allo == address(0)) revert LawNotConfigured();
        Mem memory m;

        IPowers.Conditions memory conditions = IPowers(powers).getConditions(lawId);
        if(conditions.needFulfilled == 0) revert ("Fulfilled not set");

        m.createPoolActionId = LawUtilities.hashActionId(conditions.needFulfilled, lawCalldata, nonce);

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
        (, , m.managerRoleId) = abi.decode(m.createPoolActionCalldata, (address, uint256, uint16));

        // --- Predict the upcoming Law IDs ---
        m.counter = Powers(payable(powers)).lawCounter();
        m.proposeLawId = m.counter;
        m.vetoLawId = m.counter + 1;
        m.executeLawId = m.counter + 2; // The ID for the AlloDistribute instance

        // --- Prepare LawData for the 3 new laws ---

        // 1. Propose Payout Law (StatementOfIntent)
        m.proposeName = string.concat("Pool ", Strings.toString(m.poolId), ": Propose Payout");
        m.payoutInputParams = new string[](2);
        m.payoutInputParams[0] = "address[] recipients";
        m.payoutInputParams[1] = "uint256[] amounts";
        m.encodedParams = abi.encode(m.payoutInputParams); 
        
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

        // 2. Veto Payout Law (StatementOfIntent)
        m.vetoName = string.concat("Pool ", Strings.toString(m.poolId), ": Veto Payout");
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

        // 3. Execute Payout Law (AlloDistribute)
        m.executeName = string.concat("Pool ", Strings.toString(m.poolId), ": Execute Payout");
        // Config for AlloDistribute: (address alloAddress, uint256 poolId)
        m.executeConfig = abi.encode(config_.allo, m.poolId);

        m.executeCondition.allowedRole = m.managerRoleId; // Use roleId from Law A's input
        m.executeCondition.needFulfilled = m.proposeLawId;    // Propose must pass
        m.executeCondition.needNotFulfilled = m.vetoLawId;     // Veto must NOT pass
  
        m.executeLawData = PowersTypes.LawInitData({
            targetLaw: config_.alloDistributeAddress,
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

        // Powers.fulfill will execute these calls
        return (actionId, targets, values, calldatas);
    }

     /// @notice Retrieves the config data for a given factory law instance.
    function getConfigData(address powers, uint16 lawId) external view returns (ConfigData memory) {
         bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
         if(lawConfig[lawHash_].allo == address(0)) revert LawNotConfigured();
        return lawConfig[lawHash_];
    }
}
