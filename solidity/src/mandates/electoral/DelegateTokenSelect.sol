// SPDX-License-Identifier: MIT

/// @notice Assign roles based on delegated token amounts from nominees.
///
/// This mandate:
/// - Fetches nominees from a Nominees contract
/// - Gets delegated vote amounts for each nominee from an ERC20Votes token
/// - Ranks nominees by delegated token amount
/// - Revokes roles from all current holders
/// - Assigns roles to top N nominees (based on maxRoleHolders)
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Mandate } from "../../Mandate.sol";
import { MandateUtilities } from "../../libraries/MandateUtilities.sol";
import { Powers } from "../../Powers.sol";
import { Nominees } from "../../helpers/Nominees.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract DelegateTokenSelect is Mandate {
    struct Data {
        address powersContract;
        address votesToken;
        address nomineesContract;
        uint256 roleId;
        uint256 maxRoleHolders;
    }

    mapping(bytes32 mandateHash => Data data) internal _data;

    /// @notice Constructor for DelegateTokenSelect mandate
    constructor() {
        bytes memory configParams =
            abi.encode("address VotesToken", "address NomineesContract", "uint256 RoleId", "uint256 MaxRoleHolders");
        emit Mandate__Deployed(configParams);
    }

    function initializeMandate(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address votesToken_, address nomineesContract_, uint256 roleId_, uint256 maxRoleHolders_) =
            abi.decode(config, (address, address, uint256, uint256));

        bytes32 mandateHash = MandateUtilities.hashMandate(msg.sender, index);

        _data[mandateHash] = Data({
            powersContract: msg.sender,
            votesToken: votesToken_,
            nomineesContract: nomineesContract_,
            roleId: roleId_,
            maxRoleHolders: maxRoleHolders_
        });

        // No input parameters needed for this mandate
        inputParams = abi.encode();

        super.initializeMandate(index, nameDescription, inputParams, config);
    }

    /// @notice Execute the mandate by revoking current role holders and assigning top token holders
    /// @param mandateCalldata The calldata (empty for this mandate)
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
        bytes32 mandateHash = MandateUtilities.hashMandate(powers, mandateId);
        Data memory data = _data[mandateHash];

        actionId = MandateUtilities.hashActionId(mandateId, mandateCalldata, nonce);

        // Step 1: Get current role holders from Powers
        uint256 amountRoleHolders = Powers(payable(data.powersContract)).getAmountRoleHolders(data.roleId);

        address[] memory currentRoleHolders = new address[](amountRoleHolders);
        for (uint256 i = 0; i < amountRoleHolders; i++) {
            currentRoleHolders[i] = Powers(payable(data.powersContract)).getRoleHolderAtIndex(data.roleId, i);
        }

        // Step 2: Get nominees
        address[] memory nominees = Nominees(data.nomineesContract).getNominees();
        uint256 numNominees = nominees.length;

        // Step 3: Determine elected nominees
        address[] memory elected;
        
        // Gas optimization: If all nominees will be elected, skip ranking
        if (numNominees <= data.maxRoleHolders) {
            // All nominees get elected, no need to rank by delegated tokens
            elected = nominees;
        } else {
            // Need to rank by delegated tokens and select top maxRoleHolders
            address[] memory rankedNominees = new address[](numNominees);
            uint256[] memory delegatedVotes = new uint256[](numNominees);

            // Get delegated votes for each nominee
            for (uint256 i = 0; i < numNominees; i++) {
                rankedNominees[i] = nominees[i];
                delegatedVotes[i] = ERC20Votes(data.votesToken).getVotes(nominees[i]);
            }

            // Sort nominees by delegated votes (bubble sort - descending)
            for (uint256 i = 0; i < numNominees - 1; i++) {
                for (uint256 j = 0; j < numNominees - i - 1; j++) {
                    if (delegatedVotes[j] < delegatedVotes[j + 1]) {
                        // Swap votes
                        uint256 tempVotes = delegatedVotes[j];
                        delegatedVotes[j] = delegatedVotes[j + 1];
                        delegatedVotes[j + 1] = tempVotes;
                        // Swap nominees
                        address tempNominee = rankedNominees[j];
                        rankedNominees[j] = rankedNominees[j + 1];
                        rankedNominees[j + 1] = tempNominee;
                    }
                }
            }

            // Select top maxRoleHolders candidates
            elected = new address[](data.maxRoleHolders);
            for (uint256 i = 0; i < data.maxRoleHolders; i++) {
                elected[i] = rankedNominees[i];
            }
        }

        // Step 4: Calculate total number of operations needed
        uint256 totalOperations = amountRoleHolders + elected.length;

        if (totalOperations == 0) {
            // No operations needed, but we still need to create an empty array
            (targets, values, calldatas) = MandateUtilities.createEmptyArrays(1);
            return (actionId, targets, values, calldatas);
        }

        (targets, values, calldatas) = MandateUtilities.createEmptyArrays(totalOperations);

        uint256 operationIndex = 0;

        // Step 5: Revoke roles from all current holders
        for (uint256 i = 0; i < currentRoleHolders.length; i++) {
            targets[operationIndex] = data.powersContract;
            calldatas[operationIndex] =
                abi.encodeWithSelector(Powers.revokeRole.selector, data.roleId, currentRoleHolders[i]);
            operationIndex++;
        }

        // Step 6: Assign roles to newly elected accounts
        for (uint256 i = 0; i < elected.length; i++) {
            targets[operationIndex] = data.powersContract;
            calldatas[operationIndex] = abi.encodeWithSelector(Powers.assignRole.selector, data.roleId, elected[i]);
            operationIndex++;
        }

        return (actionId, targets, values, calldatas);
    }

    /// @notice Get the stored data for a mandate
    function getData(bytes32 mandateHash) public view returns (Data memory) {
        return _data[mandateHash];
    }
}
