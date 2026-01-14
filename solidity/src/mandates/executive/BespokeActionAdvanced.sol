// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a bespoke action with a single function call.
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";

// import { console } from "forge-std/console.sol"; // only for testing purposes.

contract BespokeActionAdvanced is Mandate {
    struct Mem {
        address targetContract;
        bytes4 targetFunction;
        bytes[] staticParams;
        string[] dynamicParams;
        uint8[] indexDynamicParams;
        bytes[] dynamicParts;
        uint256 staticLen;
        bytes packedParams;
    }

    /// @notice Constructor of the BespokeActionAdvanced mandate
    constructor() {
        bytes memory configParams = abi.encode(
            "address TargetContract",
            "bytes4 TargetFunction",
            "bytes[] StaticParams",
            "string[] DynamicParams",
            "uint8[] IndexDynamicParams"
        );
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    { 
        ( , , , string[] memory dynamicParams, ) = abi.decode(config, (address, bytes4, bytes[], string[], uint8[]));
        super.initializeMandate(index, nameDescription, abi.encode(dynamicParams), config);
    }

    /// @notice Execute the mandate by calling the configured target function with mixed static/dynamic parameters
    /// @param mandateCalldata the calldata containing dynamic parameters to insert into the function call
    function handleRequest(
        address,
        /*caller*/
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;
        ( 
            mem.targetContract,
            mem.targetFunction,
            mem.staticParams,
            mem.dynamicParams,
            mem.indexDynamicParams
        ) = abi.decode(getConfig(powers, mandateId), (address, bytes4, bytes[], string[], uint8[]));
        actionId = MandateUtilities.computeActionId(mandateId, mandateCalldata, nonce);

        // Send the calldata to the target function
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        targets[0] = mem.targetContract;
        calldatas[0] = _buildCalldata(mem.indexDynamicParams, mem.staticParams, mem.targetFunction, mandateCalldata);

        return (actionId, targets, values, calldatas);
    }

    /// @dev Builds the calldata for the configured target function by inserting dynamic params
    /// into the preconfigured static params according to insertion indices, then prefixing
    /// the 4-byte function selector
    /// @param  indexDynamicParams An array indicating at which static param index each dynamic param should be inserted.
    ///                           Use staticLen as index to insert at the end.
    /// @param  staticParams An array of static parameters as bytes[]
    /// @param  targetFunction The 4-byte function selector of the target function
    /// @param mandateCalldata The dynamic parameters encoded as bytes[]
    /// @return The complete calldata ready for execution
    function _buildCalldata(
        uint8[] memory indexDynamicParams, 
        bytes[] memory staticParams,
        bytes4 targetFunction,
        bytes memory mandateCalldata
        ) internal view returns (bytes memory) {
            Mem memory mem;

            // mandateCalldata is expected to be abi.encode(bytes[] dynamicParts) where
            // dynamicParts.length == data.indexDynamicParams.length
            mem.dynamicParts = abi.decode(mandateCalldata, (bytes[]));

            if (mem.dynamicParts.length != indexDynamicParams.length) revert("Bad Dynamic Length");
            mem.staticLen = staticParams.length;

            // Compose parameter bytes in the following order:
            // for k in [0..staticLen-1]:
            //   append all dynamicParts[j] where indexDynamicParams[j] == k
            //   append staticParams[k]
            // finally append all dynamicParts[j] where indexDynamicParams[j] == staticLen (insert at end)
 
            for (uint256 k; k < mem.staticLen; k++) {
                // Insert dynamics scheduled before static k
                for (uint256 j; j < mem.dynamicParts.length; j++) {
                    if (indexDynamicParams[j] == k) {
                        mem.packedParams = abi.encodePacked(mem.packedParams, mem.dynamicParts[j]);
                    }
                }
                // Append static param k
                mem.packedParams = abi.encodePacked(mem.packedParams, staticParams[k]);
            }

            // Append dynamics scheduled at the end
            for (uint256 j; j < mem.dynamicParts.length; j++) {
                if (indexDynamicParams[j] == mem.staticLen) {
                    mem.packedParams = abi.encodePacked(mem.packedParams, mem.dynamicParts[j]);
                }
            }

            return abi.encodePacked(targetFunction, mem.packedParams);
    }
}
