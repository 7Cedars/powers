import { ConnectedWallet } from '@privy-io/react-auth';
import { Config, GetBlockReturnType } from '@wagmi/core';
import { Log } from "viem";

export type SupportedChains = 421614 | 11155111 | 31337 | undefined
export type Status = "idle" | "pending" | "error" | "success"
export type Vote = 0n | 1n | 2n  // = against, for, abstain  
// 'string | number | bigint | boolean | ByteArray 
export type OrganizationType = 'Powers 101' | 'Bridging Off-Chain Governance' | 'Grants Manager' | 'Split Governance' | 'Packaged Upgrades' | 'Single Upgrades'
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

export type LawExecutions = {
  powers: `0x${string}`, 
  config: `0x${string}`, 
  actionsIds: bigint[], 
  executions: bigint[] 
}

// If possible, remove this type. 
export type PowersExecutions = {
  lawId: bigint, 
  actionId: bigint, 
  blockNumber: bigint, 
  blockHash: `0x${string}`, 
  targets: `0x${string}`[], 
  values: bigint[], 
  calldatas: `0x${string}`[] 
}

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
  needNotCompleted: bigint;
  needCompleted: bigint;
  readStateFrom: bigint;
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
  config?: `0x${string}`;
  inputParams?: `0x${string}`; 
  params ?: {varName: string, dataType: DataType}[]; 
  executions?: LawExecutions; 
  active: boolean;
}

export type Metadata = { 
  icon: string; 
  banner: string;
  description: string; 
  erc20s: `0x${string}`[];
  erc721s: `0x${string}`[];
  erc1155s: `0x${string}`[];
  attributes: Attribute[]
}

export type RoleLabel = { 
  roleId: bigint; 
  label: string; 
  holders?: bigint;
}

export type BlockRange = {
  from: bigint;
  to: bigint;
}

export type Powers = {
  contractAddress: `0x${string}`;
  name?: string;
  uri?: string;
  metadatas?: Metadata; 
  lawCount?: bigint;
  laws?: Law[];
  activeLaws?: Law[];
  proposals?: Action[];
  proposalsBlocksFetched?: BlockRange;
  executedActions?: LawExecutions[]; // executions per law. 
  roles?: bigint[];
  roleLabels?: RoleLabel[];
  roleHolders?: bigint[];
  deselectedRoles?: bigint[];
  layout?: Record<string, { x: number; y: number }>; // Graph layout positions
}

export type Role = {
  access: boolean,
  account: `0x${string}`,
  roleId: number,
  since?: number
}

export type Roles = {
  roleId: bigint;
  holders?: number;
  laws?: Law[];
  proposals?: Action[];
  roles?: Role[];
};

export type Checks = {
  allPassed?: boolean; 
  authorised?: boolean;
  proposalExists?: boolean;
  voteActive?: boolean;
  proposalPassed?: boolean;
  executed?: boolean;
  actionNotCompleted?: boolean;
  lawCompleted?: boolean;
  lawNotCompleted?: boolean;
  delayPassed?: boolean;
  throttlePassed?: boolean;
}

export type Action = {
  actionId: string;
  lawId: bigint;
  caller?: `0x${string}`;
  dataTypes: DataType[] | undefined;
  paramValues: (InputType | InputType[])[] | undefined;
  nonce: string;
  description: string;
  callData: `0x${string}`;
  upToDate: boolean;
  state?: number;
  voteStart?: bigint;
  voteDuration?: bigint;
  voteEnd?: bigint;
  againstVotes?: bigint;
  forVotes?: bigint;
  abstainVotes?: bigint;
  executedAt?: bigint;
  cancelled?: boolean;
  requested?: boolean;
  fulfilled?: boolean;
}

export type ActionTruncated = Omit<Action, "actionId" | "dataTypes" | "paramValues" | "callData" | "upToDate" | "description">

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

export type CompletedProposal = {
  caller: `0x${string}`;
  address: `0x${string}`;
  lawCalldata: `0x${string}`;
  descriptionHash: `0x${string}`;
  blockNumber: bigint;
} 