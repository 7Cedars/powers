// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

contract CheckExternalActionState is Law {
    /// @dev Configuration for this law adoption.
    struct ConfigData {
        address parentPowers;
        uint16 lawId;
    }
    mapping(bytes32 lawHash => ConfigData data) public lawConfig;

    constructor() {
        bytes memory configParams = abi.encode("address parentPowers", "uint16 lawId", "string[] inputParams");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory, bytes memory config)
        public
        override
    {
        (address parentPowers_, uint16 lawId_, string[] memory inputParams_) =
            abi.decode(config, (address, uint16, string[])); // validate config

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        lawConfig[lawHash] = ConfigData({ parentPowers: parentPowers_, lawId: lawId_ });

        super.initializeLaw(index, nameDescription, abi.encode(inputParams_), config);
    }

    function handleRequest(
        address, /*caller*/
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        ConfigData memory config = lawConfig[LawUtilities.hashLaw(powers, lawId)];
        uint256 remoteActionId = LawUtilities.hashActionId(config.lawId, lawCalldata, nonce);

        PowersTypes.ActionState state = IPowers(config.parentPowers).getActionState(remoteActionId);
        if (state != PowersTypes.ActionState.Fulfilled) {
            revert("Action not fulfilled");
        }

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        return (actionId, targets, values, calldatas);
    }
}
