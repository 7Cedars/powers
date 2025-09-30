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

/// @notice This law allows members of a role to select from nominated addresses for their own role.
///
/// The logic:
/// - Members can assign or revoke roles from nominated addresses.
/// - The inputParams are dynamic - as many bool options will appear as there are nominees.
/// - Members can select multiple nominees up to the maxVotes limit.
/// - Role assignment/revocation is handled through the Powers contract.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { Nominees } from "@mocks/Nominees.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract PeerSelect is Law {
    struct MemoryData {
        address caller;
        bytes32 lawHash;
        address[] nominees;
        string[] nomineeList;
        bool[] selection;
        uint256 numSelections;
        uint256 i;
        uint256[] selectedIndices;
        bool[] assignFlags;
    }

    struct Data {
        uint256 maxRoleHolders;
        uint256 roleId;
        uint8 maxVotes;
        address nomineesContract;
    }

    mapping(bytes32 lawHash => Data) public data;

    constructor() {
        bytes memory configParams = abi.encode("uint256 maxRoleHolders", "uint256 roleId", "uint8 maxVotes", "address NomineesContract");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        MemoryData memory mem;
        (uint256 maxRoleHolders_, uint256 roleId_, uint8 maxVotes_, address nomineesContract_) = abi.decode(config, (uint256, uint256, uint8, address));
        
        // Get nominees from the Nominees contract
        mem.nominees = Nominees(nomineesContract_).getNominees();
        
        // Save data to state
        mem.lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[mem.lawHash].maxRoleHolders = maxRoleHolders_;
        data[mem.lawHash].roleId = roleId_;
        data[mem.lawHash].maxVotes = maxVotes_;
        data[mem.lawHash].nomineesContract = nomineesContract_;

        // Create dynamic inputParams based on nominees
        mem.nomineeList = new string[](mem.nominees.length);
        for (uint256 i = 0; i < mem.nominees.length; i++) {
            mem.nomineeList[i] = string.concat("bool ", Strings.toHexString(mem.nominees[i]));
        }
        inputParams = abi.encode(mem.nomineeList);

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    function handleRequest(address /* caller */, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        )
    {
        MemoryData memory mem;
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        
        // Decode the selection data
        (mem.selection) = abi.decode(lawCalldata, (bool[]));
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Get current nominees from Nominees contract
        mem.nominees = Nominees(data[mem.lawHash].nomineesContract).getNominees();

        // Validate selection length matches nominees length
        if (mem.selection.length != mem.nominees.length) {
            revert("Invalid selection length.");
        }

        // Count selections and collect selected indices
        mem.numSelections = 0;
        mem.selectedIndices = new uint256[](mem.selection.length);
        for (mem.i = 0; mem.i < mem.selection.length; mem.i++) {
            if (mem.selection[mem.i]) {
                mem.selectedIndices[mem.numSelections] = mem.i;
                mem.numSelections++;
            }
        }

        // Validate selection count
        if (mem.numSelections == 0) {
            revert("Must select at least one nominee.");
        }
        if (mem.numSelections > data[mem.lawHash].maxVotes) {
            revert("Too many selections. Exceeds maxVotes limit.");
        }

        // Prepare arrays for multiple calls
        mem.assignFlags = new bool[](mem.numSelections);
        uint256 assignCount = 0;
        uint256 revokeCount = 0;

        // Check each selected nominee and determine if it's assignment or revocation
        for (mem.i = 0; mem.i < mem.numSelections; mem.i++) {
            uint256 selectedIndex = mem.selectedIndices[mem.i];
            uint48 hasRoleSince = Powers(payable(powers)).hasRoleSince(mem.nominees[selectedIndex], data[mem.lawHash].roleId);
            mem.assignFlags[mem.i] = (hasRoleSince == 0);
            
            if (mem.assignFlags[mem.i]) {
                assignCount++;
            } else {
                revokeCount++;
            }
        }

        // Validate assignments don't exceed max role holders
        if (assignCount > 0) {
            uint256 currentRoleHolders = Powers(payable(powers)).getAmountRoleHolders(data[mem.lawHash].roleId);
            if (currentRoleHolders + assignCount > data[mem.lawHash].maxRoleHolders) {
                revert("Too many assignments. Would exceed max role holders.");
            }
        }

        // Set up calls to Powers contract
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(mem.numSelections);
        
        for (mem.i = 0; mem.i < mem.numSelections; mem.i++) {
            uint256 selectedIndex = mem.selectedIndices[mem.i];
            targets[mem.i] = powers;
            
            if (mem.assignFlags[mem.i]) {
                calldatas[mem.i] = abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId, mem.nominees[selectedIndex]);
            } else {
                calldatas[mem.i] = abi.encodeWithSelector(Powers.revokeRole.selector, data[mem.lawHash].roleId, mem.nominees[selectedIndex]);
            }
        }

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
