// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol"; 
import {LawUtilities} from "../../libraries/LawUtilities.sol"; 
// import {IAllo} from "../../../lib/allo-v2/contracts/core/interfaces/IAllo.sol"; 

/**
 * @title AlloDistribute
 * @notice A bespoke law to call the distribute function on a pre-configured Allo v2 pool,
 * assuming an EasyRPGF-style strategy where _data is abi.encode(address[], uint256[]).
 * @dev This law is intended to be adopted dynamically by AdoptEasyRPGFGovernance.
 */
contract AlloDistribute is Law {
    /// @dev Data stored for each instance of this law.
    struct ConfigData {
        address allo;
        uint256 poolId;
    }

    /// @dev Mapping from law hash => configuration data.
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;

    /// @notice Error when input arrays length mismatch.
    error InputLengthMismatch();

    // State memory accumulator to avoid stack too deep errors
    struct Mem {
        address[] recipients;
        uint256[] amounts;
        bytes distributeData;
        bytes alloCalldata;
    }
    /// @notice Standard initializer for Powers laws.
    /// @param index The unique index assigned by Powers.sol.
    /// @param nameDescription A human-readable description.
    /// @param inputParams ABI encoded string[] describing required inputs for execute.
    /// @param config Abi.encode(address alloAddress, uint256 poolId).
    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams, // Expected: abi.encode(string[]("address[] recipients", "uint256[] amounts"))
        bytes memory config
    ) public override {
        // Ensure config data is provided for initialization checks (optional but good practice)
        if (config.length == 0) revert("Config required");
        (address alloAddress, uint256 poolId_) = abi.decode(config, (address, uint256));
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);

        lawConfig[lawHash_] = ConfigData({
            allo: alloAddress,
            poolId: poolId_
        });

        // Store standard law data like name, inputs, etc.
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Prepares the call to Allo.distribute.
    /// @param caller The original caller interacting with Powers.sol (not used here directly).
    /// @param powers The address of the Powers contract instance.
    /// @param lawId The ID of this specific law instance.
    /// @param lawCalldata ABI encoded input data: abi.encode(address[] recipients, uint256[] amounts).
    /// @param nonce A unique nonce for replay protection.
    /// @return actionId Unique ID for this action proposal.
    /// @return targets Array containing the Allo contract address.
    /// @return values Array containing 0 (no ETH sent).
    /// @return calldatas Array containing the encoded call to Allo.distribute.
    function handleRequest(
        address caller,
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    ) public view override returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) {
        bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
        ConfigData memory config_ = lawConfig[lawHash_];
        if(config_.allo == address(0)) revert("Law not configured"); // Basic check
        Mem memory m;

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Use state struct to avoid stack too deep
        (m.recipients, m.amounts) = abi.decode(lawCalldata, (address[], uint256[]));

        if (m.recipients.length != m.amounts.length) {
            revert InputLengthMismatch();
        }
        if (m.recipients.length == 0) {
             revert InputLengthMismatch(); // Cannot distribute to zero recipients
        }

        // Prepare the `_data` argument for Allo.distribute by encoding recipients and amounts
        // This matches how EasyRPGFStrategy expects it based on its _distribute implementation.
        m.distributeData = abi.encode(m.recipients, m.amounts);

        // Prepare the final calldata for the Allo contract interaction
        m.alloCalldata = abi.encodeWithSelector(
            0x3a5fbd92, // IAllo.distribute.selector,
            config_.poolId,
            m.distributeData
        );

        // Setup the return values for Powers.sol
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = config_.allo;
        values[0] = 0; // No ETH value sent in this call
        calldatas[0] = m.alloCalldata;

        return (actionId, targets, values, calldatas);
    }

    /// @notice Retrieves the config data for a given law instance. Used for frontend/display.
    function getConfigData(address powers, uint16 lawId) external view returns (ConfigData memory) {
         bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
         if(lawConfig[lawHash_].allo == address(0)) revert("Law not configured");
        return lawConfig[lawHash_];
    }
}
