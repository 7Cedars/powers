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
          scores \
        } \
      }`,
  },
});

const gqlResponse = await gqlRequest;
if (gqlResponse.error) throw Error("Request failed");

const snapshotData = gqlResponse["data"]["data"];
if (snapshotData.proposal.state.length == 0) return Functions.encodeString("Proposal not recognised.");
if (snapshotData.proposal.state != "closed") return Functions.encodeString("Vote not closed."); 

const index = snapshotData.proposal.choices.indexOf(choice) 
if (index == -1) return Functions.encodeString("Choice not present.");

const maxScore = Math.max(...snapshotData.proposal.scores)
if (maxScore != snapshotData.proposal.scores[index]) return Functions.encodeString("Choice did not pass.");

return Functions.encodeString("true");