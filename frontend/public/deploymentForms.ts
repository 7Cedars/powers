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
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreibjnkey6ldzghkbnp73pigh4lj6rmnmqalzplcwfz25vmhl3rst3q",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeickdiqcdmjjwx6ah6ckuveufjw6n2g6qdvatuhxcsbmkub3pvshnm",
    description: "A simple DAO with a basic governance based on a separation of powers between delegates, an executive council and an admin. It is a good starting point for understanding the Powers protocol.",
    disabled: false,
    onlyLocalhost: false,
    fields: []
  },
  {
    id: 2,
    title: "Split Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiciziefght5urlxntfekn5au5gfaawgve6emam4fkumokjapn2q5e",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiduqnzehle3y5t47mxoxgqvbxqus7meu6gfxldzrff2r3cmzjdham",
    description: "Deploy Governance that splits decision making along type of proposal. In this example proposals are assessed on 3 different paths: low risk, repetitive tasks, mid risk and high risk, non-repetitive tasks. Each path has different voting thresholds and quorums to adjust security and efficiency according to the risk of the proposal.",
    disabled: false,
    onlyLocalhost: false,
    fields: []
  },
  {
    id: 3,
    title: "Packaged Upgrades",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreigj2wm3xpqmqhednl6wpocvqux3zqd4vdb4gndrnv4kqgyare3zka",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaxdinbxkpv5xa5od5yjho3bshpvzaacuxcnfgi6ie3galmwkggvi",
    description: "Deploy an organisation with to governance options, each encoded in an executable law that upgrades the Powers contract. Option A results in adopting a governance systsem similar to the Powers101 example. Option B results in adopting a governance systsem similar to the Split Governance example. Note that the upgrade is one-time use only. If you want to re-try, redeploy this organisation.",
    disabled: false,
    onlyLocalhost: false,
    fields: []
  },
  {
    id: 4,
    title: "Bridging Off-Chain Governance",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreid2erwqvdqoji6injd2qnlzprl5j5fztf53lmfdjxvlged4gyqpn4",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeigtg54snwvwxmotdelgholl2jny2xobla6eqmpi2chmxuy5pzs6dm",
    description: "Deploy a DAO that bridges off-chain snapshot votes to on-chain governor.sol governance. It uses a Chainlink Function subscription to check proposals on snapshot.box. Please see https://docs.chain.link/chainlink-functions for more information. After setting up a subscription, deploy this organisation and add the two snapshot laws as subscribers to your Chainlink Function subscription.",
    disabled: false,
    onlyLocalhost: false,
    fields: [
      { name: "snapshotSpace", placeholder: "Optional: Snapshot space address (0x...)", type: "text", required: false },
      { name: "governorAddress", placeholder: "Optional: Governor address (0x...)", type: "text", required: false },
      { name: "chainlinkSubscriptionId", placeholder: "Chainlink subscription ID, see docs.chain.link/chainlink-functions/resources/subscriptions", type: "number", required: true },
    ]
  },
  {
    id: 5,
    title: "Grants Manager",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreiawj6j4fkudjj6kr54ygn3j55cw3cvapuwqiib3uwfonoyyrr2q7i",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeibglg2jk56676ugqtarjzseiq6mpptuapal6xlkt5avm3gtxcwgcy",
    description: "Deploy a grant program using Powers. This program allows the general public to make proposals, has a sequential path for assess along scope, technicality and finances, and allows to distribute funds along milestones. It also has a mechanisms for challening decisions.",
    disabled: false,
    onlyLocalhost: false,
    fields: [
      { name: "parentDaoAddress", placeholder: "Parent DAO or your own address (0x...)", type: "text", required: true }
    ]
  },
  {
    id: 6,
    title: "Single Upgrades",
    uri: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreidxsk3sq7zsv2w6q4ighdplgn5akiony3rnplmagjc66p7ky4r3h4",
    banner: "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafybeiaexs22jpd7xiq2bl2snyerw2bi4m4drxsq73cqxcxxptokbbm4cm",
    description: "Deploy a governed upgrades DAO using Powers. This example implements a governance system where the previous DAO can adopt and revoke laws one by one, while delegates can veto these actions. It includes electoral laws for delegate nomination and election processes.",
    disabled: false,
    onlyLocalhost: true,
    fields: []
  }
]; 