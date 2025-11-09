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

/// @notice A base contract that takes an input but does not execute any logic.
///
/// The logic:
/// - the lawCalldata includes targets[], values[], calldatas[] - that are sent straight to the Powers protocol without any checks.
/// - the lawCalldata is not executed.
///
/// @author 7Cedars,

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { TreasuryPools } from "../../helpers/TreasuryPools.sol";
 
contract SelectedPoolTransfer is Law {
    /// @dev Mapping from law hash to target contract address for each law instance
    mapping(bytes32 lawHash => address targetContract) public targetContract;
    /// @dev Mapping from law hash to target function selector for each law instance
    mapping(bytes32 lawHash => uint256 poolId) internal poolIds;

    /// @notice Constructor
    constructor() {
        bytes memory configParams = abi.encode("address TargetContract", "uint256 PoolId");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(uint16 index, string memory nameDescription, bytes memory inputParams, bytes memory config)
        public
        override
    {
        (address targetContract_, bytes4 targetFunction_, uint256 poolId_) =
            abi.decode(config, (address, bytes4, uint256));
        bytes32 lawHash = LawUtilities.hashLaw(msg.sender, index);
        
        poolIds[lawHash] = poolId_;
        targetContract[lawHash] = targetContract_;
        targetFunction[lawHash] = targetFunction_;
        
        inputParams = abi.encode("uint256 PoolId", "address payableTo", "uint256 Amount");

        super.initializeLaw(index, nameDescription, inputParams, config);
    }

    /// @notice Return calls provided by the user without modification
    /// @param lawCalldata The calldata containing targets, values, and calldatas arrays
    /// @return actionId The unique action identifier
    /// @return targets Array of target contract addresses
    /// @return values Array of ETH values to send
    /// @return calldatas Array of calldata for each call
    function handleRequest(
        address, /*caller*/
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
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);
        bytes32 lawHash =  LawUtilities.hashLaw(powers, lawId);

        uint256 poolId = poolIds[lawHash];

        (uint256 poolIdInput, , ) =
            abi.decode(lawCalldata, (uint256, address, uint256));

        if (poolIdInput != poolId) {
            revert("INVALID_POOL_ID");
        }
        
        // Send the calldata to the target function
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = targetContract[lawHash];
        calldatas[0] = abi.encodePacked(TreasuryPools.poolTransfer.selector, lawCalldata);
     
        return (actionId, targets, values, calldatas);
    }
}
