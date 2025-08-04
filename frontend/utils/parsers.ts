import { ChangeEvent } from "react";
import { InputType, DataType, Metadata, Attribute, Token, Action, ActionTruncated } from "../context/types"
import { type UseReadContractsReturnType } from 'wagmi'
import { decodeAbiParameters, hexToString } from 'viem'

const isArray = (array: unknown): array is Array<unknown> => {
  // array.find(item => !isString(item)) 
  return array instanceof Array;
};

const isString = (text: unknown): text is string => {
  return typeof text === 'string' || text instanceof String;
};

const isNumber = (number: unknown): number is number => {
  return typeof number === 'number' || number instanceof Number;
};

const isBigInt = (number: unknown): number is BigInt => {
  return typeof number === 'bigint';
};

const isBoolean = (bool: unknown): bool is boolean => {
  // array.find(item => !isString(item)) 
  return typeof bool === 'boolean' || bool instanceof Boolean;
};

const isValidUrl = (urlString: string) => {
  try { 
    return Boolean(new URL(urlString)); 
  }
  catch(e){ 
    return false; 
  }
}

export const bytesToParams = (bytes: `0x${string}`): {varName: string, dataType: DataType}[]  => {
  if (!bytes) { // I can make it more specific later.
    return [] 
  }
  const string = hexToString(bytes) 
  const raw = string.split(`\u0000`).filter(item => item.length > 3)
  const cleanString = raw.map(item => item.slice(1)) as string[]
  const result = cleanString.map(item => {
  const items = item.split(" ")
    return ({
      varName: items[1] as string, 
      dataType: items[0] as DataType
    })
  })

  return result
}


export const parseParamValues = (inputs: unknown): Array<InputType | InputType[]> => {
  // very basic parser. Here necessary input checks can be added later.  
  if (!isArray(inputs)) {
    throw new Error('@parseParamValues: input not an array.');
  }

  const result = inputs.map(input => 
    isArray(input) ? input as InputType[] : input as InputType 
  )

  return result 
};

const parseTokens = (tokens: unknown): `0x${string}`[] => {
  if (!isArray(tokens)) {
    throw new Error('@parseTokens: tokens not an array.');
  }

  const result = tokens.map(token =>  {
    if (isArray(token)) { throw new Error('@parseTokens: nested token arrays not supported.'); }
    return token as `0x${string}` 
  })

  return result 
}

const parseDescription = (description: unknown): string => {
  if (!isString(description)) {
    throw new Error(`Incorrect description, not a string: ${description}`);
  }
  // here can additional checks later. For instance length, characters, etc. 
  return description as string;
};

const parseTraitType = (description: unknown): string => {
  if (!isString(description)) {
    throw new Error(`Incorrect trait type, not a string: ${description}`);
  }
  // here can additional checks later. 

  return description as string;
};


const parseTraitValue = (traitValue: unknown): string | number => {
  if (!isString(traitValue) && !isNumber(traitValue)) {
    throw new Error(`Incorrect trait value, not a string or number or boolean: ${traitValue}`);
  }
  // here can additional checks later. 
  if (isString(traitValue)) return traitValue as string;
  return traitValue as number;
};


export const parseAttributes = (attributes: unknown): Attribute[]  => {
  if (!isArray(attributes)) {
    throw new Error(`Incorrect attributes, not an array: ${attributes}`);
  }

  try { 
    const parsedAttributes = attributes.map((attribute: unknown) => {
      if ( !attribute || typeof attribute !== 'object' ) {
        throw new Error('Incorrect or missing data at attribute');
      }

      if (
        'trait_type' in attribute &&
        'value' in attribute
        ) { return ({
            trait_type: parseTraitType(attribute.trait_type),
            value: parseTraitValue(attribute.value)
          })
        }
        throw new Error('Incorrect data at Metadata: some fields are missing or incorrect');
    })

    return parsedAttributes as Attribute[] 

  } catch {
    throw new Error('Incorrect data at Metadata: Parser caught error');
  }
};



export const parseInput = (event: ChangeEvent<HTMLInputElement>, dataType: DataType): InputType => {
  // very basic parser. Here necessary input checks can be added later.  
  // console.log("@parseInput: ", {event, dataType})

  const errorMessage = 'Incorrect input data';
  if ( !event.target.value && typeof event.target.value !== 'string' && typeof event.target.value !== 'number' && typeof event.target.value !== 'boolean' ) {
     throw new Error('@parseInput: Incorrect or missing data.');
  }

  if (event.target.value == "") {
    return errorMessage
  }

  // Note that later on I can also check for maximum values by taking the power of uintxxx
  if (dataType.indexOf('uint') > -1) {
    // console.log("@parseInput UINT: waypoint 0", {event, dataType})
    try {
      // For large numbers, we need to handle them as strings to avoid precision loss
      // JavaScript Number can only safely represent integers up to 2^53 - 1
      const value = event.target.value.trim()
      
      // Check if it's a valid number (only digits)
      if (!/^\d+$/.test(value)) {
        return errorMessage
      }
      
      // For very large numbers, use BigInt to preserve precision
      // JavaScript Number can only safely represent integers up to 2^53 - 1
      if (value.length > 15) { // Numbers with more than 15 digits may lose precision
        try {
          return BigInt(value)
        } catch {
          return errorMessage
        }
      }
      
      // For smaller numbers, we can safely use Number
      const numValue = Number(value)
      if (isNaN(numValue) || !Number.isSafeInteger(numValue)) {
        return errorMessage
      }
      
      return numValue
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('string') > -1) { 
    // console.log("@parseInput STRING: waypoint 0", {event, dataType})
    try {
      return event.target.value as string 
    } catch {
      return errorMessage
    } 
  }

  if (dataType.indexOf('bool') > -1) { 
    try {
      // console.log("@parseInput BOOL: waypoint 1", {event, value: event.target.value})
      return event.target.value == "true" ? true : false
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('address') > -1) {
    try {
      // console.log("@parseInput ADDRESS: waypoint 0", {event, dataType})
      return event.target.value as `0x${string}` 
    } catch {
      return errorMessage
    }
  }

  if (dataType.indexOf('bytes') > -1)  {
    try {
      // console.log("@parseInput BYTES: waypoint 0", {event, dataType})
      return event.target.value as `0x${string}` 
    } catch {
      return errorMessage
    }
  }

  return errorMessage
};

export const parseTrueFalse = (value: (InputType | InputType[])[]): (InputType | InputType[])[] => {
  return value.map((item) => {
    if (Array.isArray(item)) {
      // Recursively handle nested arrays
      return item.map((subitem) => {
        if (subitem) return true;
        if (!subitem) return false;
        return subitem as InputType;
      });
    } else {
      if (item) return true;
      if (!item) return false;
      
      return item as InputType;
    }
  });
}

export const parseRole = (role: bigint | undefined): number => {
  const returnValue = 
  role == undefined ? 0
  : role == 4294967295n ? 6
  : role == 0n ? 0
  : Number(role)

  return returnValue
}


export const parseVoteData = (data: unknown[]): {votes: number[], holders: number, deadline: number, state: number} => {
  if ( !data || !isArray(data)) {
    throw new Error('@parseVoteData: data not an array.');
  }
  if (data.length != 4) {
    throw new Error('@parseVoteData: data not correct length.');
  }
  const dataTypes = data.map(item => item as UseReadContractsReturnType) 

  // console.log("@parseVoteData: waypoint 0", {dataTypes})
  
  let votes: number[]
  let holders: number 
  let deadline: number 
  let state: number 
  
  if (dataTypes[0] && 'result' in dataTypes[0]) {
    if (
      dataTypes[0].result == undefined || 
      !isArray(dataTypes[0].result)
    ) { 
      votes = [0, 0, 0] 
    } else {
      votes = dataTypes[0].result.map(item => Number(item))
    } 
  } else {
    votes = [0, 0, 0]
  }

  if ('result' in dataTypes[1]) {
    holders = Number(dataTypes[1].result)
  } else {
    holders = 0
  }

  if ('result' in dataTypes[2]) {
    deadline = Number(dataTypes[2].result)
  } else {
    deadline = 0
  }

  if ('result' in dataTypes[3]) {
    state = Number(dataTypes[3].result)
  } else {
    state = 0
  }

  return {votes, holders, deadline, state}
}
  
// Parse different types of errors and extract meaningful error messages
export const parseLawError = (rawReply: unknown): string => {
  // Handle null/undefined input
  if (rawReply == null) {
    return "."
  }

  // Convert to string for processing
  let errorString: string
  try {
    errorString = String(rawReply)
  } catch {
    return "."
  }

  // Handle boolean input
  if (typeof rawReply === 'boolean') {
    return "."
  }

  // Handle contract revert errors with hex signature
  if (errorString.includes("The contract function") && errorString.includes("reverted with the following signature:")) {
    const signatureMatch = errorString.match(/reverted with the following signature:\s*(0x[a-fA-F0-9]+)/)
    if (signatureMatch && signatureMatch[1]) {
      return `: The error signature is ${signatureMatch[1]}. That is all I know.`
    }
  }

  // Handle FailedCall() errors
  if (errorString.includes("FailedCall()")) {
    return ": the call reverted. Something seems to be wrong with the calldata. Please check and try again."
  }

  // Handle invalid address errors
  if (errorString.includes("Address") && errorString.includes("is invalid") && errorString.includes("viem@")) {
    return ": invalid account address provided."
  }

  // Handle SizeExceedsPaddingSizeError
  if (errorString.includes("SizeExceedsPaddingSizeError")) {
    return ": Invalid calldata provide. Please make sure it follows the 0x format."
  }

  // Handle contract revert errors with reason
  if (errorString.includes("reverted with the following reason:")) {
    const reasonMatch = errorString.match(/reverted with the following reason:\s*([^.\n]+)/)
    if (reasonMatch && reasonMatch[1]) {
      return `: ${reasonMatch[1].trim()}`
    }
  }

  // Handle other contract errors that might have different patterns
  // Add more patterns here as needed for different error types
  
  // If no recognized error pattern is found, return empty string
  return ". Please try again."
};

export const parseUri = (uri: unknown): string => {
  if (!isString(uri)) {
    throw new Error(`Incorrect uri, not a string: ${uri}`);
  }
  
  if (!isValidUrl(uri)) {
    throw new Error(`Incorrect uri, not a uri: ${uri}`);
  }
  // here can additional checks later. 

  return uri as string;
};

export const parseMetadata = (metadata: unknown): Metadata => {
  if ( !metadata || typeof metadata !== 'object' ) {
    throw new Error('Incorrect or missing data');
  }

  if ( 
    'icon' in metadata &&   
    'banner' in metadata &&   
    'description' in metadata && 
    'erc20s' in metadata &&
    'erc721s' in metadata &&
    'erc1155s' in metadata &&
    'attributes' in metadata 
    ) { 
        return ({
          icon: metadata.icon as string,
          banner: metadata.banner as string,
          description: parseDescription(metadata.description),
          erc20s: parseTokens(metadata.erc20s),
          erc721s: parseTokens(metadata.erc721s),
          erc1155s: parseTokens(metadata.erc1155s),
          attributes: parseAttributes(metadata.attributes)
        })
       }
      
    throw new Error('Incorrect data at program Metadata: some fields are missing or incorrect');
};

export const parse1155Metadata = (metadata: unknown): Token => {
  if ( !metadata || typeof metadata !== 'object' ) {
    throw new Error('Incorrect or missing data');
  }

  // I can always add more to this logic if I think it is needed... 
  let result: Token = {
    name: "unknown",
    symbol: "unknown", 
    balance: 0n
  }

  if ( 'name' in metadata) { result.name =  metadata.name as string }
  if ( 'symbol' in metadata) { result.symbol =  metadata.symbol as string }

  return result
};

export const parseProposalStatus = (state: string | undefined): string => {
  if (!isString(state)) {
    throw new Error(`Incorrect state, not a string: ${state}`);
  }

  switch (state) {
    case '0': return "Active";
    case '1': return "Cancelled";
    case '2': return "Defeated";
    case '3': return "Succeeded";
    case '4': return "Requested";
    case '5': return "Fulfilled";
    case '6': return "NonExistent";

    default:
      return "unsupported state";
  } 
 
};

export const parseErrorMessage = (message: unknown): boolean | string  => {
  if (typeof message == null) {
    return false
  }
  try {
    String(message)
  } catch {
    throw new Error('Incorrect or missing data at rawReply');
  }

  if (typeof message === 'boolean') {
    return message
  }

  if (typeof message !== 'boolean') {
    return String(message) // .split("\n")[1]
  }

  else {
    return false 
  }
};

export const shorterDescription = (message: string | undefined, output: "short" | "long" | "full")  => {
  if (!message) {
    return ""
  }

  if (!isString(message)) {
    throw new Error(`Incorrect message, not a string: ${message}`);
  }

  const splitMessage = message.split(":")

  if (output == "short") {
    return splitMessage[0]
  }

  if (output == "long") {
    return splitMessage[1] ? splitMessage[1] : splitMessage[0]
  } 

  if (output == "full") {
    return message
  }
};

// would be great to make this more dynamic. 
export const parseChainId = (chainId: string | undefined): 421614 | 11155111 | 11155420 | 31337 | undefined => {
  // console.log("@parseChainId: waypoint 0", {chainId})
  if (!chainId) {
    return undefined
  }
  if (chainId !== "421614" && chainId !== "11155111" && chainId !== "11155420" && chainId !== "31337") {
    return undefined
  }
  return parseInt(chainId) as 421614 | 11155111 | 11155420 | 31337 | undefined
}


export const parseActionData = (data: unknown[]): ActionTruncated => {
  if (!isArray(data)) {
    throw new Error('@parseActionData: data not an array.');
  }
  if (data.length != 12) {
    throw new Error('@parseActionData: data not correct length.');
  }

  // console.log("@parseActionData: waypoint 0", {data})

  const action: ActionTruncated = {
    cancelled: data[0] as boolean,
    requested: data[1] as boolean,
    fulfilled: data[2] as boolean,
    lawId: data[3] as bigint,
    voteStart: data[4] as bigint,
    voteDuration: data[5] as bigint,
    voteEnd: data[6] as bigint,
    caller: data[7] as `0x${string}`,
    againstVotes: data[8] as bigint,
    forVotes: data[9] as bigint,
    abstainVotes: data[10] as bigint,
    nonce: data[11] as unknown as string
  }

  // console.log("@parseActionData: waypoint 1", {action})

  return action as ActionTruncated
} 