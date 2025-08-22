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

/// @notice Adopts a single law that can be executed by a preset role Id. - no other conditions are added.   
/// It is best combined with a 'presetAction' law that deploys multiple new laws and then self destructs. 
/// See the "RUN THIS LAW FIRST: ..." laws in createLawInitData.ts for an example.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { ILaw } from "../../interfaces/ILaw.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

contract AdoptLawPackage is Law {
    /// @notice constructor of the law
    /// @param name_ the name of the law.

    struct Data {
        uint256 roleId;
    }
    mapping(bytes32 lawHash => Data) public data;

    constructor() {
        config = abi.encode(
            "uint256 roleId"
        );

        emit Law__Deployed("");
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions,
        bytes memory config
    ) public override {
        (uint256 roleId) = abi.decode(config, (uint256));

        data[lawHash] = Data({
            roleId: roleId
        });

        inputParams = abi.encode(
            "address[] laws"
            "bytes[] lawInitDatas"
        );

        super.initializeLaw(index, nameDescription, inputParams, conditions, config);
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function handleRequest(address caller, address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (
            uint256 actionId,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes memory stateChange
        )
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        (address[] memory newLaws, PowersTypes.LawInitData[] memory lawInitDatas) = abi.decode(lawCalldata, (address[], PowersTypes.LawInitData[]));

        // send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(newLaws.length);
        for (uint256 i = 0; i < newLaws.length; i++) {
            targets[i] = powers;
            calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitDatas[i]);
        }

        return (actionId, targets, values, calldatas, "");
    }
}
