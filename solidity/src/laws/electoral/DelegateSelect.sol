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

/// @notice Natspecs are tbi.
///
/// @author 7Cedars

/// @notice This contract assigns accounts to roles by the tokens that have been delegated to them.
/// - At construction time, the following is set:
///    - the maximum amount of accounts that can be assigned the role
///    - the roleId to be assigned
///    - the ERC20 token address to be assessed.
///    - the address from which to retrieve nominees.
///
/// - The logic:
///    - The calldata holds the accounts that need to be _revoked_ from the role prior to the election.
///    - If fewer than N accounts are nominated, all will be assigne roleId R.
///    - If more than N accounts are nominated, the accounts that hold most ERC20 T will be assigned roleId R.
///
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
/// - doess not have to role restricted.
/// - translates a simple token based voting system to separated powers.
/// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers } from "../../Powers.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { NominateMe } from "../state/NominateMe.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { Arrays } from "@openzeppelin/contracts/utils/Arrays.sol";

contract DelegateSelect is Law {
    struct Data {
        address erc20Token;
        uint256 maxRoleHolders;
        uint256 roleId;
        address[] electedAccounts;
    }

    mapping(bytes32 lawHash => Data) internal data;

    struct MemoryData {
        bytes32 lawHash;
        bytes32 nominateMeHash;
        Conditions conditions;
        uint16 nominateMeId;
        address nominateMeAddress;
        address[] nominees;
        uint256 numberRevokees;
        uint256 arrayLength;
        address[] accountElects;
    }

    constructor() {
        bytes memory configParams = abi.encode("address Erc20Token", "uint256 MaxRoleHolders", "uint256 RoleId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (address erc20Token_, uint256 maxRoleHolders_, uint256 roleId_) =
            abi.decode(config, (address, uint256, uint256));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash].erc20Token = erc20Token_;
        data[lawHash].maxRoleHolders = maxRoleHolders_;
        data[lawHash].roleId = roleId_;
        inputParams = abi.encode();
        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        MemoryData memory mem;

        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        mem.conditions = laws[mem.lawHash].conditions;        
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // step 1: setting up array for revoking & assigning roles.
        mem.nominateMeId = mem.conditions.readStateFrom; // readStateFrom is the nominateMe law.
        (mem.nominateMeAddress,,) = Powers(payable(powers)).getActiveLaw(mem.nominateMeId);
        mem.nominateMeHash = LawUtilities.hashLaw(powers, mem.nominateMeId);
        
        // mem.numberNominees = NominateMe(mem.nominateMeAddress).getNomineesCount(mem.nominateMeId);
        mem.nominees = NominateMe(mem.nominateMeAddress).getNominees(mem.nominateMeHash);
        mem.numberRevokees = data[mem.lawHash].electedAccounts.length;
        mem.arrayLength = mem.nominees.length < data[mem.lawHash].maxRoleHolders
            ? mem.numberRevokees + mem.nominees.length
            : mem.numberRevokees + data[mem.lawHash].maxRoleHolders;

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(mem.arrayLength);
        for (uint256 i; i < mem.arrayLength; i++) {
            targets[i] = powers;
        }
        // step 2: calls to revoke roles of previously elected accounts & delete array that stores elected accounts.
        for (uint256 i; i < mem.numberRevokees; i++) {
            calldatas[i] = abi.encodeWithSelector(
                Powers.revokeRole.selector, data[mem.lawHash].roleId, data[mem.lawHash].electedAccounts[i]
            );
        }

        // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
        if (mem.nominees.length < data[mem.lawHash].maxRoleHolders) {
            mem.accountElects = new address[](mem.nominees.length);
            for (uint256 i; i < mem.nominees.length; i++) {
                address accountElect = mem.nominees[i];
                calldatas[i + mem.numberRevokees] =
                    abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId, accountElect);
                mem.accountElects[i] = accountElect;
            }

            // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
        } else {
            // retrieve balances of delegated votes of nominees.
            mem.accountElects = new address[](data[mem.lawHash].maxRoleHolders);
            uint256[] memory _votes = new uint256[](mem.nominees.length);
            address[] memory _nominees = mem.nominees;

            for (uint256 i; i < mem.nominees.length; i++) {
                _votes[i] = ERC20Votes(data[mem.lawHash].erc20Token).getVotes(_nominees[i]);
            }

            // note how the following mechanism works:
            // a. we add 1 to each nominee's position, if we found a account that holds more tokens.
            // b. if the position is greater than MAX_ROLE_HOLDERS, we break. (it means there are more accounts that have more tokens than MAX_ROLE_HOLDERS)
            // c. if the position is less than MAX_ROLE_HOLDERS, we assign the roles.
            uint256 index;
            for (uint256 i; i < mem.nominees.length; i++) {
                uint256 rank;
                // a: loop to assess ranking.
                for (uint256 j; j < mem.nominees.length; j++) {
                    if (j != i && _votes[j] >= _votes[i]) {
                        rank++;
                        if (rank > data[mem.lawHash].maxRoleHolders) break; // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold.
                    }
                }
                // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                if (rank < data[mem.lawHash].maxRoleHolders && index < mem.arrayLength - mem.numberRevokees) {
                    calldatas[index + mem.numberRevokees] =
                        abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId, _nominees[i]);
                    mem.accountElects[index] = _nominees[i];
                    index++;
                }
            }
        }
        stateChange = abi.encode(mem.accountElects);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address[] memory accountElects) = abi.decode(stateChange, (address[]));
        for (uint256 i; i < data[lawHash].electedAccounts.length; i++) {
            data[lawHash].electedAccounts.pop();
        }
        data[lawHash].electedAccounts = accountElects;
    }
}
