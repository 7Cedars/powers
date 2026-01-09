// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Powers } from "../Powers.sol";
import { PowersTypes } from "../interfaces/PowersTypes.sol";

/// @title Powers Factory
/// @notice Factory contract to deploy specific types of Powers implementations
contract PowersFactory is PowersTypes {
    
    MandateInitData[] public mandateInitData;
    uint256 public immutable maxCallDataLength;
    uint256 public immutable maxReturnDataLength;
    uint256 public immutable maxExecutionsLength;
    
    address public latestDeployment;

    event PowersDeployed(address indexed powersAddress, string name, string uri);

    constructor(
        MandateInitData[] memory _mandateInitData,
        uint256 _maxCallDataLength,
        uint256 _maxReturnDataLength,
        uint256 _maxExecutionsLength
    ) {
        for(uint i = 0; i < _mandateInitData.length; i++) {
            mandateInitData.push(_mandateInitData[i]);
        }
        maxCallDataLength = _maxCallDataLength;
        maxReturnDataLength = _maxReturnDataLength;
        maxExecutionsLength = _maxExecutionsLength;
    }

    function deployPowers(string memory name, string memory uri) external returns (address) {
        Powers powers = new Powers(
            name,
            uri,
            maxCallDataLength,
            maxReturnDataLength,
            maxExecutionsLength
        );

        // Constitute the powers instance with the stored mandate data
        powers.constitute(mandateInitData);

        // Transfer admin rights to the caller
        // 1. Assign ADMIN_ROLE to msg.sender
        powers.assignRole(powers.ADMIN_ROLE(), msg.sender);
        // 2. Revoke ADMIN_ROLE from this factory
        powers.revokeRole(powers.ADMIN_ROLE(), address(this));

        latestDeployment = address(powers);
        
        emit PowersDeployed(address(powers), name, uri);

        return address(powers);
    }

    function getConstructionParams() external view returns (
        MandateInitData[] memory,
        uint256,
        uint256,
        uint256
    ) {
        return (mandateInitData, maxCallDataLength, maxReturnDataLength, maxExecutionsLength);
    }

    function getLatestDeployment() external view returns (address) {
        return latestDeployment;
    }
}
