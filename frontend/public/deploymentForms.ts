export interface DeploymentForm {
  id: number;
  title: string;
  uri: string; 
  banner: string;
  description: string;
  disabled: boolean;
  onLocalhost: boolean;
  fields: {
    name: string;
    placeholder: string;
    type: string;
    required: boolean;
  }[];
}

export const deploymentForms: DeploymentForm[] = [
  {
    id: 1,
    title: "Powers 101",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreieioptfopmddgpiowg6duuzsd4n6koibutthev72dnmweczjybs4q",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeibbtfbr5t7ndfwrh2gp5xwleahnezkugqiwcfj5oktvt5heijoswq",
    description: "A simple DAO with a basic governance based on a separation of powers between delegates, an executive council and an admin. It is a good starting point for understanding the Powers protocol. The treasury address is optional, if left empty a mock treasury address is used.",
    disabled: false,
    onLocalhost: false,
    fields: [
      { name: "treasuryAddress", placeholder: "Optional: Treasury address (0x...)", type: "text", required: false }
    ]
  },
  {
    id: 2,
    title: "Bridging Off-Chain Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiakcm5i4orree75muwzlezxyegyi2wjluyr2l657oprgfqlxllzoi",
    banner: "",
    description: "Deploy a DAO that bridges off-chain snapshot votes to on-chain governor.sol governance. The snapshot space and governor address are optional, if left empty a mock space and address are used.",
    disabled: false,
    onLocalhost: false,
    fields: [
      { name: "snapshotSpace", placeholder: "Optional: Snapshot space address (0x...)", type: "text", required: false },
      { name: "governorAddress", placeholder: "Optional: Governor address (0x...)", type: "text", required: false },
      { name: "chainlinkSubscriptionId", placeholder: "Chainlink subscription ID, see docs.chain.link/chainlink-functions/resources/subscriptions", type: "number", required: true },
    ]
  },
  {
    id: 3,
    title: "Grants Manager",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiduudrmyjwrv3krxl2kg6dfuofyag7u2d22beyu5os5kcitghtjbm",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeibglg2jk56676ugqtarjzseiq6mpptuapal6xlkt5avm3gtxcwgcy",
    description: "Deploy a DAO focused on grant management. This form allows you to deploy a Powers.sol instance with grant distribution laws. The grant manager contract is optional, if left empty a mock grant manager contract is used. Assessors can also be selected after the deployment.",
    disabled: true,
    onLocalhost: false,
    fields: [
      { name: "parentDaoAddress", placeholder: "Optional: Parent DAO address (0x...)", type: "text", required: false },
      { name: "grantTokenAddress", placeholder: "Optional: Grant token address (0x...)", type: "text", required: false },
      { name: "assessors", placeholder: "Optional: Assessors addresses (0x...), comma separated", type: "text", required: false }
    ]
  },
  {
    id: 4,
    title: "Split Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiduudrmyjwrv3krxl2kg6dfuofyag7u2d22beyu5os5kcitghtjbm",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeibglg2jk56676ugqtarjzseiq6mpptuapal6xlkt5avm3gtxcwgcy",
    description: "Deploy Governance that splits decision making along type of proposal.",
    disabled: false,
    onLocalhost: true,
    fields: [
      { name: "treasuryAddress", placeholder: "Optional: Treasury address (0x...)", type: "text", required: false }
    ]
  }
]; 