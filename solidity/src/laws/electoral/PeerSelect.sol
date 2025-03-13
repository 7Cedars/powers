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
import { LawUtils } from "../LawUtils.sol";
import { ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract PeerSelect is Law { 
    using ShortStrings for *;

    uint256 public immutable MAX_ROLE_HOLDERS;
    uint32 public immutable ROLE_ID;
    mapping(address => uint48) public _elected;
    address[] public _electedSorted;

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        uint256 maxRoleHolders_,
        uint32 roleId_
    )  {
        LawUtils.checkConstructorInputs(powers_, allowedRole_);
        name = name_.toShortString();
        powers = powers_;
        allowedRole = allowedRole_;
        config = config_;

        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
        
        bytes memory params = abi.encode(
            "uint256 NomineeIndex", 
            "bool Assign"
        );
        emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, params);
    }

    function handleRequest(address /*initiator*/, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        address nominees = config.readStateFrom;  
        (uint256 index, bool assign) = abi.decode(lawCalldata, (uint256, bool));

        actionId = LawUtils.hashActionId(address(this), lawCalldata, descriptionHash);
        (targets, values, calldatas) = LawUtils.createEmptyArrays(1);
        targets[0] = powers;

        if (assign) {
            if (_electedSorted.length >= MAX_ROLE_HOLDERS) {
                revert ("Max role holders reached.");
            }
            address accountElect = NominateMe(nominees).nomineesSorted(index);
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, accountElect);
        } else {
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID, _electedSorted[index]);
        }
        return (actionId, targets, values, calldatas, "");
    }

    function _changeState(bytes memory stateChange) internal override {
        (uint256 index, bool assign) = abi.decode(stateChange, (uint256, bool));

        if (assign) {
            address nominees = config.readStateFrom; 
            address accountElect = NominateMe(nominees).nomineesSorted(index);
            _electedSorted.push(accountElect);
        } else {
            _electedSorted[index] = _electedSorted[_electedSorted.length - 1];
            _electedSorted.pop();
        }
    }
}
