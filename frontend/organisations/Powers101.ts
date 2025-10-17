import { Organization } from "./types";
import { powersAbi } from "@/context/abi";
import { Abi, encodeAbiParameters, encodeFunctionData } from "viem";
import { minutesToBlocks, ADMIN_ROLE, PUBLIC_ROLE, createConditions, getLawAddress } from "./helpers";
import { LawInitData } from "./types";
import openElection from "@/context/builds/OpenElection.json"
 

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
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibjnkey6ldzghkbnp73pigh4lj6rmnmqalzplcwfz25vmhl3rst3q",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeickdiqcdmjjwx6ah6ckuveufjw6n2g6qdvatuhxcsbmkub3pvshnm",
    description: "A simple DAO with basic governance based on a separation of powers between delegates, an executive council and an admin. It is a good starting point for understanding the Powers protocol.",
    disabled: false,
    onlyLocalhost: false
  },
  fields: [],
  dependencies: [
    {
      name: "Open Election", 
      abi: JSON.parse(JSON.stringify(openElection.abi)) as Abi,
      args: [],
      bytecode: JSON.parse(JSON.stringify(openElection.bytecode.object)) as `0x${string}`,
      ownable: true
    }
  ],

  createLawInitData: (powersAddress: `0x${string}`, deployedLaws: Record<string, `0x${string}`>, deployedDependencies: Record<string, `0x${string}`>): LawInitData[] => {
    const lawInitData: LawInitData[] = [];

    console.log("deployedLaws", deployedLaws);
    console.log("deployedDependencies", deployedDependencies);

    //////////////////////////////////////////////////////////////////
    //                 LAW 1: INITIAL SETUP                         //
    //////////////////////////////////////////////////////////////////

    lawInitData.push({
      nameDescription: "RUN THIS LAW FIRST: It assigns labels to laws and mints tokens. Press the refresh button to see the new labels.",
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
      nameDescription: "Statement of Intent: Create an SoI for an action that can later be executed by Delegates.",
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
      nameDescription: "Veto an action: Veto an action that has been proposed by the community.",
      targetLaw: getLawAddress("StatementOfIntent", deployedLaws),
      config: statementOfIntentConfig,
      conditions: createConditions({
        allowedRole: ADMIN_ROLE,
        needFulfilled: 2n
      })
    });

    // Law 4: Execute an action
    lawInitData.push({
      nameDescription: "Execute an action: Execute an action that has been proposed by the community.",
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

    // Law 5: Nominate me for delegate
    lawInitData.push({
      nameDescription: "Nominate oneself for any role.",
      targetLaw: getLawAddress("NominateMe", deployedLaws),
      config: "0x",
      conditions: createConditions({
        allowedRole: 1n
      })
    });

    // Law 6: Call election for delegate role
    lawInitData.push({
      nameDescription: "Call delegate election!: Please press the refresh button after the election has been deployed.",
      targetLaw: getLawAddress("ElectionStart", deployedLaws),
      config: encodeAbiParameters(
        [
          { name: 'ElectionList', type: 'address' },
          { name: 'ElectionTally', type: 'address' },
          { name: 'roleId', type: 'uint16' },
          { name: 'maxToElect', type: 'uint32' }
        ],
        [ 
          getLawAddress("ElectionList", deployedLaws), 
          getLawAddress("ElectionSelect", deployedLaws),
          2,
          5
        ]
      ),
      conditions: createConditions({
        allowedRole: ADMIN_ROLE
      })
    });

    // Law 7: Self select as community member
    lawInitData.push({
      nameDescription: "Self select as community member: Self select as a community member. Anyone can call this law.",
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

    return lawInitData;
  }
};

