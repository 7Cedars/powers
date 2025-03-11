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

contract PeerSelect is Law { 
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
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
        string[] memory paramArray = new string[](2);
        inputParams = abi.encode(
            "uint256 NomineeIndex", 
            "bool Revoke"); 
    }

    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        address nominees = config.readStateFrom;  
        (uint256 index, bool revoke) = abi.decode(lawCalldata, (uint256, bool));

        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = powers;

        if (revoke) {
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID, _electedSorted[index]);
        }

        if (!revoke) {
            if (_electedSorted.length >= MAX_ROLE_HOLDERS) {
                revert ("Max role holders reached.");
            }
            address accountElect = NominateMe(nominees).nomineesSorted(index);
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, accountElect);
        }

        return (targets, values, calldatas, lawCalldata);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (uint256 index, bool revoke) = abi.decode(stateChange, (uint256, bool));

        if (revoke) {
            _electedSorted[index] = _electedSorted[_electedSorted.length - 1];
            _electedSorted.pop();
        } else {
            address nominees = config.readStateFrom; 
            address accountElect = NominateMe(nominees).nomineesSorted(index);
            _electedSorted.push(accountElect);
        }
    }
}
