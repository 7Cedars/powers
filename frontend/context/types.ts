import { ConnectedWallet } from '@privy-io/react-auth';
import { GetBlockReturnType } from '@wagmi/core';
import { Log } from "viem";

export type Status = "idle" | "pending" | "error" | "success"
export type Vote = 0n | 1n | 2n  // = against, for, abstain  
// 'string | number | bigint | boolean | ByteArray 
export type InputType = number | boolean | string | `0x${string}` | undefined 
export type DataType = "uint8" | "uint16" | "uint32" | "uint48" | "uint64" | "uint128" | "uint256" | "address" | "bytes" | "string" | "bytes32" | "bool" |
                       "uint8[]" | "uint16[]" | "uint32[]" | "uint48[]" | "uint64[]" | "uint128[]" | "uint256[]" | "address[]" | "bytes[]" | "string[]" | "bytes32[]" | "bool[]" | "unsupported" | "empty" 
export type LawSimulation = [
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
  rpc?: string;
  nativeCurrency?: {
    name: string;
    symbol: string;
    decimals: bigint;
  };
  blockExplorerUrl?: string;
  iconUrl?: string;
  organisations?: `0x${string}`[]; 
  erc20s: `0x${string}`[];
  erc721s: `0x${string}`[];
  erc1155s: `0x${string}`[];
}
                      

export type Config = {
  delayExecution: bigint; 
  needNotCompleted: `0x${string}`;
  needCompleted: `0x${string}`;
  readStateFrom: `0x${string}`;
  quorum: bigint; 
  succeedAt: bigint; 
  throttleExecution: bigint;
  votingPeriod: bigint;
}

type Args = {
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
  law: `0x${string}`;
  name?: string;
  description?: string;
  allowedRole?: bigint;
  powers?: `0x${string}`;
  config: Config;
  params?: string[];
  executions?: Execution[]; 
}

export type Metadata = { 
  icon: string; 
  banner: string;
  description: string; 
  attributes: Attribute[]
}

export type RoleLabel = { 
  roleId: bigint; 
  label: string; 
}

export type Organisation = {
  contractAddress: `0x${string}`;
  name?: string;
  metadatas?: Metadata; 
  colourScheme: number;
  laws?: Law[];
  activeLaws?: Law[];
  proposals?: Proposal[];
  roles: bigint[];
  roleLabels: RoleLabel[];
  deselectedRoles?: bigint[];
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
  proposals?: Proposal[];
  roles?: Role[];
};

export type Checks = {
  allPassed?: boolean; 
  authorised?: boolean;
  proposalExists?: boolean;
  proposalPassed?: boolean;
  proposalNotCompleted?: boolean;
  lawCompleted?: boolean;
  lawNotCompleted?: boolean;
  delayPassed?: boolean;
  throttlePassed?: boolean;
}

export type Action = {
  dataTypes: DataType[] | undefined;
  paramValues: (InputType | InputType[])[] | undefined;
  description: string;
  callData: `0x${string}`;
  upToDate: boolean;
}

export type Proposal = {
  actionId: number;
  targetLaw: `0x${string}`;
  voteStart: bigint;
  voteStartBlockData?: GetBlockReturnType; 
  voteDuration: bigint;
  voteEnd: bigint;
  cancelled: boolean;
  completed: boolean;
  caller: `0x${string}`;
  againstVotes?: bigint;
  forVotes?: bigint;
  abstainVotes?: bigint;
  description?: string;
  executeCalldata?: `0x${string}`;
  state?: number;
  blockNumber: bigint;
  blockHash?: `0x${string}`;
}

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