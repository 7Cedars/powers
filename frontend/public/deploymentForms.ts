export interface DeploymentForm {
  id: number;
  title: string;
  uri: string; 
  banner: string;
  description: string;
  disabled: boolean;
  onlyLocalhost: boolean;
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
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreighvtmagvaungqtvig2rz5lour4nj6m6jgnjbr7husq4m7cicukxm",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeickdiqcdmjjwx6ah6ckuveufjw6n2g6qdvatuhxcsbmkub3pvshnm",
    description: "A simple DAO with a basic governance based on a separation of powers between delegates, an executive council and an admin. It is a good starting point for understanding the Powers protocol. The treasury address is optional, if left empty a mock treasury address is used.",
    disabled: false,
    onlyLocalhost: false,
    fields: [
      { name: "treasuryAddress", placeholder: "Optional: Treasury address (0x...)", type: "text", required: false }
    ]
  },
  {
    id: 2,
    title: "Bridging Off-Chain Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreihwyr2mtoxodb3s3572lvixhskxbv5gjshli2rhnj7ermfhu7z6ni",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeigtg54snwvwxmotdelgholl2jny2xobla6eqmpi2chmxuy5pzs6dm",
    description: "Deploy a DAO that bridges off-chain snapshot votes to on-chain governor.sol governance. The ERC20Votes contract, snapshot space and governor address are optional, if left empty a mock contract, space and address are used.",
    disabled: false,
    onlyLocalhost: false,
    fields: [
      { name: "erc20Votes", placeholder: "Optional: Erc20Votes address (0x...)", type: "text", required: false },
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
    onlyLocalhost: false,
    fields: [
      { name: "parentDaoAddress", placeholder: "Optional: Parent DAO address (0x...)", type: "text", required: false },
      { name: "grantTokenAddress", placeholder: "Optional: Grant token address (0x...)", type: "text", required: false },
      { name: "assessors", placeholder: "Optional: Assessors addresses (0x...), comma separated", type: "text", required: false }
    ]
  },
  {
    id: 4,
    title: "Split Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiabdhbbcfcj6mgfusngaoapxwirqcpm3fjw45qvwsnuzke7k3ftoi",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiduqnzehle3y5t47mxoxgqvbxqus7meu6gfxldzrff2r3cmzjdham",
    description: "Deploy Governance that splits decision making along type of proposal. It is a well known approach to creating efficient decision making processes.",
    disabled: false,
    onlyLocalhost: false,
    fields: [
      { name: "treasuryAddress", placeholder: "Optional: Treasury address (0x...)", type: "text", required: false }
    ]
  },
  {
    id: 5,
    title: "Packaged Upgrades",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreidwzi5bvmcew73ixlgv7a37fgiajwl2iruq5ttllaakfxj7irsue4",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaxdinbxkpv5xa5od5yjho3bshpvzaacuxcnfgi6ie3galmwkggvi",
    description: "Deploy an organisation with to governance options, each encoded in an executable law that upgrades the Powers contract.",
    disabled: false,
    onlyLocalhost: false,
    fields: []
  }
]; 