// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Law} from "../../Law.sol"; 
import {IPowers} from "../../interfaces/IPowers.sol"; 
import {LawUtilities} from "../../libraries/LawUtilities.sol";  


/**
 * @title CreateEasyRPGFPool
 * @notice Law A: Creates an Allo v2 pool using EasyRPGFStrategy.
 * @dev Stores the managerRoleId in the action's lawCalldata for later use by AdoptEasyRPGFGovernance.
 * @dev The return data (poolId) from the Allo call will be stored by Powers.sol in the Action struct.
 */
contract AlloCreateRPGFPool is Law {
    /// @dev Metadata struct for the Allo pool
    struct Metadata {
        uint256 protocol;
        string pointer;
    }


    /// @dev Configuration for each instance of this factory law.
    struct ConfigData {
        address allo;
        bytes32 profileId;
        address easyRPGFStrategy; // The specific EasyRPGF strategy implementation address
    }

    /// @dev Mapping law hash => configuration.
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;

    // State memory accumulator to avoid stack too deep errors
    struct Mem {
        address tokenAddress;
        uint256 tokenAmount;
        uint16 managerRoleId;
        bytes initStrategyData;
        address[] managers;
        Metadata metadata;
        bytes alloCalldata;
    }

    /// @notice Standard initializer for Powers laws.
    /// @param index The unique index assigned by Powers.sol.
    /// @param nameDescription A human-readable description.
    /// @param inputParams encoded string[] describing required inputs for execute.
    /// @param config Abi.encode(address allo, bytes32 profileId, address easyRPGFStrategy).
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams, // Expected:  ("address token", "uint256 amount", "uint16 managerRoleId"))
        bytes memory config
    ) public override {
        (
            address alloAddress,
            bytes32 profileId_,
            address easyRPGFStrategy_
        ) = abi.decode(config, (address, bytes32, address));

        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);

        inputParams = abi.encode("address token", "uint256 amount", "uint16 managerRoleId");

        lawConfig[lawHash_] = ConfigData({
            allo: alloAddress,
            profileId: profileId_,
            easyRPGFStrategy: easyRPGFStrategy_
        });

        // Store standard law data, including the input description needed for propose/fulfill
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Prepares the call to Allo.createPoolWithStrategy. No callback needed.
    /// @param caller The original caller interacting with Powers.sol (not used).
    /// @param powers The address of the Powers contract instance.
    /// @param lawId The ID of this specific law instance.
    /// @param lawCalldata ABI encoded input data: abi.encode(address token, uint256 amount, uint16 managerRoleId).
    ///        This ENTIRE blob is stored by Powers.sol in action.lawCalldata.
    /// @param nonce A unique nonce for replay protection.
    /// @return actionId Unique ID for this action proposal.
    /// @return targets Array containing the Allo contract address.
    /// @return values Array containing 0 (no ETH sent).
    /// @return calldatas Array containing the encoded call to Allo.createPoolWithStrategy.
    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata, // Contains token, amount, managerRoleId
        uint256 nonce
    ) public view override returns (
        uint256 actionId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
        // NO callbackSelector or callbackData returned
    ) {
        bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
        ConfigData memory config_ = lawConfig[lawHash_];
        if(config_.allo == address(0)) revert("Law not configured");
        Mem memory m;

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Decode inputs *only* to use them for the Allo call
        (m.tokenAddress, m.tokenAmount, m.managerRoleId) = abi.decode(lawCalldata, (address, uint256, uint16)); // managerRoleId stays encoded in lawCalldata

        // Prepare inputs for Allo's createPoolWithStrategy
        m.initStrategyData = abi.encode(0); // EasyRPGFStrategy has no init data in initialize
        m.managers = new address[](1);
        m.managers[0] = powers; // Set the Powers contract as the sole pool manager initially
        m.metadata = Metadata({
            protocol: 1, // Example: IPFS
            pointer: "" // No initial metadata pointer
        }); 

        // Encode the main call to Allo
        m.alloCalldata = abi.encodeWithSelector(
            0xe1007d4a, // IAllo.createPoolWithCustomStrategy.selector,
            config_.profileId,          // _profileId
            config_.easyRPGFStrategy,   // _strategy (the implementation contract)
            m.initStrategyData,         // _initStrategyData
            m.tokenAddress,             // _token
            m.tokenAmount,              // _amount
            m.metadata,                 // _metadata
            m.managers                  // _managers
        );

        // Setup the return values for Powers.sol
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = config_.allo;
        values[0] = 0; // No ETH value sent directly here
        calldatas[0] = m.alloCalldata;

        return (actionId, targets, values, calldatas);
    }

    /// @notice Retrieves the config data for a given factory law instance.
    function getConfigData(address powers, uint16 lawId) external view returns (ConfigData memory) {
         bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
         if(lawConfig[lawHash_].allo == address(0)) revert("Law not configured");
        return lawConfig[lawHash_];
    }
}
