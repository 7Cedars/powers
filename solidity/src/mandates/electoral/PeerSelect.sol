// SPDX-License-Identifier: MIT

/// @notice Allows members of a role to select from nominated addresses for their own role.
///
/// The logic:
/// - Members can assign or revoke roles from nominated addresses.
/// - The inputParams are dynamic - as many bool options will appear as there are nominees.
/// - Members can select multiple nominees up to the maxVotes limit.
/// - Role assignment/revocation is handled through the Powers contract.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { Powers } from "../../Powers.sol";
import { Nominees } from "../../helpers/Nominees.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract PeerSelect is Mandate {
    struct MemoryData {
        address caller;
        bytes32 mandateHash;
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

    mapping(bytes32 mandateHash => Data) public data;

    /// @notice Constructor for PeerSelect mandate
    constructor() {
        bytes memory configParams =
            abi.encode("uint256 maxRoleHolders", "uint256 roleId", "uint8 maxVotes", "address NomineesContract");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        MemoryData memory mem;
        (uint256 maxRoleHolders_, uint256 roleId_, uint8 maxVotes_, address nomineesContract_) =
            abi.decode(config, (uint256, uint256, uint8, address));

        // Get nominees from the Nominees contract
        mem.nominees = Nominees(nomineesContract_).getNominees();

        // Save data to state
        mem.mandateHash = MandateUtilities.hashMandate(msg.sender, index);
        data[mem.mandateHash].maxRoleHolders = maxRoleHolders_;
        data[mem.mandateHash].roleId = roleId_;
        data[mem.mandateHash].maxVotes = maxVotes_;
        data[mem.mandateHash].nomineesContract = nomineesContract_;

        // Create dynamic inputParams based on nominees
        mem.nomineeList = new string[](mem.nominees.length);
        for (uint256 i = 0; i < mem.nominees.length; i++) {
            mem.nomineeList[i] = string.concat("bool ", Strings.toHexString(mem.nominees[i]));
        }
        inputParams = abi.encode(mem.nomineeList);

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls to assign or revoke roles for selected nominees
    /// @param powers The Powers contract address
    /// @param mandateId The mandate identifier
    /// @param mandateCalldata Encoded bool[] selections matching current nominees from Nominees contract
    /// @param nonce Unique nonce to build the action id
    function handleRequest(
        address,
        /* caller */
        address powers,
        uint16 mandateId,
        bytes memory mandateCalldata,
        uint256 nonce
    )
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        MemoryData memory mem;
        mem.mandateHash = MandateUtilities.hashMandate(powers, mandateId);

        // Decode the selection data
        (mem.selection) = abi.decode(mandateCalldata, (bool[]));
        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // Get current nominees from Nominees contract
        mem.nominees = Nominees(data[mem.mandateHash].nomineesContract).getNominees();

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
        if (mem.numSelections > data[mem.mandateHash].maxVotes) {
            revert("Too many selections. Exceeds maxVotes limit.");
        }

        // Prepare arrays for multiple calls
        mem.assignFlags = new bool[](mem.numSelections);
        uint256 assignCount = 0;
        uint256 revokeCount = 0;

        // Check each selected nominee and determine if it's assignment or revocation
        for (mem.i = 0; mem.i < mem.numSelections; mem.i++) {
            uint256 selectedIndex = mem.selectedIndices[mem.i];
            uint48 hasRoleSince =
                Powers(payable(powers)).hasRoleSince(mem.nominees[selectedIndex], data[mem.mandateHash].roleId);
            mem.assignFlags[mem.i] = (hasRoleSince == 0);

            if (mem.assignFlags[mem.i]) {
                assignCount++;
            } else {
                revokeCount++;
            }
        }

        // Validate assignments don't exceed max role holders
        if (assignCount > 0) {
            uint256 currentRoleHolders = Powers(payable(powers)).getAmountRoleHolders(data[mem.mandateHash].roleId);
            if (currentRoleHolders + assignCount > data[mem.mandateHash].maxRoleHolders) {
                revert("Too many assignments. Would exceed max role holders.");
            }
        }

        // Set up calls to Powers contract
        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(mem.numSelections);

        for (mem.i = 0; mem.i < mem.numSelections; mem.i++) {
            uint256 selectedIndex = mem.selectedIndices[mem.i];
            targets[mem.i] = powers;

            if (mem.assignFlags[mem.i]) {
                calldatas[mem.i] = abi.encodeWithSelector(
                    Powers.assignRole.selector, data[mem.mandateHash].roleId, mem.nominees[selectedIndex]
                );
            } else {
                calldatas[mem.i] = abi.encodeWithSelector(
                    Powers.revokeRole.selector, data[mem.mandateHash].roleId, mem.nominees[selectedIndex]
                );
            }
        }

        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return data[mandateHash];
    }
}
