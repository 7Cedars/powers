// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

contract CheckExternalActionState is Law {
    error ActionNotFulfilled();

    constructor() {
        bytes memory configParams = abi.encode("address powersAddress", "uint16 lawId", "string[] inputParams");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory, bytes memory config)
        public
        override
    {
        ( , , string[] memory inputParams) = abi.decode(config, (address, uint16, string[])); // validate config
        super.initializeLaw(index, nameDescription, abi.encode(inputParams), config);
    }

    function handleRequest(
        address, /*caller*/
        address, /*powers*/
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // Decode parameters
        (bytes memory userCalldata, address remotePowersAddress, uint16 remoteLawId) = 
            abi.decode(lawCalldata, (bytes, address, uint16));

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        uint256 remoteActionId = LawUtilities.hashActionId(remoteLawId, userCalldata, nonce);

        PowersTypes.ActionState state = IPowers(remotePowersAddress).getActionState(remoteActionId);
        if (state != PowersTypes.ActionState.Fulfilled) {
            revert ActionNotFulfilled();
        }
        
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(0);

        return (actionId, targets, values, calldatas);
    }
}
