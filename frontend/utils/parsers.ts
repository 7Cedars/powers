import { ChangeEvent } from "react";
import { InputType, DataType, Metadata, Attribute, Token } from "../context/types"
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
  const errorMessage = 'Incorrect input data';
  if ( !event.target.value && typeof event.target.value !== 'string' && typeof event.target.value !== 'number' && typeof event.target.value !== 'boolean' ) {
     throw new Error('@parseInput: Incorrect or missing data.');
  }

  // Note that later on I can also check for maximum values by taking the power of uintxxx
  if (dataType.indexOf('uint') > -1) {
    try {
      return Number(event.target.value) 
    } catch {
      return errorMessage
    }
  }

  if (dataType.indexOf('bool') > -1) {
    try {
      return event.target.value == 'true'
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('string') > -1) { 
    try {
      return event.target.value as string 
    } catch {
      return errorMessage
    }
  }
  
  if (dataType.indexOf('address') > -1) {
    try {
      return event.target.value as `0x${string}` 
    } catch {
      return errorMessage
    }
  }

  if (dataType.indexOf('bytes') > -1)  {
    try {
      return event.target.value as `0x${string}` 
    } catch {
      return errorMessage
    }
  }
};

export const parseRole = (role: bigint | undefined): number => {
  const returnValue = 
  role == undefined ? 0
  : role == 4294967295n ? 6
  : role == 0n ? 0
  : Number(role)

  return returnValue
}


export const parseVoteData = (data: unknown[]): {votes: number[], holders: number, deadline: number} => {
  if ( !data || !isArray(data)) {
    throw new Error('@parseVoteData: data not an array.');
  }
  if (data.length != 3) {
    throw new Error('@parseVoteData: data not correct length.');
  }
  const dataTypes = data.map(item => item as UseReadContractsReturnType) 
  let votes: number[]
  let holders: number 
  let deadline: number 
  
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

  return {votes, holders, deadline}
}
  
// direct copy for now from loyal-customer-engagement project. Adapt as needed. 
export const parseLawError = (rawReply: unknown): boolean | string  => {
  if (typeof rawReply == null) {
    return false
  }
  try {
    String(rawReply)
  } catch {
    throw new Error('Incorrect or missing data at rawReply');
  }

  if (typeof rawReply === 'boolean') {
    return rawReply
  }

  if (typeof rawReply !== 'boolean') {
    const splitString = String(rawReply).split(`\n`) 
    // console.log(rawReply)
    return splitString[2]
  }

  else {
    return false 
  }
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
    'attributes' in metadata 
    ) { 
        return ({
          icon: metadata.icon as string,
          banner: metadata.banner as string,
          description: parseDescription(metadata.description),
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
    case '4': return "Completed"; 

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


