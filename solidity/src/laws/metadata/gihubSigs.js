// --- Inputs ---
// args[0]: repo (e.g., "7cedars/powers")
// args[1]: branch (e.g., "main")
// args[2]: commitHash (e.g., "0x123abc...")
// args[3]: folderName (e.g., "src/proposals/")

const repo = args[0];
const branch = args[1];
const commitHash = args[2];
const folderName = args[3];

// --- Hardcoded value from your request ---
const maxAgeCommitInDays = "90";

// --- Validate Inputs ---
if (!repo || !branch || !commitHash || !folderName) {
    throw Error("Missing required args");
}

// --- API Request ---
// This URL must point to your deployed `route.ts` file.
// I'm using the host from your .sol file as a placeholder.
const url = `https://powers-protocol.vercel.app/api/check-commit`; 

const githubRequest = Functions.makeHttpRequest({
    url: url,
    method: "GET",
    timeout: 9000, // 9-second timeout
    params: {
        repo: repo,
        branch: branch,
        commitHash: commitHash,
        maxAgeCommitInDays: maxAgeCommitInDays,
        folderName: folderName
    }
});

// --- Execute Request ---
const githubResponse = await githubRequest;

// --- Handle Response ---
if (githubResponse.error || !githubResponse.data || !githubResponse.data.data || !githubResponse.data.data.signature) {
    // Network error or timeout
    throw Error(`Request Failed: ${githubResponse.error.message}`);
}

// --- Success ---
// Return the signature string
return Functions.encodeString(githubResponse.data.data.signature);