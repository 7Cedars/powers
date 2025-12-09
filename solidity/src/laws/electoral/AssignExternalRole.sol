// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

contract AssignExternalRole is Law {
    // State variables
    address private s_externalPowersAddress;
    uint256 private s_roleId;

    constructor() {
        bytes memory configParams = abi.encode("address externalPowers", "uint256 roleId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory, bytes memory config)
        public
        override
    {
        // Decode and store configuration parameters
        (s_externalPowersAddress, s_roleId) = abi.decode(config, (address, uint256));

        // Define the input parameters for the UI
        bytes memory inputParams = abi.encodePacked(abi.encode("address account"));
        super.initializeLaw(index, nameDescription, inputParams, config);
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
        // Decode input parameter
        (address account) = abi.decode(lawCalldata, (address));

        // Check if the account has the required role on the external contract
        uint48 hasRole = Powers(s_externalPowersAddress).hasRoleSince(account, s_roleId);
        if (hasRole == 0) {
            revert("Account does not have role.");
        }

        // Prepare the action to assign the role on the current Powers contract
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = powers; // The target is the current Powers contract
        calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, s_roleId, account);

        return (actionId, targets, values, calldatas);
    }
}
