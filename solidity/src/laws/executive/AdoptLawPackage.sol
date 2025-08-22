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
    constructor() {
        emit Law__Deployed("");
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        Conditions memory conditions,
        bytes memory config
    ) public override {
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

        (address[] memory newLaws, bytes[] memory lawInitDatas) = abi.decode(lawCalldata, (address[], bytes[]));

        // send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(newLaws.length);
        for (uint256 i = 0; i < newLaws.length; i++) {
            PowersTypes.LawInitData memory lawInitData = abi.decode(lawInitDatas[i], (PowersTypes.LawInitData));
            targets[i] = powers;
            calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
        }

        return (actionId, targets, values, calldatas, "");
    }
}
