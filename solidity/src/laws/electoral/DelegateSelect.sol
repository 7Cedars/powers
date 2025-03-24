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
///
///
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
/// - doess not have to role restricted.
/// - translates a simple token based voting system to separated powers.
/// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers} from "../../Powers.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { NominateMe } from "../state/NominateMe.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract DelegateSelect is Law {
    mapping(bytes32 lawHash => address erc20Token) public erc20Token;
    mapping(bytes32 lawHash => uint256 maxRoleHolders) public maxRoleHolders;
    mapping(bytes32 lawHash => uint256 roleId) public roleId;
    mapping(bytes32 lawHash => address[] electedAccounts) public electedAccounts;

    constructor(
        string memory name_,
        string memory description_
    ) Law(name_) {
        bytes memory configParams = abi.encode(
            "address erc20Token",
            "uint256 maxRoleHolders",
            "uint256 roleId"
        );
        emit Law__Deployed(name_, description_, configParams);
    }

    function initializeLaw(uint16 index, Conditions memory conditions, bytes memory config, bytes memory inputParams) public override {
        (address erc20Token_, uint256 maxRoleHolders_, uint256 roleId_) = abi.decode(config, (address, uint256, uint256));
        erc20Token[hashLaw(msg.sender, index)] = erc20Token_; // £todo interface should be checked here.
        maxRoleHolders[hashLaw(msg.sender, index)] = maxRoleHolders_;
        roleId[hashLaw(msg.sender, index)] = roleId_;

        inputParams = abi.encode(
            "bool Assign", 
            "address Account"
            );

        super.initializeLaw(index, conditions, config, inputParams);
    }

    function handleRequest(address /*caller*/, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {  
        bytes32 lawHash = hashLaw(msg.sender, lawId);
        actionId = hashActionId(lawId, lawCalldata, nonce);
        LawData memory law = initialisedLaws[lawHash];

        // step 1: setting up array for revoking & assigning roles.
        uint16 nominateMeId = law.conditions.readStateFrom;
        address nominateMeAddress = Powers(payable(msg.sender)).getActiveLawAddress(nominateMeId);
        

        address[] memory accountElects;
        uint256 numberNominees = NominateMe(nominateMeAddress).nomineesCount(hashLaw(msg.sender, nominateMeId));
        uint256 numberRevokees = electedAccounts[lawHash].length;
        uint256 arrayLength =
            numberNominees < maxRoleHolders[lawHash] ? numberRevokees + numberNominees : numberRevokees + maxRoleHolders[lawHash];
        
        (targets, values, calldatas) = createEmptyArrays(arrayLength);
        for (uint256 i; i < arrayLength; i++) {
            targets[i] = msg.sender;
        }
        // step 2: calls to revoke roles of previously elected accounts & delete array that stores elected accounts.
        for (uint256 i; i < numberRevokees; i++) {
            calldatas[i] = abi.encodeWithSelector(Powers.revokeRole.selector, roleId[lawHash], electedAccounts[lawHash][i]);
        }

        // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
        if (numberNominees < maxRoleHolders[lawHash]) {
            accountElects = new address[](numberNominees);
            for (uint256 i; i < numberNominees; i++) {
                address accountElect = NominateMe(nominateMeAddress).nomineesSorted(hashLaw(msg.sender, nominateMeId), i);
                calldatas[i + numberRevokees] =
                    abi.encodeWithSelector(Powers.assignRole.selector, roleId[lawHash], accountElect);
                accountElects[i] = accountElect;
            }
        
        // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
        } else {
            // retrieve balances of delegated votes of nominees.
            accountElects = new address[](maxRoleHolders[lawHash]);
            uint256[] memory _votes = new uint256[](numberNominees); 
            address[] memory _nominees = NominateMe(nominateMeAddress).getNominees(hashLaw(msg.sender, nominateMeId));
            
            for (uint256 i; i < numberNominees; i++) { 
                _votes[i] = ERC20Votes(erc20Token[lawHash]).getVotes(_nominees[i]);
            }

            // note how the following mechanism works:
            // a. we add 1 to each nominee's position, if we found a account that holds more tokens.
            // b. if the position is greater than MAX_ROLE_HOLDERS, we break. (it means there are more accounts that have more tokens than MAX_ROLE_HOLDERS)
            // c. if the position is less than MAX_ROLE_HOLDERS, we assign the roles.
            uint256 index;
            for (uint256 i; i < numberNominees; i++) {
                uint256 rank;
                // a: loop to assess ranking.
                for (uint256 j; j < numberNominees; j++) {
                    if (j != i && _votes[j] >= _votes[i]) {
                        rank++;
                        if (rank > maxRoleHolders[lawHash]) break; // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold.
                    }
                }
                // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                if (rank < maxRoleHolders[lawHash] && index < arrayLength - numberRevokees) {
                    calldatas[index + numberRevokees] =
                        abi.encodeWithSelector(Powers.assignRole.selector, roleId[lawHash], _nominees[i]);
                    accountElects[index] = _nominees[i];
                    index++;
                }
            }
        }
        stateChange = abi.encode(accountElects);

        return (actionId, targets, values, calldatas, stateChange);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address[] memory elected) = abi.decode(stateChange, (address[]));
        for (uint256 i; i < electedAccounts[lawHash].length; i++) {
            electedAccounts[lawHash].pop();
        }
        electedAccounts[lawHash] = elected;
    }
}
