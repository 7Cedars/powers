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

/// @notice Adopt a set of laws configured at initialization.
/// @dev Builds calls to `IPowers.adoptLaw` for each configured law. No self-destruction occurs.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../LawUtilities.sol";
import { IPowers } from "../../interfaces/IPowers.sol";
import { PowersTypes } from "../../interfaces/PowersTypes.sol";

contract AdoptLaws is Law {
    /// @notice Constructor for AdoptLaws law
    struct Data {
        address[] laws;
        bytes[] lawInitDatas;
    }

    mapping(bytes32 lawHash => Data data) internal data;

    constructor() {
        bytes memory configParams = abi.encode("address[] laws", "bytes[] lawInitDatas");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        // Set UI-exposed input parameters: laws and lawInitDatas

        (address[] memory laws_, bytes[] memory lawInitDatas_) = abi.decode(config, (address[], bytes[]));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        data[lawHash] = Data({ laws: laws_, lawInitDatas: lawInitDatas_ });

        inputParams = abi.encode();
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls to adopt the configured laws
    /// @param lawCalldata Unused for this law
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        Data memory data_ = data[LawUtilities.hashLaw(powers, lawId)];

        // Create arrays for the calls to adoptLaw
        uint256 length = data_.laws.length;
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(length);
        for (uint256 i; i < length; i++) {
            PowersTypes.LawInitData memory lawInitData = abi.decode(data_.lawInitDatas[i], (PowersTypes.LawInitData));
            targets[i] = powers;
            calldatas[i] = abi.encodeWithSelector(IPowers.adoptLaw.selector, lawInitData);
        }
        return (actionId, targets, values, calldatas);
    }

    function getData(bytes32 lawHash) public view returns (Data memory) {
        return data[lawHash];
    }
}
