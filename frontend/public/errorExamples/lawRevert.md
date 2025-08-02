{error: {…}}
error
: 
error
: 
ContractFunctionExecutionError: The contract function "request" reverted with the following reason: Nominee already nominated. Contract Call: address: 0x8fa86ae26fad52bcd2bdac1e9dbbe1ad77b50e36 function: request(uint16 lawId, bytes lawCalldata, uint256 nonce, string uriAction) args: (5, 0x0000000000000000000000000000000000000000000000000000000000000001, 554453, 453453) sender: 0x328735d26e5Ada93610F0006c32abE2278c46211 Docs: https://viem.sh/docs/contract/simulateContract Version: viem@2.21.55 at getContractError (webpack-internal:///(app-pages-browser)/./node_modules/viem/_esm/utils/errors/getContractError.js:34:12) at simulateContract (webpack-internal:///(app-pages-browser)/./node_modules/viem/_esm/actions/public/simulateContract.js:83:98) at async simulateContract (webpack-internal:///(app-pages-browser)/./node_modules/@wagmi/core/dist/esm/actions/simulateContract.js:26:33) at async eval (webpack-internal:///(app-pages-browser)/./hooks/useLaw.ts:98:33)
abi
: 
Array(75)
0
: 
{type: 'constructor', inputs: Array(2), stateMutability: 'nonpayable'}
1
: 
{type: 'receive', stateMutability: 'payable'}
2
: 
{type: 'function', name: 'ADMIN_ROLE', inputs: Array(0), outputs: Array(1), stateMutability: 'view'}
3
: 
{type: 'function', name: 'PUBLIC_ROLE', inputs: Array(0), outputs: Array(1), stateMutability: 'view'}
4
: 
{type: 'function', name: 'adoptLaw', inputs: Array(1), outputs: Array(0), stateMutability: 'nonpayable'}
5
: 
{type: 'function', name: 'assignRole', inputs: Array(2), outputs: Array(0), stateMutability: 'nonpayable'}
6
: 
{type: 'function', name: 'canCallLaw', inputs: Array(2), outputs: Array(1), stateMutability: 'view'}
7
: 
{type: 'function', name: 'cancel', inputs: Array(3), outputs: Array(1), stateMutability: 'nonpayable'}
8
: 
{type: 'function', name: 'castVote', inputs: Array(2), outputs: Array(0), stateMutability: 'nonpayable'}
9
: 
{type: 'function', name: 'castVoteWithReason', inputs: Array(3), outputs: Array(0), stateMutability: 'nonpayable'}
10
: 
{type: 'function', name: 'constitute', inputs: Array(1), outputs: Array(0), stateMutability: 'nonpayable'}
11
: 
{type: 'function', name: 'eip712Domain', inputs: Array(0), outputs: Array(7), stateMutability: 'view'}
12
: 
{type: 'function', name: 'fulfill', inputs: Array(5), outputs: Array(0), stateMutability: 'payable'}
13
: 
{type: 'function', name: 'getActionCalldata', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
14
: 
{type: 'function', name: 'getActionData', inputs: Array(1), outputs: Array(12), stateMutability: 'view'}
15
: 
{type: 'function', name: 'getActionNonce', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
16
: 
{type: 'function', name: 'getActionUri', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
17
: 
{type: 'function', name: 'getActiveLaw', inputs: Array(1), outputs: Array(3), stateMutability: 'view'}
18
: 
{type: 'function', name: 'getAmountRoleHolders', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
19
: 
{type: 'function', name: 'getDeposits', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
20
: 
{type: 'function', name: 'getProposedActionDeadline', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
21
: 
{type: 'function', name: 'getRoleLabel', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
22
: 
{type: 'function', name: 'hasRoleSince', inputs: Array(2), outputs: Array(1), stateMutability: 'view'}
23
: 
{type: 'function', name: 'hasVoted', inputs: Array(2), outputs: Array(1), stateMutability: 'view'}
24
: 
{type: 'function', name: 'labelRole', inputs: Array(2), outputs: Array(0), stateMutability: 'nonpayable'}
25
: 
{type: 'function', name: 'lawCount', inputs: Array(0), outputs: Array(1), stateMutability: 'view'}
26
: 
{type: 'function', name: 'name', inputs: Array(0), outputs: Array(1), stateMutability: 'view'}
27
: 
{type: 'function', name: 'onERC1155BatchReceived', inputs: Array(5), outputs: Array(1), stateMutability: 'nonpayable'}
28
: 
{type: 'function', name: 'onERC1155Received', inputs: Array(5), outputs: Array(1), stateMutability: 'nonpayable'}
29
: 
{type: 'function', name: 'onERC721Received', inputs: Array(4), outputs: Array(1), stateMutability: 'nonpayable'}
30
: 
{type: 'function', name: 'propose', inputs: Array(4), outputs: Array(1), stateMutability: 'nonpayable'}
31
: 
{type: 'function', name: 'request', inputs: Array(4), outputs: Array(0), stateMutability: 'payable'}
32
: 
{type: 'function', name: 'revokeLaw', inputs: Array(1), outputs: Array(0), stateMutability: 'nonpayable'}
33
: 
{type: 'function', name: 'revokeRole', inputs: Array(2), outputs: Array(0), stateMutability: 'nonpayable'}
34
: 
{type: 'function', name: 'setUri', inputs: Array(1), outputs: Array(0), stateMutability: 'nonpayable'}
35
: 
{type: 'function', name: 'state', inputs: Array(1), outputs: Array(1), stateMutability: 'view'}
36
: 
{type: 'function', name: 'uri', inputs: Array(0), outputs: Array(1), stateMutability: 'view'}
37
: 
{type: 'function', name: 'version', inputs: Array(0), outputs: Array(1), stateMutability: 'pure'}
38
: 
{type: 'event', name: 'ActionExecuted', inputs: Array(5), anonymous: false}
39
: 
{type: 'event', name: 'ActionRequested', inputs: Array(5), anonymous: false}
40
: 
{type: 'event', name: 'EIP712DomainChanged', inputs: Array(0), anonymous: false}
41
: 
{type: 'event', name: 'FundsReceived', inputs: Array(1), anonymous: false}
42
: 
{type: 'event', name: 'LawAdopted', inputs: Array(1), anonymous: false}
43
: 
{type: 'event', name: 'LawRevived', inputs: Array(1), anonymous: false}
44
: 
{type: 'event', name: 'LawRevoked', inputs: Array(1), anonymous: false}
45
: 
{type: 'event', name: 'Powers__Initialized', inputs: Array(3), anonymous: false}
46
: 
{type: 'event', name: 'ProposedActionCancelled', inputs: Array(1), anonymous: false}
47
: 
{type: 'event', name: 'ProposedActionCreated', inputs: Array(9), anonymous: false}
48
: 
{type: 'event', name: 'RoleLabel', inputs: Array(2), anonymous: false}
49
: 
{type: 'event', name: 'RoleSet', inputs: Array(3), anonymous: false}
50
: 
{type: 'event', name: 'VoteCast', inputs: Array(4), anonymous: false}
51
: 
{type: 'error', name: 'FailedCall', inputs: Array(0)}
52
: 
{type: 'error', name: 'InvalidShortString', inputs: Array(0)}
53
: 
{type: 'error', name: 'Powers__AccessDenied', inputs: Array(0)}
54
: 
{type: 'error', name: 'Powers__ActionAlreadyInitiated', inputs: Array(0)}
55
: 
{type: 'error', name: 'Powers__ActionCancelled', inputs: Array(0)}
56
: 
{type: 'error', name: 'Powers__ActionNotRequested', inputs: Array(0)}
57
: 
{type: 'error', name: 'Powers__AlreadyCastVote', inputs: Array(0)}
58
: 
{type: 'error', name: 'Powers__CannotAddToPublicRole', inputs: Array(0)}
59
: 
{type: 'error', name: 'Powers__CannotAddZeroAddress', inputs: Array(0)}
60
: 
{type: 'error', name: 'Powers__ConstitutionAlreadyExecuted', inputs: Array(0)}
61
: 
{type: 'error', name: 'Powers__IncorrectInterface', inputs: Array(0)}
62
: 
{type: 'error', name: 'Powers__InvalidCallData', inputs: Array(0)}
63
: 
{type: 'error', name: 'Powers__InvalidName', inputs: Array(0)}
64
: 
{type: 'error', name: 'Powers__InvalidVoteType', inputs: Array(0)}
65
: 
{type: 'error', name: 'Powers__LawAlreadyActive', inputs: Array(0)}
66
: 
{type: 'error', name: 'Powers__LawDidNotPassChecks', inputs: Array(0)}
67
: 
{type: 'error', name: 'Powers__LawDoesNotExist', inputs: Array(0)}
68
: 
{type: 'error', name: 'Powers__LawNotActive', inputs: Array(0)}
69
: 
{type: 'error', name: 'Powers__LockedRole', inputs: Array(0)}
70
: 
{type: 'error', name: 'Powers__NoVoteNeeded', inputs: Array(0)}
71
: 
{type: 'error', name: 'Powers__OnlyPowers', inputs: Array(0)}
72
: 
{type: 'error', name: 'Powers__ProposedActionNotActive', inputs: Array(0)}
73
: 
{type: 'error', name: 'Powers__UnexpectedActionState', inputs: Array(0)}
74
: 
{type: 'error', name: 'StringTooLong', inputs: Array(1)}
length
: 
75
[[Prototype]]
: 
Array(0)
args
: 
(4) ['5', '0x0000000000000000000000000000000000000000000000000000000000000001', 554453n, '453453']
cause
: 
ContractFunctionRevertedError: The contract function "request" reverted with the following reason: Nominee already nominated. Version: viem@2.21.55 at eval (webpack-internal:///(app-pages-browser)/./node_modules/viem/_esm/utils/errors/getContractError.js:25:20) at getContractError (webpack-internal:///(app-pages-browser)/./node_modules/viem/_esm/utils/errors/getContractError.js:33:7) at simulateContract (webpack-internal:///(app-pages-browser)/./node_modules/viem/_esm/actions/public/simulateContract.js:83:98) at async simulateContract (webpack-internal:///(app-pages-browser)/./node_modules/@wagmi/core/dist/esm/actions/simulateContract.js:26:33) at async eval (webpack-internal:///(app-pages-browser)/./hooks/useLaw.ts:98:33)
contractAddress
: 
"0x8fa86ae26fad52bcd2bdac1e9dbbe1ad77b50e36"
details
: 
undefined
docsPath
: 
"/docs/contract/simulateContract"
formattedArgs
: 
undefined
functionName
: 
"request"
metaMessages
: 
Array(2)
0
: 
"Contract Call:"
1
: 
"  address:   0x8fa86ae26fad52bcd2bdac1e9dbbe1ad77b50e36\n  function:  request(uint16 lawId, bytes lawCalldata, uint256 nonce, string uriAction)\n  args:             (5, 0x0000000000000000000000000000000000000000000000000000000000000001, 554453, 453453)\n  sender:    0x328735d26e5Ada93610F0006c32abE2278c46211"
length
: 
2
[[Prototype]]
: 
Array(0)
name
: 
"ContractFunctionExecutionError"
sender
: 
"0x328735d26e5Ada93610F0006c32abE2278c46211"
shortMessage
: 
"The contract function \"request\" reverted with the following reason:\nNominee already nominated."
version
: 
"2.21.55"
message
: 
"The contract function \"request\" reverted with the following reason:\nNominee already nominated.\n\nContract Call:\n  address:   0x8fa86ae26fad52bcd2bdac1e9dbbe1ad77b50e36\n  function:  request(uint16 lawId, bytes lawCalldata, uint256 nonce, string uriAction)\n  args:             (5, 0x0000000000000000000000000000000000000000000000000000000000000001, 554453, 453453)\n  sender:    0x328735d26e5Ada93610F0006c32abE2278c46211\n\nDocs: https://viem.sh/docs/contract/simulateContract\nVersion: viem@2.21.55"
stack
: 
"ContractFunctionExecutionError: The contract function \"request\" reverted with the following reason:\nNominee already nominated.\n\nContract Call:\n  address:   0x8fa86ae26fad52bcd2bdac1e9dbbe1ad77b50e36\n  function:  request(uint16 lawId, bytes lawCalldata, uint256 nonce, string uriAction)\n  args:             (5, 0x0000000000000000000000000000000000000000000000000000000000000001, 554453, 453453)\n  sender:    0x328735d26e5Ada93610F0006c32abE2278c46211\n\nDocs: https://viem.sh/docs/contract/simulateContract\nVersion: viem@2.21.55\n    at getContractError (webpack-internal:///(app-pages-browser)/./node_modules/viem/_esm/utils/errors/getContractError.js:34:12)\n    at simulateContract (webpack-internal:///(app-pages-browser)/./node_modules/viem/_esm/actions/public/simulateContract.js:83:98)\n    at async simulateContract (webpack-internal:///(app-pages-browser)/./node_modules/@wagmi/core/dist/esm/actions/simulateContract.js:26:33)\n    at async eval (webpack-internal:///(app-pages-browser)/./hooks/useLaw.ts:98:33)"
[[Prototype]]
: 
BaseError
[[Prototype]]
: 
Object
[[Prototype]]
: 
Object