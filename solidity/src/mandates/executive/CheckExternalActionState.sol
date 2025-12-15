// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

contract CheckExternalActionState is Mandate {
    /// @dev Configuration for this mandate adoption.
    struct ConfigData {
        address parentPowers;
        uint16 mandateId;
    }
    mapping(bytes32 mandateHash => ConfigData data) public mandateConfig;

    constructor() {
        bytes memory configParams = abi.encode("address parentPowers", "uint16 mandateId", "string[] inputParams");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory, bytes memory config)
        public
        override
    {
        (address parentPowers_, uint16 mandateId_, string[] memory inputParams_) =
            abi.decode(config, (address, uint16, string[])); // validate config

        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        mandateConfig[mandateHash] = ConfigData({ parentPowers: parentPowers_, mandateId: mandateId_ });

        super.initializeMandate(index, nameDescription, abi.encode(inputParams_), config);
    }

    function handleRequest(
        address, /*caller*/
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
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);
        ConfigData memory config = mandateConfig[MandateUtilities.hashMandate(powers, mandateId)];
        uint256 remoteActionId = MandateUtilities.hashActionId(config.mandateId, mandateCalldata, nonce);

        PowersTypes.ActionState state = IPowers(config.parentPowers).getActionState(remoteActionId);
        if (state != PowersTypes.ActionState.Fulfilled) {
            revert("Action not fulfilled");
        }

        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
        return (actionId, targets, values, calldatas);
    }
}
