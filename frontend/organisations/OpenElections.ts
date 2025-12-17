import { Organization, MandateInitData, isDeployableContract, isFunctionCallDependency, DeployableContract } from "./types";
import { powersAbi, safeL2Abi, safeProxyFactoryAbi } from "@/context/abi";  
import { Abi, encodeAbiParameters, encodeFunctionData, parseAbiParameters, keccak256, encodePacked, toFunctionSelector } from "viem";
import { getMandateAddress, daysToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, createMandateInitData, minutesToBlocks } from "./helpers";
import nominees from "@/context/builds/Nominees.json";
import openElection from "@/context/builds/OpenElection.json";
import { getConstants } from "@/context/constants";
import { sepolia, arbitrumSepolia, optimismSepolia, mantleSepoliaTestnet, foundry } from "@wagmi/core/chains";

/**
 * Helper function to extract contract address from receipt
 */
function getContractAddressFromReceipt(receipt: any, contractName: string): `0x${string}` {
  if (!receipt || !receipt.contractAddress) {
    throw new Error(`Failed to get contract address for ${contractName} from receipt.`);
  }
  return receipt.contractAddress;
}

/**
 * Helper function to extract return value from function call receipt
 */
function getReturnValueFromReceipt(receipt: any): any {
  // This would need to be implemented based on the specific function call 
  // For now, return the receipt itself - the organization can extract what it needs
  return receipt;
}

/**
 * Open Elections
 *
 * Implements a simple open elections governance structure.
 * 
 * Note that for testing purposes, daysToBlocks has been replaced with minutesToBlocks. In reality every minute is a day. 
 */
export const OpenElections: Organization = {
  metadata: {
    id: "open-elections",
    title: "Open Elections",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiaaprfqxtgyxa5v2dnf7edfbc3mxewdh4axf4qtkurpz66jh2f2ve",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeideyeixpz7bkqxpasrlhu7ia3plir6z5b2vh3d7w26e5is27nqyfu",
    description: "Open Elections demonstrates how, using the Powers protocol, electoral lists can be used to assign roles to accounts. (These type of approaches are becoming more popular, see for instance the elections for Arbitrum's Security council, or multiple options votes). The specific logic used for an electoral list can be customised in its mandate implementation.",
    disabled: false,
    onlyLocalhost: true
  },
  fields: [ ],
  dependencies:  [ 
    {
        name: "OpenElection",
        abi: openElection.abi as Abi,
        bytecode: openElection.bytecode.object as `0x${string}`,
        args: [],
        ownable: true
    }
  ],
  allowedChains: [
    sepolia.id,
    arbitrumSepolia.id,
    optimismSepolia.id, 
  ],
  allowedChainsLocally: [
    sepolia.id, 
    arbitrumSepolia.id,
    optimismSepolia.id, 
    foundry.id
  ],
 
  createMandateInitData: (
    powersAddress: `0x${string}`,
    formData: Record<string, any>,
    deployedMandates: Record<string, `0x${string}`>,
    dependencyReceipts: Record<string, any>,
    chainId: number,
  ): MandateInitData[] => {
    const mandateInitData: MandateInitData[] = [];
    let mandateCounter = 0;
    // console.log("deployedMandates @ PowerLabs", deployedMandates);
    // console.log("chainId @ createMandateInitData", {formData, selection: formData["chainlinkSubscriptionId"] as bigint});
    
    //////////////////////////////////////////////////////////////////
    //                 INITIAL SETUP & ROLE LABELS                  //
    //////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Initial Setup: Assign role labels (Delegates, Funders) and revokes itself after execution",
      targetMandate: getMandateAddress("PresetSingleAction", deployedMandates),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [ powersAddress, powersAddress,  powersAddress ],
          [0n, 0n, 0n],
          [
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",
              args: [1n, "Voters"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [2n, "Delegates"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "revokeMandate",
              args: [1n]
            })
          ]
        ]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });

        
    //////////////////////////////////////////////////////////////////
    //                       OPEN ELECTIONS LAWS                    //
    //////////////////////////////////////////////////////////////////
    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Nominate for Delegates: Anyone can nominate themselves for the Token Delegate role.",
      targetMandate: getMandateAddress("Nominate", deployedMandates),
      config: encodeAbiParameters(
        parseAbiParameters("address OpenElection"),
        [ getContractAddressFromReceipt(dependencyReceipts["OpenElection"], "OpenElection") ]
      ),
      conditions: createConditions({
        allowedRole: 1n, // Voters: only accounts with Voter role can nominate for delegate
      })
    });
    const nominateForDelegates = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Open an election: Open an election in the OpenElection contract and adopt a bespoke vote law.",
      targetMandate: getMandateAddress("PresetSingleAction", deployedMandates),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [ 
            getContractAddressFromReceipt(dependencyReceipts["OpenElection"], "OpenElection"), 
            powersAddress 
          ],
          [
            0n, 
            0n 
          ],
          [
            encodeFunctionData({
              abi: openElection.abi as Abi,
              functionName: "openElection",
              args: [
                minutesToBlocks(5, chainId), // voting period
              ]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "adoptMandate",
              args: [
                encodeAbiParameters(
                    // Curious if this will work as intended. 
                    parseAbiParameters("string nameDescription, address targetMandate, bytes config, tuple(uint256,uint32,uint32,uint32,uint16,uint16,uint8,uint8) Conditions"),
                    [ 
                        "Vote in Open Election: Allows voters to vote in open elections.", 
                        getMandateAddress("VoteInOpenElection", deployedMandates),
                        encodeAbiParameters(
                            parseAbiParameters("address openElectionContract, uint256 maxVotes"),
                            [ 
                                getContractAddressFromReceipt(dependencyReceipts["OpenElection"], "OpenElection"),
                                3n // max votes
                            ]
                        ),
                        createConditions({
                            allowedRole: 1n // Voters
                        })
                    ]
                ),
              ]
            })
          ]
        ]
      ),
      conditions: createConditions({
        allowedRole: 1n, // Voters: only accounts with Voter role can nominate for delegate
      })
    }); 


    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Nominate for Delegates: Anyone can nominate themselves for the Token Delegate role.",
      targetMandate: getMandateAddress("Nominate", deployedMandates),
      config: encodeAbiParameters(
        parseAbiParameters("address VotesToken, address Nominees, uint256 RoleId, uint256 MaxRoleHolders"),
        [ 
          getConstants(chainId).VOTES_TOKEN as `0x${string}`,
          getContractAddressFromReceipt(dependencyReceipts["Nominees"], "Nominees"), 
          2n,
          10n
        ]
      ),
      conditions: createConditions({
        allowedRole: PUBLIC_ROLE,
        votingPeriod: minutesToBlocks(5, chainId),
        succeedAt: 51n,
        needFulfilled: nominateForDelegates,
        quorum: 50n
      })
    });

    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    ///////////////////////////////////////////////////////////////// 
    const assignRevokeRoleConfig = encodeAbiParameters(
      parseAbiParameters('address powers, bytes4 FunctionSelector, string[] Params'),
      [
        powersAddress,
        toFunctionSelector("assignRoles(address[],uint256[])"),
        ["address account", "uint256 roleId"]
      ]
    );

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "Admin can assign any role: For this demo, the admin can assign any role to an account.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config: assignRevokeRoleConfig,
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });
    const assignAnyRole = BigInt(mandateCounter);

    mandateCounter++;
    mandateInitData.push({
      nameDescription: "A delegate can revoke a role: For this demo, any delegate can revoke previously assigned roles.",
      targetMandate: getMandateAddress("BespokeActionSimple", deployedMandates),
      config:assignRevokeRoleConfig,
      conditions: createConditions({
        allowedRole: 2n,
        needFulfilled: assignAnyRole
      })
    });  

    return mandateInitData;
  }
};
