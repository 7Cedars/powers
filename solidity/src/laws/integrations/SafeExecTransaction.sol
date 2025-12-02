// SPDX-License-Identifier: MIT
/// @notice A law to execute a transaction on a Gnosis Safe, assuming the Powers contract is an owner.
/// @dev This law uses the v=1 signature type, where the transaction executor (`msg.sender` to the Safe)
///      is an owner, thus providing its own approval by making the call.
/// @author 7Cedars

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { LawUtilities } from "../../libraries/LawUtilities.sol";
import { Safe } from "lib/safe-smart-account/contracts/Safe.sol";
import { Enum } from "lib/safe-smart-account/contracts/common/Enum.sol";

contract SafeExecTransaction is Law {
    /// @dev Configuration for this law adoption.
    struct ConfigData {
        address safe; // The Safe address to execute the transaction on.
    }

    /// @dev Mapping from law hash to its configuration.
    mapping(bytes32 => ConfigData) public lawConfig;

    /// @notice Exposes the expected input parameters for UIs during deployment.
    constructor() {
        bytes memory configParams =
            abi.encode("string[] inputParams", "address safe");
        emit Law__Deployed(configParams);
    }

    function initializeLaw(
        uint16 index,
        string memory nameDescription,
        bytes memory inputParams,
        bytes memory config
    ) public override {
        (string[] memory inputParamsRaw, address safe) = abi.decode(config, (string[], address));
        bytes32 lawHash_ = LawUtilities.hashLaw(msg.sender, index);
        lawConfig[lawHash_] = ConfigData({ 
            safe: safe
        });
        super.initializeLaw(index, nameDescription, abi.encode(inputParamsRaw), config);
    }

    /// @notice Prepares a transaction to be executed by the configured Gnosis Safe.
    /// @dev This function decodes the internal transaction parameters from `lawCalldata` and
    ///      constructs a `v=1` signature where `powers` is the designated signer.
    ///      This is valid only if the `powers` contract is an owner of the target Safe.
    /// @param lawCalldata The ABI-encoded parameters for the internal Safe transaction:
    ///                    (address to, uint256 value, bytes data, Enum.Operation operation).
    /// @return actionId The unique action identifier.
    /// @return targets An array containing the Safe contract address.
    /// @return values An array containing 0, as no ETH is sent to the Safe directly.
    /// @return calldatas An array with the encoded `execTransaction` call for the Safe.
    function handleRequest(
        address, /*caller*/
        address powers,
        uint16 lawId,
        bytes memory lawCalldata,
        uint256 nonce
    ) public view override returns (uint256 actionId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas) {
        actionId = LawUtilities.hashActionId(lawId, lawCalldata, nonce);

        // Decode the parameters for the transaction that the Safe will execute.
        (address to, uint256 value, bytes memory data) =
            abi.decode(lawCalldata, (address, uint256, bytes));

        bytes32 lawHash_ = LawUtilities.hashLaw(powers, lawId);
        address safeAddress = lawConfig[lawHash_].safe;

        // Construct the `v=1` signature.
        // This is not a cryptographic signature but a signal to the Safe contract.
        // It indicates that the `msg.sender` of this transaction (the `powers` contract)
        // is an owner and is providing its own approval by executing the transaction.
        // r = address of the signer (powers contract)
        // s = 0
        // v = 1
        bytes memory powersSignature = abi.encodePacked(uint256(uint160(powers)), uint256(0), uint8(1));

        // Create the calldata for the `execTransaction` call that `Powers.fulfill` will execute.
        (targets, values, calldatas) = LawUtilities.createEmptyArrays(1);
        targets[0] = safeAddress;
        calldatas[0] = abi.encodeWithSelector(
            Safe.execTransaction.selector,
            to, // The internal transaction's destination
            0, // The internal transaction's value in this law is always 0. To tansfer Eth use a different law.
            data, // The internal transaction's data
            Enum.Operation.Call, // The internal transaction's operation type
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            payable(0), // refundReceiver
            powersSignature // The `v=1` signature
        );

        return (actionId, targets, values, calldatas);
    }
}
