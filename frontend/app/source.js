// make HTTP request
const proposalId = args[0];
const url = "https://hub.snapshot.org/graphql/";
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

// Execute the API request (Promise)
const gqlResponse = await gqlRequest;
if (gqlResponse.error) {
  throw Error("Request failed");
}

// Transform data
const countryData = gqlResponse["data"]["data"];
const result = {
  choices: countryData.proposal.choices,
  scores: countryData.proposal.scores,
  state: countryData.proposal.state
};
// console.log("result: ", {result})
// encode result 
return Functions.encodeString(JSON.stringify(result));