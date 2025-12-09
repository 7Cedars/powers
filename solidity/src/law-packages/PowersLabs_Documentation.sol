// SPDX-License-Identifier: MIT

/// @notice An example implementation of a Law Package that adopts multiple laws into the Powers protocol.
/// @dev It is meant to be adopted through the AdoptLaws law, and then be executed to adopt multiple laws in a single transaction.
/// @dev The law self-destructs after execution.
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

// For now this LawPackage only adopts a new URI. Child organisaiton specific governance flows will be added later. 

contract PowerLabs_Documentation is Law {
    struct Mem {
        uint16 lawCount;
        address safeProxy;
        bytes signature; 
    }
    address[] private lawAddresses;
    address private allowanceModuleAddress;
    uint16 constant public NUMBER_OF_CALLS = 7; // total number of calls in handleRequest
    uint48 immutable public blocksPerHour;
    
    // in this case lawAddresses should be [statementOfIntent, SafeExecTransaction, PresetSingleAction, SafeAllowanceAction]
    constructor(uint48 blocksPerHour_, address[] memory lawDependencies, address allowanceModuleAddress_) {
        blocksPerHour = blocksPerHour_;
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
    function handleRequest(address, /*caller*/ address powers, uint16 lawId, bytes memory lawCalldata, uint256 nonce)
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
            uint256(0),                // s = 0
            uint8(1)                  // v = 1 This is a type 1 call. See Safe.sol for details.
        );

        (targets, values, calldatas) = LawUtilities.createEmptyArrays(NUMBER_OF_CALLS);

        /////////////////////////////////////////////////////////////////////////////////////////////////////
        // DIRECT CALLS TO POWERS CONTRACT TO ADOPT THE ALLOWANCE MODULE AND SET THE SAFEPROXY AS TREASURY //
        /////////////////////////////////////////////////////////////////////////////////////////////////////

        for (uint i; i < NUMBER_OF_CALLS; i++) {
            targets[i] = powers;
        }

        // 1: adopt new uri. 
        calldatas[0] = abi.encodeWithSelector(IPowers.setUri.selector, "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiaiji5cy5qnm7t4lpqmvbln5h2rknajznqccvvvo6biuvlf4bvmye");

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
 