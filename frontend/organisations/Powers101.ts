import { Organization } from "./types";
import { powersAbi } from "@/context/abi";
import { Abi, encodeAbiParameters, encodeFunctionData } from "viem";
import { minutesToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, getLawAddress } from "./helpers";
import { LawInitData } from "./types"; 
 

/**
 * Powers 101 Organization
 * 
 * A simple DAO with basic governance based on separation of powers between 
 * delegates, members, and an admin. Perfect for learning the Powers protocol.
 * 
 * Key Features:
 * - Statement of Intent system for proposals
 * - Delegate execution with voting requirements
 * - Veto power for admin
 * - Self-nomination and election system
 * - Community membership via self-selection
 */
export const Powers101: Organization = {
  metadata: {
    id: "powers-101",
    title: "Powers 101",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreicbh6txnypkoy6ivngl3l2k6m646hruupqspyo7naf2jpiumn2jqe",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeickdiqcdmjjwx6ah6ckuveufjw6n2g6qdvatuhxcsbmkub3pvshnm",
    description: "A simple DAO with basic governance based on a separation of powers between delegates, an executive council and an admin. It is a good starting point for understanding the Powers protocol.",
    disabled: false,
    onlyLocalhost: false
  },
  fields: [],
  dependencies: [ ],

  createLawInitData: (
    powersAddress: `0x${string}`, 
    formData: Record<string, any>,
    deployedLaws: Record<string, `0x${string}`>,
    dependencyReceipts: Record<string, any>,
    chainId: number,
  ): LawInitData[] => {
    const lawInitData: LawInitData[] = [];

    console.log("deployedLaws @Powers101", deployedLaws);
    console.log("deployedDependencies @Powers101", deployedLaws);

    //////////////////////////////////////////////////////////////////
    //                 LAW 1: INITIAL SETUP                         //
    //////////////////////////////////////////////////////////////////

    lawInitData.push({
      nameDescription: "Initial Setup: Assign role labels (Members, Delegates) and revoke itself after execution",
      targetLaw: getLawAddress("PresetSingleAction", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'targets', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
          { name: 'calldatas', type: 'bytes[]' }
        ],
        [
          [
            powersAddress, 
            powersAddress,  
            powersAddress
          ],
          [0n, 0n, 0n],
          [
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",
              args: [1n, "Members"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "labelRole",  
              args: [2n, "Delegates"]
            }),
            encodeFunctionData({
              abi: powersAbi,
              functionName: "revokeLaw",
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
    //                    EXECUTIVE LAWS                            //
    //////////////////////////////////////////////////////////////////

    const statementOfIntentConfig = encodeAbiParameters(
      [{ name: 'inputParams', type: 'string[]' }],
      [["address[] Targets", "uint256[] Values", "bytes[] Calldatas"]]
    );

    // Law 2: Statement of Intent
    lawInitData.push({
      nameDescription: "Propose Action: Members propose actions through a Statement of Intent that Delegates can later execute",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: statementOfIntentConfig,
      conditions: createConditions({
        allowedRole: 1n,
        votingPeriod: minutesToBlocks(5, Number(deployedLaws.chainId)),
        succeedAt: 51n,
        quorum: 20n
      })
    });

    // Law 3: Veto an action
    lawInitData.push({
      nameDescription: "Veto Action: Admin can veto actions proposed by the community",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: statementOfIntentConfig,
      conditions: createConditions({
        allowedRole: ADMIN_ROLE,
        needFulfilled: 2n
      })
    });

    // Law 4: Execute an action
    lawInitData.push({
      nameDescription: "Execute Action: Delegates approve and execute actions proposed by the community",
      targetLaw: getLawAddress("OpenAction", deployedLaws),
      config: "0x",
      conditions: createConditions({
        allowedRole: 2n,
        quorum: 50n,
        succeedAt: 77n,
        votingPeriod: minutesToBlocks(5, Number(deployedLaws.chainId)),
        needFulfilled: 2n,
        needNotFulfilled: 3n,
        delayExecution: minutesToBlocks(3, Number(deployedLaws.chainId))
      })
    });

    //////////////////////////////////////////////////////////////////
    //                    ELECTORAL LAWS                            //
    //////////////////////////////////////////////////////////////////

    // Law 5: Self select as community member
    lawInitData.push({
      nameDescription: "Join as Member: Anyone can self-select to become a community member",
      targetLaw: getLawAddress("SelfSelect", deployedLaws),
      config: encodeAbiParameters(
        [{ name: 'roleId', type: 'uint256' }],
        [1n]
      ),
      conditions: createConditions({
        throttleExecution: 25n,
        allowedRole: PUBLIC_ROLE
      })
    });

    // Law 6: Self select as delegate
    lawInitData.push({
      nameDescription: "Become Delegate: Community members can self-select to become a Delegate",
      targetLaw: getLawAddress("SelfSelect", deployedLaws),
      config: encodeAbiParameters(
        [{ name: 'roleId', type: 'uint256' }],
        [2n]
      ),
      conditions: createConditions({
        throttleExecution: 25n,
        allowedRole: 1n
      })
    });

    return lawInitData;
  }
};
