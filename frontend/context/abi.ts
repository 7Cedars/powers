import { Abi } from "viem"

import powers from "../../solidity/out/Powers.sol/Powers.json"
import law from "../../solidity/out/Law.sol/Law.json"

export const powersAbi: Abi = JSON.parse(JSON.stringify(powers.abi)) 
export const lawAbi: Abi = JSON.parse(JSON.stringify(law.abi)) 

// Note: these abis only have the functions that are used in the UI
export const erc20Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "owner", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "name",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "symbol",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "totalSupply",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "decimals",
    "inputs": [],
    "outputs": [{ "name": "", "type": "uint8", "internalType": "uint8" }],
    "stateMutability": "view"
  },
]

export const erc721Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "owner", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "name",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "ownerOf",
    "inputs": [
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "symbol",
    "inputs": [],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "tokenURI",
    "inputs": [
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
]

export const erc1155Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "account", "type": "address", "internalType": "address" },
      { "name": "id", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "balanceOfBatch",
    "inputs": [
      {
        "name": "accounts",
        "type": "address[]",
        "internalType": "address[]"
      },
      { "name": "ids", "type": "uint256[]", "internalType": "uint256[]" }
    ],
    "outputs": [
      { "name": "", "type": "uint256[]", "internalType": "uint256[]" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "uri",
    "inputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
    "stateMutability": "view"
  },
]

export const ownableAbi: Abi = [
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      { "name": "newOwner", "type": "address", "internalType": "address" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
]

//////////////////////////////////////////////////////////
//                    Powers ABI                        //
////////////////////////////////////////////////////////// 
// export const powersAbi: Abi = [
//     {
//       "type": "constructor",
//       "inputs": [
//         { "name": "name_", "type": "string", "internalType": "string" },
//         { "name": "uri_", "type": "string", "internalType": "string" }
//       ],
//       "stateMutability": "nonpayable"
//     },
//     { "type": "receive", "stateMutability": "payable" },
//     {
//       "type": "function",
//       "name": "ADMIN_ROLE",
//       "inputs": [],
//       "outputs": [{ "name": "", "type": "uint32", "internalType": "uint32" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "PUBLIC_ROLE",
//       "inputs": [],
//       "outputs": [{ "name": "", "type": "uint32", "internalType": "uint32" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "adoptLaw",
//       "inputs": [
//         { "name": "law", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "assignRole",
//       "inputs": [
//         { "name": "roleId", "type": "uint32", "internalType": "uint32" },
//         { "name": "account", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "canCallLaw",
//       "inputs": [
//         { "name": "caller", "type": "address", "internalType": "address" },
//         { "name": "targetLaw", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "cancel",
//       "inputs": [
//         { "name": "targetLaw", "type": "address", "internalType": "address" },
//         { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//         {
//           "name": "descriptionHash",
//           "type": "bytes32",
//           "internalType": "bytes32"
//         }
//       ],
//       "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "castVote",
//       "inputs": [
//         { "name": "actionId", "type": "uint256", "internalType": "uint256" },
//         { "name": "support", "type": "uint8", "internalType": "uint8" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "castVoteWithReason",
//       "inputs": [
//         { "name": "actionId", "type": "uint256", "internalType": "uint256" },
//         { "name": "support", "type": "uint8", "internalType": "uint8" },
//         { "name": "reason", "type": "string", "internalType": "string" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "constitute",
//       "inputs": [
//         {
//           "name": "constituentLaws",
//           "type": "address[]",
//           "internalType": "address[]"
//         }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "eip712Domain",
//       "inputs": [],
//       "outputs": [
//         { "name": "fields", "type": "bytes1", "internalType": "bytes1" },
//         { "name": "name", "type": "string", "internalType": "string" },
//         { "name": "version", "type": "string", "internalType": "string" },
//         { "name": "chainId", "type": "uint256", "internalType": "uint256" },
//         {
//           "name": "verifyingContract",
//           "type": "address",
//           "internalType": "address"
//         },
//         { "name": "salt", "type": "bytes32", "internalType": "bytes32" },
//         {
//           "name": "extensions",
//           "type": "uint256[]",
//           "internalType": "uint256[]"
//         }
//       ],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "execute",
//       "inputs": [
//         { "name": "targetLaw", "type": "address", "internalType": "address" },
//         { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//         { "name": "description", "type": "string", "internalType": "string" }
//       ],
//       "outputs": [],
//       "stateMutability": "payable"
//     },
//     {
//       "type": "function",
//       "name": "getActiveLaw",
//       "inputs": [
//         { "name": "law", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [{ "name": "active", "type": "bool", "internalType": "bool" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "getAmountRoleHolders",
//       "inputs": [
//         { "name": "roleId", "type": "uint32", "internalType": "uint32" }
//       ],
//       "outputs": [
//         {
//           "name": "amountMembers",
//           "type": "uint256",
//           "internalType": "uint256"
//         }
//       ],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "getProposalVotes",
//       "inputs": [
//         { "name": "actionId", "type": "uint256", "internalType": "uint256" }
//       ],
//       "outputs": [
//         {
//           "name": "againstVotes",
//           "type": "uint256",
//           "internalType": "uint256"
//         },
//         { "name": "forVotes", "type": "uint256", "internalType": "uint256" },
//         { "name": "abstainVotes", "type": "uint256", "internalType": "uint256" }
//       ],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "hasRoleSince",
//       "inputs": [
//         { "name": "account", "type": "address", "internalType": "address" },
//         { "name": "roleId", "type": "uint32", "internalType": "uint32" }
//       ],
//       "outputs": [
//         { "name": "since", "type": "uint48", "internalType": "uint48" }
//       ],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "hasVoted",
//       "inputs": [
//         { "name": "actionId", "type": "uint256", "internalType": "uint256" },
//         { "name": "account", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "hashProposal",
//       "inputs": [
//         { "name": "targetLaw", "type": "address", "internalType": "address" },
//         { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//         {
//           "name": "descriptionHash",
//           "type": "bytes32",
//           "internalType": "bytes32"
//         }
//       ],
//       "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
//       "stateMutability": "pure"
//     },
//     {
//       "type": "function",
//       "name": "labelRole",
//       "inputs": [
//         { "name": "roleId", "type": "uint32", "internalType": "uint32" },
//         { "name": "label", "type": "string", "internalType": "string" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "laws",
//       "inputs": [
//         { "name": "lawAddress", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [{ "name": "active", "type": "bool", "internalType": "bool" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "name",
//       "inputs": [],
//       "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "onERC1155BatchReceived",
//       "inputs": [
//         { "name": "", "type": "address", "internalType": "address" },
//         { "name": "", "type": "address", "internalType": "address" },
//         { "name": "", "type": "uint256[]", "internalType": "uint256[]" },
//         { "name": "", "type": "uint256[]", "internalType": "uint256[]" },
//         { "name": "", "type": "bytes", "internalType": "bytes" }
//       ],
//       "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "onERC1155Received",
//       "inputs": [
//         { "name": "", "type": "address", "internalType": "address" },
//         { "name": "", "type": "address", "internalType": "address" },
//         { "name": "", "type": "uint256", "internalType": "uint256" },
//         { "name": "", "type": "uint256", "internalType": "uint256" },
//         { "name": "", "type": "bytes", "internalType": "bytes" }
//       ],
//       "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "onERC721Received",
//       "inputs": [
//         { "name": "", "type": "address", "internalType": "address" },
//         { "name": "", "type": "address", "internalType": "address" },
//         { "name": "", "type": "uint256", "internalType": "uint256" },
//         { "name": "", "type": "bytes", "internalType": "bytes" }
//       ],
//       "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "proposalDeadline",
//       "inputs": [
//         { "name": "actionId", "type": "uint256", "internalType": "uint256" }
//       ],
//       "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "propose",
//       "inputs": [
//         { "name": "targetLaw", "type": "address", "internalType": "address" },
//         { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//         { "name": "description", "type": "string", "internalType": "string" }
//       ],
//       "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "revokeLaw",
//       "inputs": [
//         { "name": "law", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "revokeRole",
//       "inputs": [
//         { "name": "roleId", "type": "uint32", "internalType": "uint32" },
//         { "name": "account", "type": "address", "internalType": "address" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "roles",
//       "inputs": [
//         { "name": "roleId", "type": "uint32", "internalType": "uint32" }
//       ],
//       "outputs": [
//         {
//           "name": "amountMembers",
//           "type": "uint256",
//           "internalType": "uint256"
//         }
//       ],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "setUri",
//       "inputs": [
//         { "name": "newUri", "type": "string", "internalType": "string" }
//       ],
//       "outputs": [],
//       "stateMutability": "nonpayable"
//     },
//     {
//       "type": "function",
//       "name": "state",
//       "inputs": [
//         { "name": "actionId", "type": "uint256", "internalType": "uint256" }
//       ],
//       "outputs": [
//         {
//           "name": "",
//           "type": "uint8",
//           "internalType": "enum PowersTypes.ActionState"
//         }
//       ],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "uri",
//       "inputs": [],
//       "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
//       "stateMutability": "view"
//     },
//     {
//       "type": "function",
//       "name": "version",
//       "inputs": [],
//       "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
//       "stateMutability": "pure"
//     },
//     {
//       "type": "event",
//       "name": "EIP712DomainChanged",
//       "inputs": [],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "FundsReceived",
//       "inputs": [
//         {
//           "name": "value",
//           "type": "uint256",
//           "indexed": false,
//           "internalType": "uint256"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "LawAdopted",
//       "inputs": [
//         {
//           "name": "law",
//           "type": "address",
//           "indexed": true,
//           "internalType": "address"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "LawRevoked",
//       "inputs": [
//         {
//           "name": "law",
//           "type": "address",
//           "indexed": true,
//           "internalType": "address"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "Powers__Initialized",
//       "inputs": [
//         {
//           "name": "contractAddress",
//           "type": "address",
//           "indexed": false,
//           "internalType": "address"
//         },
//         {
//           "name": "name",
//           "type": "string",
//           "indexed": false,
//           "internalType": "string"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "ProposalCancelled",
//       "inputs": [
//         {
//           "name": "actionId",
//           "type": "uint256",
//           "indexed": true,
//           "internalType": "uint256"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "ActionRequested",
//       "inputs": [
//         {
//           "name": "caller",
//           "type": "address",
//           "indexed": true,
//           "internalType": "address"
//         },
//         {
//           "name": "targetLaw",
//           "type": "address",
//           "indexed": true,
//           "internalType": "address"
//         },
//         {
//           "name": "lawCalldata",
//           "type": "bytes",
//           "indexed": false,
//           "internalType": "bytes"
//         },
//         {
//           "name": "description",
//           "type": "string",
//           "indexed": false,
//           "internalType": "string"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "ProposalCreated",
//       "inputs": [
//         {
//           "name": "actionId",
//           "type": "uint256",
//           "indexed": true,
//           "internalType": "uint256"
//         },
//         {
//           "name": "caller",
//           "type": "address",
//           "indexed": true,
//           "internalType": "address"
//         },
//         {
//           "name": "targetLaw",
//           "type": "address",
//           "indexed": false,
//           "internalType": "address"
//         },
//         {
//           "name": "signature",
//           "type": "string",
//           "indexed": false,
//           "internalType": "string"
//         },
//         {
//           "name": "executeCalldata",
//           "type": "bytes",
//           "indexed": false,
//           "internalType": "bytes"
//         },
//         {
//           "name": "voteStart",
//           "type": "uint256",
//           "indexed": false,
//           "internalType": "uint256"
//         },
//         {
//           "name": "voteEnd",
//           "type": "uint256",
//           "indexed": false,
//           "internalType": "uint256"
//         },
//         {
//           "name": "description",
//           "type": "string",
//           "indexed": false,
//           "internalType": "string"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "ActionExecuted",
//       "inputs": [
//         {
//           "name": "targets",
//           "type": "address[]",
//           "indexed": false,
//           "internalType": "address[]"
//         },
//         {
//           "name": "values",
//           "type": "uint256[]",
//           "indexed": false,
//           "internalType": "uint256[]"
//         },
//         {
//           "name": "calldatas",
//           "type": "bytes[]",
//           "indexed": false,
//           "internalType": "bytes[]"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "RoleLabel",
//       "inputs": [
//         {
//           "name": "roleId",
//           "type": "uint32",
//           "indexed": true,
//           "internalType": "uint32"
//         },
//         {
//           "name": "label",
//           "type": "string",
//           "indexed": false,
//           "internalType": "string"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "RoleSet",
//       "inputs": [
//         {
//           "name": "roleId",
//           "type": "uint32",
//           "indexed": true,
//           "internalType": "uint32"
//         },
//         {
//           "name": "account",
//           "type": "address",
//           "indexed": true,
//           "internalType": "address"
//         },
//         {
//           "name": "access",
//           "type": "bool",
//           "indexed": true,
//           "internalType": "bool"
//         }
//       ],
//       "anonymous": false
//     },
//     {
//       "type": "event",
//       "name": "VoteCast",
//       "inputs": [
//         {
//           "name": "account",
//           "type": "address",
//           "indexed": true,
//           "internalType": "address"
//         },
//         {
//           "name": "actionId",
//           "type": "uint256",
//           "indexed": true,
//           "internalType": "uint256"
//         },
//         {
//           "name": "support",
//           "type": "uint8",
//           "indexed": true,
//           "internalType": "uint8"
//         },
//         {
//           "name": "reason",
//           "type": "string",
//           "indexed": false,
//           "internalType": "string"
//         }
//       ],
//       "anonymous": false
//     },
//     { "type": "error", "name": "FailedCall", "inputs": [] },
//     { "type": "error", "name": "InvalidShortString", "inputs": [] },
//     { "type": "error", "name": "Powers__AccessDenied", "inputs": [] },
//     { "type": "error", "name": "Powers__AlreadyCastVote", "inputs": [] },
//     {
//       "type": "error",
//       "name": "Powers__CancelCallNotFromActiveLaw",
//       "inputs": []
//     },
//     {
//       "type": "error",
//       "name": "Powers__ConstitutionAlreadyExecuted",
//       "inputs": []
//     },
//     { "type": "error", "name": "Powers__IncorrectInterface", "inputs": [] },
//     { "type": "error", "name": "Powers__InvalidCallData", "inputs": [] },
//     { "type": "error", "name": "Powers__InvalidactionId", "inputs": [] },
//     { "type": "error", "name": "Powers__InvalidVoteType", "inputs": [] },
//     { "type": "error", "name": "Powers__LawAlreadyActive", "inputs": [] },
//     { "type": "error", "name": "Powers__LawDidNotPassChecks", "inputs": [] },
//     {
//       "type": "error",
//       "name": "Powers__LawDoesNotNeedProposalVote",
//       "inputs": []
//     },
//     { "type": "error", "name": "Powers__LawNotActive", "inputs": [] },
//     { "type": "error", "name": "Powers__LockedRole", "inputs": [] },
//     { "type": "error", "name": "Powers__NoVoteNeeded", "inputs": [] },
//     { "type": "error", "name": "Powers__LawNotActive", "inputs": [] },
//     { "type": "error", "name": "Powers__OnlyPowers", "inputs": [] },
//     {
//       "type": "error",
//       "name": "Powers__ProposalAlreadyCompleted",
//       "inputs": []
//     },
//     { "type": "error", "name": "Powers__ProposalCancelled", "inputs": [] },
//     { "type": "error", "name": "Powers__ProposalNotActive", "inputs": [] },
//     {
//       "type": "error",
//       "name": "Powers__UnexpectedActionState",
//       "inputs": []
//     },
//     {
//       "type": "error",
//       "name": "StringTooLong",
//       "inputs": [{ "name": "str", "type": "string", "internalType": "string" }]
//     }
//   ]
// //////////////////////////////////////////////////////////
// //                      Law ABI                         //
// ////////////////////////////////////////////////////////// 
// export const lawAbi: Abi = [
//   {
//     "type": "constructor",
//     "inputs": [
//       { "name": "name_", "type": "string", "internalType": "string" },
//       { "name": "description_", "type": "string", "internalType": "string" },
//       {
//         "name": "powers_",
//         "type": "address",
//         "internalType": "address payable"
//       },
//       { "name": "allowedRole_", "type": "uint32", "internalType": "uint32" },
//       {
//         "name": "config_",
//         "type": "tuple",
//         "internalType": "struct ILaw.LawConfig",
//         "components": [
//           { "name": "quorum", "type": "uint8", "internalType": "uint8" },
//           { "name": "succeedAt", "type": "uint8", "internalType": "uint8" },
//           {
//             "name": "votingPeriod",
//             "type": "uint32",
//             "internalType": "uint32"
//           },
//           {
//             "name": "needCompleted",
//             "type": "address",
//             "internalType": "address"
//           },
//           {
//             "name": "needNotCompleted",
//             "type": "address",
//             "internalType": "address"
//           },
//           {
//             "name": "delayExecution",
//             "type": "uint48",
//             "internalType": "uint48"
//           },
//           {
//             "name": "throttleExecution",
//             "type": "uint48",
//             "internalType": "uint48"
//           },
//           {
//             "name": "readStateFrom",
//             "type": "address",
//             "internalType": "address"
//           }
//         ]
//       }
//     ],
//     "stateMutability": "nonpayable"
//   },
//   {
//     "type": "function",
//     "name": "allowedRole",
//     "inputs": [],
//     "outputs": [{ "name": "", "type": "uint32", "internalType": "uint32" }],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "checksAtExecute",
//     "inputs": [
//       { "name": "caller", "type": "address", "internalType": "address" },
//       { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//       {
//         "name": "descriptionHash",
//         "type": "bytes32",
//         "internalType": "bytes32"
//       }
//     ],
//     "outputs": [],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "checksAtPropose",
//     "inputs": [
//       { "name": "caller", "type": "address", "internalType": "address" },
//       { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//       {
//         "name": "descriptionHash",
//         "type": "bytes32",
//         "internalType": "bytes32"
//       }
//     ],
//     "outputs": [],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "config",
//     "inputs": [],
//     "outputs": [
//       { "name": "quorum", "type": "uint8", "internalType": "uint8" },
//       { "name": "succeedAt", "type": "uint8", "internalType": "uint8" },
//       { "name": "votingPeriod", "type": "uint32", "internalType": "uint32" },
//       {
//         "name": "needCompleted",
//         "type": "address",
//         "internalType": "address"
//       },
//       {
//         "name": "needNotCompleted",
//         "type": "address",
//         "internalType": "address"
//       },
//       {
//         "name": "delayExecution",
//         "type": "uint48",
//         "internalType": "uint48"
//       },
//       {
//         "name": "throttleExecution",
//         "type": "uint48",
//         "internalType": "uint48"
//       },
//       {
//         "name": "readStateFrom",
//         "type": "address",
//         "internalType": "address"
//       }
//     ],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "description",
//     "inputs": [],
//     "outputs": [{ "name": "", "type": "string", "internalType": "string" }],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "executeLaw",
//     "inputs": [
//       { "name": "caller", "type": "address", "internalType": "address" },
//       { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//       {
//         "name": "descriptionHash",
//         "type": "bytes32",
//         "internalType": "bytes32"
//       }
//     ],
//     "outputs": [
//       { "name": "targets", "type": "address[]", "internalType": "address[]" },
//       { "name": "values", "type": "uint256[]", "internalType": "uint256[]" },
//       { "name": "calldatas", "type": "bytes[]", "internalType": "bytes[]" }
//     ],
//     "stateMutability": "nonpayable"
//   },
//   {
//     "type": "function",
//     "name": "executions",
//     "inputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
//     "outputs": [{ "name": "", "type": "uint48", "internalType": "uint48" }],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "inputParams",
//     "inputs": [],
//     "outputs": [{ "name": "", "type": "bytes", "internalType": "bytes" }],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "name",
//     "inputs": [],
//     "outputs": [
//       { "name": "", "type": "bytes32", "internalType": "ShortString" }
//     ],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "powers",
//     "inputs": [],
//     "outputs": [
//       { "name": "", "type": "address", "internalType": "address payable" }
//     ],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "simulateLaw",
//     "inputs": [
//       { "name": "caller", "type": "address", "internalType": "address" },
//       { "name": "lawCalldata", "type": "bytes", "internalType": "bytes" },
//       {
//         "name": "descriptionHash",
//         "type": "bytes32",
//         "internalType": "bytes32"
//       }
//     ],
//     "outputs": [
//       { "name": "targets", "type": "address[]", "internalType": "address[]" },
//       { "name": "values", "type": "uint256[]", "internalType": "uint256[]" },
//       { "name": "calldatas", "type": "bytes[]", "internalType": "bytes[]" },
//       { "name": "stateChange", "type": "bytes", "internalType": "bytes" }
//     ],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "stateVars",
//     "inputs": [],
//     "outputs": [{ "name": "", "type": "bytes", "internalType": "bytes" }],
//     "stateMutability": "view"
//   },
//   {
//     "type": "function",
//     "name": "supportsInterface",
//     "inputs": [
//       { "name": "interfaceId", "type": "bytes4", "internalType": "bytes4" }
//     ],
//     "outputs": [{ "name": "", "type": "bool", "internalType": "bool" }],
//     "stateMutability": "view"
//   },
//   {
//     "type": "event",
//     "name": "Law__Initialized",
//     "inputs": [
//       {
//         "name": "law",
//         "type": "address",
//         "indexed": true,
//         "internalType": "address"
//       },
//       {
//         "name": "powers",
//         "type": "address",
//         "indexed": true,
//         "internalType": "address"
//       },
//       {
//         "name": "name",
//         "type": "string",
//         "indexed": false,
//         "internalType": "string"
//       },
//       {
//         "name": "description",
//         "type": "string",
//         "indexed": false,
//         "internalType": "string"
//       },
//       {
//         "name": "allowedRole",
//         "type": "uint48",
//         "indexed": false,
//         "internalType": "uint48"
//       },
//       {
//         "name": "config",
//         "type": "tuple",
//         "indexed": false,
//         "internalType": "struct ILaw.LawConfig",
//         "components": [
//           { "name": "quorum", "type": "uint8", "internalType": "uint8" },
//           { "name": "succeedAt", "type": "uint8", "internalType": "uint8" },
//           {
//             "name": "votingPeriod",
//             "type": "uint32",
//             "internalType": "uint32"
//           },
//           {
//             "name": "needCompleted",
//             "type": "address",
//             "internalType": "address"
//           },
//           {
//             "name": "needNotCompleted",
//             "type": "address",
//             "internalType": "address"
//           },
//           {
//             "name": "delayExecution",
//             "type": "uint48",
//             "internalType": "uint48"
//           },
//           {
//             "name": "throttleExecution",
//             "type": "uint48",
//             "internalType": "uint48"
//           },
//           {
//             "name": "readStateFrom",
//             "type": "address",
//             "internalType": "address"
//           }
//         ]
//       }
//     ],
//     "anonymous": false
//   },
//   { "type": "error", "name": "Law__DeadlineNotPassed", "inputs": [] },
//   { "type": "error", "name": "Law__ExecutionGapTooSmall", "inputs": [] },
//   { "type": "error", "name": "Law__ExecutionLimitReached", "inputs": [] },
//   { "type": "error", "name": "Law__NoDeadlineSet", "inputs": [] },
//   { "type": "error", "name": "Law__NoZeroAddress", "inputs": [] },
//   { "type": "error", "name": "Law__OnlyPowers", "inputs": [] },
//   { "type": "error", "name": "Law__ParentBlocksCompletion", "inputs": [] },
//   { "type": "error", "name": "Law__ParentLawNotSet", "inputs": [] },
//   { "type": "error", "name": "Law__ParentNotCompleted", "inputs": [] },
//   { "type": "error", "name": "Law__ProposalNotSucceeded", "inputs": [] },
//   {
//     "type": "error",
//     "name": "StringTooLong",
//     "inputs": [{ "name": "str", "type": "string", "internalType": "string" }]
//   }
// ]

