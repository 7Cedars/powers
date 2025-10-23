const branch = args[0];
const commitHash = args[1];
const folderName = args[2]; 

if (!branch || !commitHash || !folderName) {
    throw Error("Missing required args");
}

const url = `https://powers-protocol.vercel.app/api/check-commit`; 

const githubRequest = Functions.makeHttpRequest({
    url: url,
    method: "GET",
    timeout: 9000, 
    params: {
        repo: "7cedars/powers",
        branch: branch,
        commitHash: commitHash,
        maxAgeCommitInDays: 90,
        folderName: folderName
    }
});

 
const githubResponse = await githubRequest;
if (githubResponse.error || !githubResponse.data || !githubResponse.data.data || !githubResponse.data.data.signature) {
    throw Error(`Request Failed: ${githubResponse.error.message}`);
}

return Functions.encodeString(githubResponse.data.data.signature);