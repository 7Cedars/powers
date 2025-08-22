// checks how many commits were made by author on a specific folder path within the last 90 days. Returns the count as a uint256.

const repo = args[0]
const path = args[1]
const author = args[2]

// Validate inputs
if (!repo || !path || !author || !secrets.githubApiKey) {
    throw Error("Missing required arguments: repo, path, author, or githubApiKey")
}

// Calculate date 90 days ago in ISO 8601 format
const ninetyDaysAgo = new Date()
ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)
const sinceDate = ninetyDaysAgo.toISOString() // Format as YYYY-MM-DDTHH:MM:SSZ

console.log(`Searching for commits by ${author} in path "${path}" since ${sinceDate}`)

// Make request to GitHub Repository Commits API
const githubRequest = Functions.makeHttpRequest({
    url: `https://powers-protocol.vercel.app/api/github-commits?repo=${repo}&path=${path}&author=${author}`,
    method: "GET",
    headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': `Bearer ${secrets.githubApiKey}`,
        'X-GitHub-Api-Version': '2022-11-28'
    },
    timeout: 5000
})

try {
    const [githubResponse] = await Promise.all([githubRequest])
    
    if (githubResponse.status !== 200) {
        console.log("GitHub API error:", githubResponse.status, githubResponse.data)
        throw Error(`GitHub API returned status ${githubResponse.status}`)
    }
    
    const commitCount = githubResponse.data.commitCount
    
    console.log(`Found ${commitCount} commits by ${author} in path "${path}" in the last 90 days`)
    
    return Functions.encodeUint256(commitCount)
    
} catch (error) {
    throw Error(`Failed to check GitHub commits: ${error.message}`)
}