// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { Powers } from "../../Powers.sol";
import { IPowers } from "../../interfaces/IPowers.sol";

contract AssignExternalRole is Mandate {
    struct Data {
        address externalPowersAddress;
        uint256 roleId;
    }

    mapping(bytes32 mandateHash => Data) public data;

    constructor() {
        bytes memory configParams = abi.encode("address externalPowers", "uint256 roleId");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory, bytes memory config)
        public
        override
    {
        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        
        // Decode and store configuration parameters
        (data[mandateHash].externalPowersAddress, data[mandateHash].roleId) = abi.decode(config, (address, uint256));

        // Define the input parameters for the UI
        bytes memory inputParams = abi.encode("address account");
        super.initializeMandate(index, nameDescription, inputParams, config);
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
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        Data memory mandateData = data[mandateHash];

        // Decode input parameter
        (address account) = abi.decode(mandateCalldata, (address));

        // A: Check if the account has the role in the Child contract (current Powers contract)
        uint48 hasRoleInChild = Powers(powers).hasRoleSince(account, mandateData.roleId);
        bool A = hasRoleInChild > 0;

        // B: Check if the account has the role in the Parent contract (external Powers contract)
        uint48 hasRoleInParent = Powers(mandateData.externalPowersAddress).hasRoleSince(account, mandateData.roleId);
        bool B = hasRoleInParent > 0;

        // Prepare the action ID
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // Handle the four scenarios
        if (A && !B) {
            // A == true and B == false: revoke role in child contract
            (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(IPowers.revokeRole.selector, mandateData.roleId, account);
        } else if (!A && B) {
            // B == true and A == false: assign role in child contract
            (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
            targets[0] = powers;
            calldatas[0] = abi.encodeWithSelector(IPowers.assignRole.selector, mandateData.roleId, account);
        } else if (!A && !B) {
            // A == false and B == false: revert
            revert("Account does not have role at parent");
        } else {
            // A == true and B == true: revert
            revert("Account already has role at parent");
        }

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a mandate
    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return data[mandateHash];
    }
}
