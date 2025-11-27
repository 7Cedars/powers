// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

contract CheckExternalActionState is Law {
    error ActionNotFulfilled();

    constructor() {
        bytes memory configParams = abi.encode("string[] inputParams");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory, bytes memory config)
        public
        override
    {
        bytes memory finalInputParams = abi.encodePacked(
            config,
            abi.encode("address powersAddress", "uint16 lawId")
        );
        super.initializeLaw(index, nameDescription, finalInputParams, config);
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
