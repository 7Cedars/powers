import { GetBlockReturnType } from '@wagmi/core';
import { Log } from "viem";

export type SupportedChains = 421614 | 11155111 | 31337 | 5003 | undefined
export type Status = "idle" | "pending" | "error" | "success"
export type Vote = 0n | 1n | 2n  // = against, FOR, ABSTAIN  
// 'string | number | bigint | boolean | ByteArray 
export type OrganizationType = 'Powers 101' | 'Bridging Off-Chain Governance' | 'Grants Manager' | 'Split Governance' | 'Packaged Upgrades' | 'Single Upgrades' | 'PowersDAO'
export type InputType = boolean | string | number | bigint | `0x${string}`
export type DataType = "uint8" | "uint16" | "uint32" | "uint48" | "uint64" | "uint128" | "uint256" | "address" | "bytes" | "string" | "bytes32" | "bool" |
                       "uint8[]" | "uint16[]" | "uint32[]" | "uint48[]" | "uint64[]" | "uint128[]" | "uint256[]" | "address[]" | "bytes[]" | "string[]" | "bytes32[]" | "bool[]" | "unsupported" | "empty" 
export type LawSimulation = [
      bigint, 
      `0x${string}`[], 
      bigint[], 
      `0x${string}`[], 
      `0x${string}`
]

export type Attribute = {  
  trait_type: string | number ;  
  value: string;
}

export type Token = {
  name?: string; 
  symbol?: string; 
  type?: "erc20" | "erc721" | "erc1155" | "native";  
  balance: bigint; 
  decimals?: bigint; 
  address?: `0x${string}`; 
  tokenId?: number;
  valueNative?: number; 
}

export type ChainProps = {
  name: string;
  network: string; 
  id: number;
  genesisBlock: bigint; // block at which the first PowersProtocol was deployed. 
  blockTimeInSeconds?: number;
  alternativeBlockNumbers?: SupportedChains;
  rpc?: string;
  nativeCurrency?: {
    name: string;
    symbol: string;
    decimals: bigint;
  };
  blockExplorerUrl?: string;
  iconUrl?: string;
}
                      
export type Conditions = {
  allowedRole: bigint; 
  delayExecution: bigint; 
  needNotFulfilled: bigint;
  needFulfilled: bigint;
  quorum: bigint; 
  succeedAt: bigint; 
  throttleExecution: bigint;
  votingPeriod: bigint;
}

type Args = {
  nonce: bigint;
  description: string;
  caller: `0x${string}`;
  lawCalldata: `0x${string}`;
  targetLaw: `0x${string}`;
}

export type LogExtended = Log & 
  {args: Args}

export type Execution = {
  log: LogExtended; 
  blocksData?: GetBlockReturnType
}

export type Law = {
  powers: `0x${string}`;
  lawAddress: `0x${string}`;
  lawHash: `0x${string}`;
  index: bigint;
  nameDescription?: string;
  conditions?: Conditions;
  actions? : Action[];
  config?: `0x${string}`;
  inputParams?: `0x${string}`; 
  params ?: {varName: string, dataType: DataType}[]; 
  active: boolean;
}

export type CommunicationChannels = {
  discord?: string;
  telegram?: string;
  x?: string;
  paragraph?: string;
  youtube?: string;
  facebook?: string;
  github?: string;
  forum?: string;
  documentation?: string;
}

export type Metadata = { 
  icon: string; 
  banner: string;
  description: string; 
  website?: string;
  codeOfConduct?: string;
  disputeResolution?: string;
  communicationChannels?: CommunicationChannels;
  attributes?: Attribute[];
}

export type BlockRange = {
  from: bigint;
  to: bigint;
}

export type ActionVote = {
  actionId: string
  voteStart: bigint
  voteDuration: bigint
  voteEnd: bigint
  againstVotes: bigint
  forVotes: bigint
  abstainVotes: bigint
  state: number
}

export type Powers = {
  contractAddress: `0x${string}`;
  chainId: bigint;
  name?: string;
  uri?: string;
  treasury?: `0x${string}`;
  metadatas?: Metadata; 
  lawCount?: bigint;
  laws?: Law[];
  roles?: Role[];
  layout?: Record<string, { x: number; y: number }>; // Graph layout positions
}

export type Role = { 
  roleId: bigint; 
  label: string; 
  amountHolders?: bigint;
  members?: Member[];
}

export type Member = { 
  account: `0x${string}`; 
  since: bigint; 
}

export type Checks = {
  allPassed?: boolean; 
  authorised?: boolean;
  actionExists?: boolean;
  voteActive?: boolean;
  proposalPassed?: boolean;
  fulfilled?: boolean;
  actionNotFulfilled?: boolean;
  lawFulfilled?: boolean;
  lawNotFulfilled?: boolean;
  delayPassed?: boolean;
  throttlePassed?: boolean;
}

export type Action = {
  actionId: string;
  lawId: bigint;
  caller?: `0x${string}`;
  dataTypes?: DataType[] | undefined;
  paramValues?: (InputType | InputType[])[] | undefined;
  nonce?: string;
  description?: string;
  callData?: `0x${string}`;
  upToDate?: boolean;
  proposedAt?: bigint;
  requestedAt?: bigint;
  fulfilledAt?: bigint;
  cancelledAt?: bigint;
  state?: number;
  voteStart?: bigint;
  voteDuration?: bigint;
  voteEnd?: bigint;
  againstVotes?: bigint;
  forVotes?: bigint;
  abstainVotes?: bigint;
}

export type ActionTruncated = Omit<Action, "proposedAt" | "requestedAt" | "fulfilledAt" | "cancelledAt" | "state" | "voteStart" | "voteDuration" | "voteEnd" | "againstVotes" | "forVotes" | "abstainVotes">

export type ProtocolEvent = {
  address: `0x${string}`;
  blockHash: `0x${string}`;
  blockNumber: bigint;
  args: any; 
  data: `0x${string}`;
  eventName: string;
  logIndex: number;
  transactionHash: `0x${string}`;
  transactionIndex: number;
}

export type ContractAddress = {
  contract: string; 
  address: `0x${string}`; 
}
