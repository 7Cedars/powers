// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @notice Run delegate elections and assign roles based on election results.
///
/// This law:
/// - Fetches current role holders from Powers
/// - Runs an election using a Erc20DelegateElection contract
/// - Revokes roles from all current holders
/// - Assigns roles to newly elected accounts
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Powers } from "../../Powers.sol";
import { Erc20DelegateElection } from "@mocks/Erc20DelegateElection.sol";

contract ElectionSelect is Law {
    struct Data {
        address powersContract;
        address ElectionContract;
        uint256 roleId;
        uint256 maxRoleHolders;
    }

    mapping(bytes32 lawHash => Data data) internal _data;

    /// @notice Constructor for ElectionSelect law
    constructor() {
        bytes memory configParams = abi.encode("address ElectionContract", "uint256 RoleId", "uint256 MaxRoleHolders");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address ElectionContract_, uint256 roleId_, uint256 maxRoleHolders_) =
            abi.decode(config, (address, uint256, uint256));

        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);

        _data[lawHash] = Data({
            powersContract: msg.sender,
            ElectionContract: ElectionContract_,
            roleId: roleId_,
            maxRoleHolders: maxRoleHolders_
        });

        // No input parameters needed for this law
        inputParams = abi.encode();

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the law by revoking current role holders and assigning newly elected accounts
    /// @param lawCalldata The calldata (empty for this law)
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        bytes32 lawHash = LawUtilities.hashLaw(powers, lawId);
        Data memory data = _data[lawHash];

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Step 1: Get current role holders from Powers
        address[] memory currentRoleHolders = Powers(payable(data.powersContract)).getRoleHolders(data.roleId);

        // Step 2: Get nominee ranking and select top candidates
        (address[] memory rankedNominees,) = Erc20DelegateElection(data.ElectionContract).getNomineeRanking();

        // Select top candidates based on maxRoleHolders
        uint256 numNominees = rankedNominees.length;
        uint256 maxN = data.maxRoleHolders;
        uint256 numToElect = numNominees <= maxN ? numNominees : maxN;

        address[] memory elected = new address[](numToElect);
        for (uint256 i = 0; i < numToElect; i++) {
            elected[i] = rankedNominees[i];
        }

        // Calculate total number of operations needed:
        // - Revoke all current role holders
        // - Assign role to all newly elected accounts
        uint256 totalOperations = currentRoleHolders.length + elected.length;

        if (totalOperations == 0) {
            // No operations needed, but we still need to create an empty array otherwise action will not be set as fulfilled..
            (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
            return (actionId, targets, values, calldatas);
        }

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(totalOperations);

        uint256 operationIndex = 0;

        // Step 3: Revoke roles from all current holders
        for (uint256 i = 0; i < currentRoleHolders.length; i++) {
            targets[operationIndex] = data.powersContract;
            calldatas[operationIndex] =
                abi.encodeWithSelector(Powers.revokeRole.selector, data.roleId, currentRoleHolders[i]);
            operationIndex++;
        }

        // Step 4: Assign roles to newly elected accounts
        for (uint256 i = 0; i < elected.length; i++) {
            targets[operationIndex] = data.powersContract;
            calldatas[operationIndex] = abi.encodeWithSelector(Powers.assignRole.selector, data.roleId, elected[i]);
            operationIndex++;
        }

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a law
    function getData(bytes32 lawHash) public view returns (Data memory) {
        return _data[lawHash];
    }
}
