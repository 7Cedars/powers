// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { Powers } from "../../Powers.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { BespokeActionSimple } from "../executive/BespokeActionSimple.sol";
import { TreasuryPoolTransfer } from "./TreasuryPoolTransfer.sol";
import { TreasuryPools } from "../../helpers/TreasuryPools.sol";

/**
 * @title TreasuryPoolGovernance
 * @notice Law B: Adopts the standard 3 governance laws (Propose, Veto, Execute Transfer) for a Treasury Pool
 * after it was created by a Law A action (e.g., via a law that calls TreasuryPools.createPool).
 * @dev Reads the poolId from the stored return data of the pool creation action (Law A).
 * @dev Reads the managerRoleId from the original input calldata of the pool creation action (Law A).
 * @dev Condition `needFulfilled` must point to the specific Law A instance.
 */
contract TreasuryPoolGovernance is Law {
    /// @dev Configuration for this law adoption law. Includes addresses of base laws to adopt.
    struct ConfigData {
        address selectedPoolTransfer; // The SelectedPoolTransfer law
        address treasuryPools; // The TreasuryPools contract
        uint16 proposeLawId; // Law ID for the Proposal law
        uint16 vetoLawId; // Law ID for the Veto law
        uint32 votingPeriod;
        uint8 succeedAt;
        uint8 quorum;
    }

    /// @dev Mapping law hash => configuration.
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;

    // State memory accumulator to avoid stack too deep errors
    struct Mem {
        uint256 createPoolActionId;
        uint16 sourceActionLawId;
        uint48 sourceActionFulfilledAt;
        bytes createPoolActionReturnData;
        uint256 poolId;
        bytes createPoolActionCalldata;
        uint256 managerRoleId;

        string[] transferInputParams;

        // mem law
        uint16 counter;
        string lawName;
        bytes encodedParams;
        bytes lawConfig;
        PowersTypes.LawInitData lawInitData;
        PowersTypes.Conditions lawCondition;
    }

    /// @notice Error if the referenced action ID is invalid or not fulfilled.
    error InvalidSourceAction();
    /// @notice Error decoding pool ID from source action return data.
    error CannotDecodePoolId();
    /// @notice Error decoding original inputs (managerRoleId) from source action calldata.
    error CannotDecodeSourceInputs();
    /// @notice Error if the law instance is not configured.
    error LawNotConfigured();

    constructor() {
        bytes memory configParams = abi.encode(
            "address selectedPoolTransfer",
            "address TreasuryPools",
            "uint16 proposalLawId",
            "uint16 vetoLawId",
            "uint32 votingPeriod",
            "uint8 succeedAt",
            "uint8 quorum"
        );
        emit Law__Deployed(configParams);
    }

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
        (
            address selectedPoolTransferAddress_,
            address treasuryPoolsAddress_,
            uint16 proposeLawId_,
            uint16 vetoLawId_,
            uint32 votingPeriod_,
            uint8 succeedAt_,
            uint8 quorum_
        ) = abi.decode(config, (address, address, uint16, uint16, uint32, uint8, uint8));
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);

        inputParams = abi.encode("address TokenAddress", "uint256 Budget", "uint256 ManagerRoleId");

        lawConfig[lawHash_] = ConfigData({
            selectedPoolTransfer: selectedPoolTransferAddress_,
            treasuryPools: treasuryPoolsAddress_,
            proposeLawId: proposeLawId_,
            vetoLawId: vetoLawId_,
            votingPeriod: votingPeriod_,
            succeedAt: succeedAt_,
            quorum: quorum_
        });

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Prepares the calls to adopt the three governance laws.
    /// @param /* caller */ The original caller (not used).
    /// @param powers The address of the Powers contract instance.
    /// @param lawId The ID of this specific law instance.
    /// @param lawCalldata ABI encoded input data: abi.encode(uint256 createPoolActionId).
    /// @param nonce A unique nonce for replay protection.
    /// @return actionId Unique ID for this action proposal.
    /// @return targets Array containing the Powers address three times.
    /// @return values Array containing 0 three times.
    /// @return calldatas Array containing the three encoded calls to Powers.adoptLaw.
    function handleRequest(
        address,
        /* caller */
        address powers,
        uint16 lawId,
        bytes memory lawCalldata, // Contains createPoolActionId
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
        ConfigData memory config_ = lawConfig[lawHash_];
        if (config_.treasuryPools == address(0)) revert("Law Not Configured");
        Mem memory m;

        // First get the law Id of the law that created the pool
        IPowers.Conditions memory conditions = IPowers(powers).getConditions(lawId);
        if (conditions.needFulfilled == 0) revert("Fulfilled not set");

        // Then retrieve the source action data
        m.createPoolActionId = LawUtilities.hashActionId(conditions.needFulfilled, lawCalldata, nonce);
        (m.sourceActionLawId,,, m.sourceActionFulfilledAt,,,) = IPowers(powers).getActionData(m.createPoolActionId);

        // Check if action exists, is fulfilled, and came from the correct law type
        if (m.sourceActionFulfilledAt == 0) revert InvalidSourceAction();

        // --- Decode necessary data, get the poolId ---
        m.createPoolActionReturnData = IPowers(powers).getActionReturnData(m.createPoolActionId, 0);
        (m.poolId) = abi.decode(m.createPoolActionReturnData, (uint256));
        if (m.poolId == 0) revert("Cannot decode poolId"); // NB! PoolId 0 is invalid

        // m.createPoolActionCalldata = IPowers(powers).getActionCalldata(m.createPoolActionId);
        (,, m.managerRoleId) = abi.decode(lawCalldata, (address, uint256, uint256));

        // --- Predict the upcoming Law IDs ---
        m.counter = Powers(payable(powers)).lawCounter();

        //////////////////////////////////////////////////////////////
        //             BUILDING SELECTED POOL TRANSFER LAW          //
        //////////////////////////////////////////////////////////////

        // 3. Execute Transfer Law (SelectedPoolTransfer)
        m.lawName = string.concat("Pool ", Strings.toString(m.poolId), " Execute Transfer");

        m.lawConfig = abi.encode(config_.treasuryPools, m.poolId);

        m.lawCondition.allowedRole = m.managerRoleId; // Use roleId from Law A's input
        m.lawCondition.votingPeriod = config_.votingPeriod; // No voting period for Execute Transfer
        m.lawCondition.succeedAt = config_.succeedAt;
        m.lawCondition.quorum = config_.quorum;
        m.lawCondition.needFulfilled = config_.proposeLawId; // Propose must pass
        m.lawCondition.needNotFulfilled = config_.vetoLawId; // Veto must NOT pass

        m.lawInitData = PowersTypes.LawInitData({
            targetLaw: config_.selectedPoolTransfer,
            nameDescription: m.lawName,
            config: m.lawConfig,
            conditions: m.lawCondition
        });

        // --- Prepare the calls to Powers.adoptLaw ---
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(IPowers.adoptLaw.selector, m.lawInitData);

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        // Powers.fulfill will execute these calls
        return (actionId, targets, values, calldatas);
    }

    /// @notice Retrieves the config data for a given factory law instance.
    function getConfigData(address powers, uint16 lawId) external view returns (ConfigData memory) {
        bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
        if (lawConfig[lawHash_].treasuryPools == address(0)) revert LawNotConfigured();
        return lawConfig[lawHash_];
    }
}
