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

abstract contract ThrottlePerAccount is Law { 
    mapping(address initiator => uint48 blockNumber) public lastTransaction;

    function checksAtExecute(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
    {
        if (uint48(block.number) - lastTransaction[initiator] < _delay()) {
            revert ("Delay not passed");
        }
        super.checksAtExecute(initiator, lawCalldata, descriptionHash);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        address initiator = abi.decode(stateChange, (address));
        lastTransaction[initiator] = uint48(block.number);
    }

    function _delay() internal view virtual returns (uint48) {
        return 0;
    }
}
