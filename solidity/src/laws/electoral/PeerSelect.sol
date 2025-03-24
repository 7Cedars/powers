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

/// @notice This contract ....
///

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers} from "../../Powers.sol";
import { NominateMe } from "../state/NominateMe.sol";
import { LawUtilities } from "../../LawUtilities.sol";

contract PeerSelect is Law { 
    // struct Data {

    // }
    
    mapping(bytes32 lawHash => uint256 maxRoleHolders) public MAX_ROLE_HOLDERS;
    mapping(bytes32 lawHash => uint256 roleId) public ROLE_ID;
    mapping(bytes32 lawHash => address[] _elected) public _elected;
    mapping(bytes32 lawHash => address[] _electedSorted) public _electedSorted;

    constructor(
        string memory name_,
        string memory description_ 
    ) Law(name_) {
        bytes memory configParams = abi.encode(
            "uint256 maxRoleHolders",
            "uint256 roleId"
        );
        emit Law__Deployed(name_, description_, configParams);
    }
    
    function initializeLaw(uint16 index, Conditions memory conditions, bytes memory config, bytes memory inputParams) public override {
        (uint256 maxRoleHolders_, uint256 roleId_) = abi.decode(config, (uint256, uint256));
        MAX_ROLE_HOLDERS[hashLaw(msg.sender, index)] = maxRoleHolders_;
        ROLE_ID[hashLaw(msg.sender, index)] = roleId_;

        inputParams = abi.encode(
            "uint256 NomineeIndex", 
            "bool Assign"
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
        address[] memory nominees = NominateMe(
            Powers(payable(msg.sender)).getActiveLawAddress(
                initialisedLaws[lawHash].conditions.readStateFrom
            )).getNominees(lawHash);
        (uint256 index, bool assign) = abi.decode(lawCalldata, (uint256, bool));

        actionId = hashActionId(lawId, lawCalldata, nonce);
        (targets, values, calldatas) = createEmptyArrays(1);
        targets[0] = msg.sender;

        if (assign) {
            if (_electedSorted[lawHash].length == MAX_ROLE_HOLDERS[lawHash]) {
                revert ("Max role holders reached.");
            }
            address accountElect = nominees[index];
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID[lawHash], accountElect);
        } else {
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID[lawHash], _electedSorted[lawHash][index]);
        }
        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (uint256 index, bool assign) = abi.decode(stateChange, (uint256, bool));

        if (assign) {
            uint16 nomineesId = initialisedLaws[lawHash].conditions.readStateFrom; 
            address nomineesContract = Powers(payable(msg.sender)).getActiveLawAddress(nomineesId);
            address accountElect = NominateMe(nomineesContract).getNominees(lawHash)[index];
            _electedSorted[lawHash].push(accountElect);
        } else {
            _electedSorted[lawHash][index] = _electedSorted[lawHash][_electedSorted[lawHash].length - 1];
            _electedSorted[lawHash].pop();
        }
    }
}
