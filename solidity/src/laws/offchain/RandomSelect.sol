// // SPDX-License-Identifier: MIT

// ///////////////////////////////////////////////////////////////////////////////
// /// This program is free software: you can redistribute it and/or modify    ///
// /// it under the terms of the MIT Public License.                           ///
// ///                                                                         ///
// /// This is a Proof Of Concept and is not intended for production use.      ///
// /// Tests are incomplete and it contracts have not been audited.            ///
// ///                                                                         ///
// /// It is distributed in the hope that it will be useful and insightful,    ///
// /// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
// /// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
// ///////////////////////////////////////////////////////////////////////////////

// /// @notice Natspecs are tbi.
// ///
// /// @author 7Cedars

// pragma solidity 0.8.26;

// import { Law } from "../../Law.sol";
// import { Powers} from "../../Powers.sol";
// import { NominateMe } from "../state/NominateMe.sol";
// import {ConfirmedOwner} from "@chainlink/contracts@1.3.0/src/v0.8/shared/access/ConfirmedOwner.sol";
// import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts@1.3.0/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
// import {VRFV2PlusClient} from "@chainlink/contracts@1.3.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

// contract RandomSelect is Law, VRFV2PlusWrapperConsumerBase, ConfirmedOwner {
//     error RandomSelect__NumberToElectMustBeLessThanNumberNominees();
//     error RandomSelect__NumberToElectMustBeGreaterThan0();

//     uint256 private immutable ROLE_ID;
//     address[] public electedAccounts;
//     uint256 public numberToElect;

//     // Chainlink VRF event declarations.
//     event RequestSent(uint256 requestId, uint32 numWords);
//     event RequestFulfilled(
//         uint256 requestId,
//         uint256[] randomWords,
//         uint256 payment
//     );

//     // Chainlink VRF struct declarations.
//     struct RequestStatus {
//         uint256 paid; // amount paid in link
//         bool fulfilled; // whether the request has been successfully fulfilled
//         uint256[] randomWords;
//     }
//     mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

//     // past requests Id.
//     uint256[] public requestIds;
//     uint256 public lastRequestId;

//     constructor(
//         string memory name_,
//         string memory description_,
//         address payable powers_,
//         uint256 allowedRole_,
//         LawUtilities.Conditions memory config_,
//         uint256 roleId_,
//         address _wrapperAddress,
//         uint32 _callbackGasLimit,
//         uint16 _requestConfirmations
//     ) Law(name_, powers_, allowedRole_, config_) ConfirmedOwner(powers_) VRFV2PlusWrapperConsumerBase(_wrapperAddress) {
//         ROLE_ID = roleId_;
//          inputParams = abi.encode(
//             "uint256 NumberToElect" //  Number of accounts to elect.
//         );

//         if (_wrapperAddress == address(0)) revert RandomSelect__WrapperAddressCannotBe0();
//         requestConfig =
//             RequestConfig({callbackGasLimit: _callbackGasLimit, requestConfirmations: _requestConfirmations, numWords: 1});

//         emit Law__Initialized(address(this), name_, description_, powers_, allowedRole_, config_, "");
//     }

//     function handleRequest(address, /*caller*/ bytes memory lawCalldata, uint256 nonce)
//         public
//         view
//         virtual
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
//     {
//         // retrieve nominees.
//         address nominees = conditions.readStateFrom;
//         uint256 numberNominees = NominateMe(nominees).nomineesCount();
//         numberToElect = abi.decode(lawCalldata, (uint256));

//         // check that number to elect is less than number of nominees.
//         if (numberToElect > numberNominees) revert RandomSelect__NumberToElectMustBeLessThanNumberNominees();

//         // check that number to elect is greater than 0.
//         if (numberToElect < 1) revert RandomSelect__NumberToElectMustBeGreaterThan0();

//         // request random value here and handle rest of request in fulfillRandomWords.
//         _requestRandomWords();

//         // note: because targets & stateChange have length 0, executeLaw will not call _changeState or _replyPowers.
//         // we will call _changeState and _replyPowers through fulfillRandomWords.
//     }

//     function _changeState(bytes memory stateChange) internal override {
//         // clear electedAccounts.
//         for (uint256 i; i < electedAccounts.length; i++) {
//             electedAccounts.pop();
//         }
//         // decode stateChange and assign to electedAccounts.
//         (address[] memory elected) = abi.decode(stateChange, (address[]));
//         electedAccounts = elected;
//     }

//     ///////////////////////////////////////////////
//     //          CHAINLINK VRF FUNCTIONS          //
//     ///////////////////////////////////////////////
//     function _requestRandomWords() internal returns (uint256) {
//         bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
//             VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
//             );
//         (uint256 requestId, uint256 reqPrice) =
//             requestRandomnessPayInNative(
//                 requestConfig.callbackGasLimit,
//                 requestConfig.requestConfirmations,
//                 1,
//                 extraArgs
//                 );
//         s_requests[requestId] =
//             VRFRequestStatus({
//                 paid: reqPrice,
//                 randomWords: new uint256[](0),  // or 1? See example cards
//                 fulfilled: false,
//                 requester: powers
//                 });
//         requestIds.push(requestId);
//         lastRequestId = requestId;
//         emit RequestSent(requestId, 1);
//         return requestId;
//     }

//     function fulfillRandomWords(
//         uint256 _requestId,
//         uint256[] memory _randomWords
//     ) internal override {
//         // check that vrf request has been paid for.
//         require(s_requests[_requestId].paid > 0, "request not found");
//         s_requests[_requestId].fulfilled = true;
//         s_requests[_requestId].randomWords = _randomWords;

//         // if this passes: retrieve nominees.
//         address nominees = conditions.readStateFrom;
//         uint256 numberNominees = NominateMe(nominees).nomineesCount();
//         uint256 numberRevokees = electedAccounts.length;
//         // calculate length of target, value, and calldata arrays.
//         uint256 arrayLength = numberRevokees + numberToElect;

//         // setting up empty target, value, and calldata arrays.
//         (targets, values, calldatas) = LawUtilities.createEmptyArrays(arrayLength);
//         // setting up targets to be the powers contract.
//         for (uint256 i; i < arrayLength; i++) {
//             targets[i] = powers;
//         }
//         // setting up calls to revoke roles of previously elected accounts.
//         for (uint256 i; i < numberRevokees; i++) {
//             calldatas[i] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID, electedAccounts[i]);
//         }

//         address[] memory _nomineesSorted = NominateMe(nominees).getNominees();
//         for (uint256 i; i < numberToElect; i++) {
//             uint256 indexSelected = (_randomWords[0] / 10 ** (i + 1)) % (numberNominees - i);
//             address selectedNominee = _nomineesSorted[indexSelected];
//             // creating call, assigning role, adding nominee to elected, and removing nominee from nominees list.
//             calldatas[i] = abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, selectedNominee); // selector probably wrong. check later.
//             accountElects[i] = selectedNominee;
//             // note that we do not need to .pop the last item of the list, because it will never be accessed as the modulo decreases each run.
//             _nomineesSorted[indexSelected] = _nomineesSorted[numberNominees - (i + 1)];
//         }

//         // calculate actionId.
//         uint256 actionId = LawUtilities.hashActionId(address(this), abi.encode(numberToElect), nonce);

//         // change state and reply powers.
//         _changeState(abi.encode(accountElects));
//         _replyPowers(actionId, targets, values, calldatas);
//     }

//     function getRequestStatus(
//         uint256 _requestId
//     )
//         external
//         view
//         returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
//     {
//         require(s_requests[_requestId].paid > 0, "request not found");
//         RequestStatus memory request = s_requests[_requestId];
//         return (request.paid, request.fulfilled, request.randomWords);
//     }

//     /// @notice withdrawNative withdraws the amount specified in amount to the owner
//     /// @param amount the amount to withdraw, in wei
//     function withdrawNative(uint256 amount) external onlyOwner {
//         (bool success, ) = payable(owner()).call{value: amount}("");
//         // solhint-disable-next-line gas-custom-errors
//         require(success, "withdrawNative failed");
//     }

//     event Received(address, uint256);

//     receive() external payable {
//         emit Received(msg.sender, msg.value);
//     }

// }
