const proposalId = args[0];
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
          scores \
          state \
        } \
      }`,
  },
});

const gqlResponse = await gqlRequest;
if (gqlResponse.error) throw Error("Request failed");

const countryData = gqlResponse["data"]["data"];
const result = countryData.proposal.choices; 
console.log("result: ", {result})
return Functions.encodeString(JSON.stringify(result));

// const result = {
//   choices: countryData.proposal.choices,
//   scores: countryData.proposal.scores,
//   state: countryData.proposal.state
// };
