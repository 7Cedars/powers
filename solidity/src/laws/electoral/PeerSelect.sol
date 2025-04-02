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

contract PeerSelect is Law {
    struct Data {
        uint256 maxRoleHolders;
        uint256 roleId;
        address[] elected;
        address[] electedSorted;
    }

    mapping(bytes32 lawHash => Data) public data;

    constructor(string memory name_) {
        LawUtilities.checkStringLength(name_);
        name = name_;
        bytes memory configParams = abi.encode("uint256 maxRoleHolders", "uint256 roleId");
        emit Law__Deployed(name_, configParams);
    }

    function initializeLaw(
        uint16 index,
        Conditions memory conditions,
        bytes memory config,
        bytes memory inputParams,
        string memory description
    ) public override {
        (uint256 maxRoleHolders_, uint256 roleId_) = abi.decode(config, (uint256, uint256));

        data[LawUtilities.hashLaw(msg.sender, index)] = Data({
            maxRoleHolders: maxRoleHolders_,
            roleId: roleId_,
            elected: new address[](0),
            electedSorted: new address[](0)
        });

        super.initializeLaw(index, conditions, config, abi.encode("uint256 NomineeIndex", "bool Assign"), description);
    }

    function handleRequest(address, /*caller*/ uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
        (address nomineesAddress, bytes32 lawHash,) = Powers(payable(msg.sender)).getActiveLaw(lawId);
        address[] memory nominees = NominateMe(nomineesAddress).getNominees(lawHash);
        (uint256 index, bool assign) = abi.decode(lawCalldata, (uint256, bool));

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = msg.sender;

        if (assign) {
            if (data[lawHash].electedSorted.length == data[lawHash].maxRoleHolders) {
                revert("Max role holders reached.");
            }
            address accountElect = nominees[index];
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, data[lawHash].roleId, accountElect);
        } else {
            calldatas[0] = abi.encodeWithSelector(
                Powers.revokeRole.selector, data[lawHash].roleId, data[lawHash].electedSorted[index]
            );
        }
        return (actionId, targets, values, calldatas, lawCalldata);
    }

    function _changeState(bytes32 lawHash, bytes memory stateChange) internal override {
        (uint256 index, bool assign) = abi.decode(stateChange, (uint256, bool));

        if (assign) {
            uint16 nomineesId = conditionsLaws[lawHash].readStateFrom;
            (address nomineesContract,,) = Powers(payable(msg.sender)).getActiveLaw(nomineesId);
            address accountElect = NominateMe(nomineesContract).getNominees(lawHash)[index];
            data[lawHash].elected.push(accountElect);
            data[lawHash].electedSorted.push(accountElect);
        } else {
            data[lawHash].electedSorted[index] = data[lawHash].electedSorted[data[lawHash].electedSorted.length - 1];
            data[lawHash].electedSorted.pop();
        }
    }
}
