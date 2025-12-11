const proposalId = args[0];
const choice = args[1]; 

const url = 'https://hub.snapshot.org/graphql/';
const gqlRequest = Functions.makeHttpRequest({
  url: url,
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  data: {
    query: `{\
        proposal(id: "${proposalId}") { \
          choices \
          state \
        } \
      }`,
  },
});

const gqlResponse = await gqlRequest;
if (gqlResponse.error) throw Error("Request failed");

const snapshotData = gqlResponse["data"]["data"];
if (snapshotData.proposal.state.length == 0) return Functions.encodeString("Proposal not recognised.");
if (snapshotData.proposal.state != "pending") return Functions.encodeString("Proposal not pending.");
if (!snapshotData.proposal.choices.includes(choice)) return Functions.encodeString("Choice not present.");
return Functions.encodeString("true");
