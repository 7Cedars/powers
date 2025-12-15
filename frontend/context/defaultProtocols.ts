import { Powers } from './types'

/**
 * Default Powers 101 protocol
 * 
 * A simple DAO with basic governance based on a separation of powers between 
 * delegates, an executive council and an admin. It is a good starting point 
 * for understanding the Powers protocol.
 */
export const defaultPowers101: Powers = {
  contractAddress: '0x4d18b96126fa23a04c1d00b77b370b562edaa450' as `0x${string}`,
  chainId: 11155420n,
  name: 'Powers 101',
  uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreicbh6txnypkoy6ivngl3l2k6m646hruupqspyo7naf2jpiumn2jqe",
  metadatas: {
    icon: '/logo1_notext.png',
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeickdiqcdmjjwx6ah6ckuveufjw6n2g6qdvatuhxcsbmkub3pvshnm",
    description: "A simple DAO with basic governance based on a separation of powers between delegates, an executive council and an admin. It is a good starting point for understanding the Powers protocol.",
    attributes: []
  },
  mandateCount: 0n,
  mandates: [],
  roles: [],
}

/**
 * Default Power Labs protocol
 * 
 * Power Labs is the on-chain organization that shepherds the development 
 * of the Powers protocol. It uses Safes (and its allowance modules) for asset management.
 * It is governed by contributors that are verified via EVM signatures posted 
 * in github commits.
 */
export const defaultPowerLabs: Powers = {
  contractAddress: '0x08b4220e5e67152ee5c40658711035b4ca86ba60' as `0x${string}`,
  chainId: 11155111n,
  name: 'Power Labs',
  uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibnvjwah2wdgd3fhak3sedriwt5xemjlacmrabt6mrht7f24m5w3i",
  metadatas: {
    icon: '/logo1_notext.png',
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideomrrzq4goct7we74barpvwte7qvbaljrj3azlwiyzzjku6wsou",
    description: "Power Labs is the on-chain organization that shepherds the development of the Powers protocol. It uses Safes (and its allowance modules) for asset management.",
    attributes: []
  },
  mandateCount: 0n,
  mandates: [],
  roles: [],
}

/**
 * Default Power Labs Child protocol
 * 
 * Power Labs Child is the on-chain organization that manages one specific field of development of the Powers protocol.
 * of the Powers protocol. It uses Safes (and its allowance modules) for asset management.
 */
export const defaultPowerLabsChild: Powers = {
  contractAddress: '0xc74504061fb47c1a3aec36d0ac4d199d3364a321' as `0x${string}`,
  chainId: 11155111n,
  name: 'Power Labs Child: Docs',
  uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreichqvnlmfgkw2jeqgerae2torhgbcgdomxzqxiymx77yhflpnniii",
  metadatas: {
    icon: '/logo1_notext.png',
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaxdinbxkpv5xa5od5yjho3bshpvzaacuxcnfgi6ie3galmwkggvi",
    description: "Power Labs Child: Docs is the on-chain organization that shepherds the development of documentation for the Powers protocol.",
    attributes: []
  },
  mandateCount: 0n,
  mandates: [],
  roles: [],
}

