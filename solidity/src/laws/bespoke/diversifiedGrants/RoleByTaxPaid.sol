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
pragma solidity 0.8.26;

import { DirectSelect } from "../../electoral/DirectSelect.sol";
import { Erc20TaxedMock } from "../../../../test/mocks/Erc20TaxedMock.sol";

contract RoleByTaxPaid is DirectSelect {
    address public erc20TaxedMock;
    uint256 public thresholdTaxPaid;

    constructor(
        // standard
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        // direct select
        uint32 roleId_,
        // the taxed token to check
        address erc20TaxedMock_,
        uint256 thresholdTaxPaid_
    ) DirectSelect(name_, description_, powers_, allowedRole_, config_, roleId_) {
        erc20TaxedMock = erc20TaxedMock_;
        thresholdTaxPaid = thresholdTaxPaid_;
    }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: decode the calldata.
        (bool revoke, address account) = abi.decode(lawCalldata, (bool, address));

        // step 1: check if initiator paid sufficient taxes in the _previous_ epoch.
        uint48 epochDuration = Erc20TaxedMock(erc20TaxedMock).epochDuration();
        uint48 currentEpoch = uint48(block.number) / epochDuration;
        if (currentEpoch == 0) {
            revert ("No finished epoch yet."); 
        }

        uint256 taxPaid = Erc20TaxedMock(erc20TaxedMock).getTaxLogs(uint48(block.number) - epochDuration, account);
        // step 2: revert of action is not eligible
        if (!revoke && taxPaid < thresholdTaxPaid) {
            revert ("Not eligible."); 
        }
        if (revoke && taxPaid >= thresholdTaxPaid) {
            revert ("Is eligible."); 
        }

        // step 3: call super
        return super.simulateLaw(initiator, lawCalldata, descriptionHash);
    }
}
