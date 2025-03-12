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

// import { Law } from "../../../Law.sol";
// import { Powers} from "../../../Powers.sol";
// import { Erc721Mock } from "../../../../test/mocks/Erc721Mock.sol";

// contract RevokeMembership is Law {
//     uint32 constant ROLE_ID = 1;

//     address public erc721Token;

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint32 allowedRole_,
//         LawConfig memory config_,
//         address erc721Token_
//     )  {
//         inputParams = abi.encode("uint256 TokenId", "address Account"); // tokenId, account
//         erc721Token = erc721Token_;
//     }

//     /// @notice execute the law.
//     /// @param lawCalldata the calldata _without function signature_ to send to the function.
//     function handleRequest(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
//         public
//         view
//         virtual
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {
//         (uint256 tokenId, address account) = abi.decode(lawCalldata, (uint256, address));
//         targets = new address[](2);
//         values = new uint256[](2);
//         calldatas = new bytes[](2);
//         stateChange = abi.encode("");

//         // action 0: revoke role member in Separated powers
//         targets[0] = powers;
//         calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID, account);

//         // action 1: burn the access token of the member, so they cannot become member again.
//         targets[1] = erc721Token;
//         calldatas[1] = abi.encodeWithSelector(Erc721Mock.burnNFT.selector, tokenId, account);

//         return (targets, values, calldatas, stateChange);
//     }
// }
