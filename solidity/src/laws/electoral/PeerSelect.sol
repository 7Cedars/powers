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
import { Powers } from "../../Powers.sol";
import { NominateMe } from "../state/NominateMe.sol";
import { LawUtilities } from "../../LawUtilities.sol";

// import "forge-std/Test.sol"; // only for testing

contract PeerSelect is Law {
    struct Data {
        uint256 maxRoleHolders;
        uint256 roleId;
        address[] elected;
        address[] electedSorted;
    }

    struct Mem {
        bytes32 lawHash;
        uint16 nomineesId;
        address nomineesAddress;
        bytes32 nomineesHash;
        address[] nominees;
        uint256 index;
        bool assign; 
        uint48 hasRoleSince;
    }

    mapping(bytes32 lawHash => Data) public data;

    constructor() {
        bytes memory configParams = abi.encode("uint256 maxRoleHolders", "uint256 roleId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions, 
        bytes memory config
    ) public override {
        (uint256 maxRoleHolders_, uint256 roleId_) = abi.decode(config, (uint256, uint256));

        data[LawUtilities.hashLaw(msg.sender, index)] = Data({
            maxRoleHolders: maxRoleHolders_,
            roleId: roleId_,
            elected: new address[](0),
            electedSorted: new address[](0)
        });

        super.initializeLaw(index, nameDescription, abi.encode("uint256 NomineeIndex", "bool Assign"), conditions, config);
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
        Mem memory mem;

        // step 0: create actionId & decode the calldata
        mem.lawHash = LawUtilities.hashLaw(powers, lawId);
        
        mem.nomineesId = laws[mem.lawHash].conditions.readStateFrom;
        (mem.nomineesAddress, mem.nomineesHash ,) = Powers(payable(powers)).getActiveLaw(mem.nomineesId);
        mem.nominees = NominateMe(mem.nomineesAddress).getNominees(mem.nomineesHash);
        (mem.index, mem.assign) = abi.decode(lawCalldata, (uint256, bool));
        mem.hasRoleSince = Powers(payable(powers)).hasRoleSince(mem.nominees[mem.index], data[mem.lawHash].roleId);

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = powers;

        if (mem.assign) {
            if (mem.hasRoleSince != 0) {
                revert("Account already has role.");
            }
            if (data[mem.lawHash].electedSorted.length == data[mem.lawHash].maxRoleHolders) {
                revert("Max role holders reached.");
            }
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, data[mem.lawHash].roleId,  mem.nominees[mem.index]);
        } else {
            if (mem.hasRoleSince == 0) {
                revert("Account does not have role.");
            }
            calldatas[0] = abi.encodeWithSelector(
                Powers.revokeRole.selector, data[mem.lawHash].roleId, mem.nominees[mem.index]
            );
        }

        lawCalldata = abi.encode(mem.nominees[mem.index], mem.index, mem.assign);

        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (address accountElect, uint256 index, bool assign) = abi.decode(stateChange, (address, uint256, bool));

        if (assign) {
            data[lawHash].elected.push(accountElect);
            data[lawHash].electedSorted.push(accountElect);
        } else {
            data[lawHash].electedSorted[index] = data[lawHash].electedSorted[data[lawHash].electedSorted.length - 1];
            data[lawHash].electedSorted.pop();
        }
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
