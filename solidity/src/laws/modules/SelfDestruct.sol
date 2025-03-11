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

/// @notice Natspecs WIP
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers} from "../../Powers.sol";

abstract contract SelfDestruct is Law {
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange) =
            super.simulateLaw(initiator, lawCalldata, descriptionHash);

        // creating new arrays
        address[] memory targetsNew = new address[](targets.length + 1);
        uint256[] memory valuesNew = new uint256[](values.length + 1);
        bytes[] memory calldatasNew = new bytes[](calldatas.length + 1);

        // pasting in old arrays. This method is super inefficient. Is there no other way of doing this?
        for (uint256 i; i < targets.length; i++) {
            targetsNew[i] = targets[i];
            valuesNew[i] = values[i];
            calldatasNew[i] = calldatas[i];
        }

        // adding self destruct data to array
        targetsNew[targets.length] = powers;
        valuesNew[values.length] = 0;
        calldatasNew[calldatas.length] = abi.encodeWithSelector(Powers.revokeLaw.selector, address(this));

        // return new arrays
        return (targetsNew, valuesNew, calldatasNew, stateChange);
    }
}
