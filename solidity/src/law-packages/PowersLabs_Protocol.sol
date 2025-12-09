// SPDX-License-Identifier: MIT

/// @notice An example implementation of a Law Package that adopts multiple laws into the Powers protocol.
/// It is meant to be adopted through the AdoptLaws law, and then be executed to adopt multiple laws in a single transaction.
/// The law self-destructs after execution.
///
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../Law.sol";
import { LawUtilities } from "../libraries/LawUtilities.sol";
import { IPowers } from "../interfaces/IPowers.sol";
import { Powers } from "../Powers.sol";
import { PowersTypes } from "../interfaces/PowersTypes.sol";
import { ILaw } from "../interfaces/ILaw.sol";
import { IERC165 } from "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { SafeExecTransaction } from "../laws/integrations/SafeExecTransaction.sol";

// This LawPackage adopts the following governance paths:
// path 0 + 1: init Allowance Module.
// path 2: adopt new child.
// path 3: assign allowance to child.

contract PowerLabs_Protocol is Law {
    struct Mem {
        uint16 lawCount;
        address safeProxy;
        bytes signature;
    }
    address[] private lawAddresses;
    address private allowanceModuleAddress;
    uint16 public constant NUMBER_OF_CALLS = 7; // total number of calls in handleRequest
    uint48 public immutable BLOCKS_PER_HOUR;

    // in this case lawAddresses should be [statementOfIntent, SafeExecTransaction, PresetSingleAction, SafeAllowanceAction]
    constructor(uint48 BLOCKS_PER_HOUR_, address[] memory lawDependencies, address allowanceModuleAddress_) {
        BLOCKS_PER_HOUR = BLOCKS_PER_HOUR_;
        lawAddresses = lawDependencies;
        allowanceModuleAddress = allowanceModuleAddress_;

        emit Law__Deployed(abi.encode());
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        inputParams = abi.encode("address SafeProxy");
        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Build calls to adopt the configured laws
    /// @param lawCalldata Unused for this law
    function handleRequest(
        address,
        /*caller*/
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    )
        public
        view
        override
        returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        Mem memory mem;

        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        mem.lawCount = Powers(powers).lawCounter();
        // (mem.safeProxy) = abi.decode(lawCalldata, (address));
        mem.signature = abi.encodePacked(
            uint256(uint160(powers)), // r = address of the signer (powers contract)
            uint256(0), // s = 0
            uint8(1) // v = 1 This is a type 1 call. See Safe.sol for details.
        );

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(NUMBER_OF_CALLS);

        /////////////////////////////////////////////////////////////////////////////////////////////////////
        // DIRECT CALLS TO POWERS CONTRACT TO ADOPT THE ALLOWANCE MODULE AND SET THE SAFEPROXY AS TREASURY //
        /////////////////////////////////////////////////////////////////////////////////////////////////////

        for (uint256 i; i < NUMBER_OF_CALLS; i++) {
            targets[i] = powers;
        }

        // 1: adopt new uri.
        calldatas[0] = abi.encodeWithSelector(
            IPowers.setUri.selector,
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreigye2u5mzkfhxtcmxl4plrkhv2hzkvvctvcw64pc5ogkxtix35ggi"
        );

        // 2: assign labels to roles - same as in PowerLabs Constitution.
        calldatas[1] = abi.encodeWithSelector(IPowers.labelRole.selector, 1, "Funders");
        calldatas[2] = abi.encodeWithSelector(IPowers.labelRole.selector, 2, "Doc Contributors");
        calldatas[3] = abi.encodeWithSelector(IPowers.labelRole.selector, 3, "Frontend Contributors");
        calldatas[4] = abi.encodeWithSelector(IPowers.labelRole.selector, 4, "Protocol Contributors");
        calldatas[5] = abi.encodeWithSelector(IPowers.labelRole.selector, 5, "Members");

        // 3: set final call to self-destruct the LawPackage after adopting the laws
        calldatas[NUMBER_OF_CALLS - 1] = abi.encodeWithSelector(IPowers.revokeLaw.selector, lawId);

        //////////////////////////////////////////////////////////////////////////
        //              GOVERNANCE FLOW FOR ADOPTING DELEGATES                  //
        //////////////////////////////////////////////////////////////////////////
    }
}
