// checks how many commits were made by author on a specific folder path within the last 90 days. Returns the count as a uint256.

const repo = args[0]
const path = args[1]
const author = args[2]

// Validate inputs
if (!repo || !path || !author) {
    throw Error("Missing required arguments: repo, path or author")
}

// Make request to GitHub Repository Commits API
const githubRequest = Functions.makeHttpRequest({
    url: `https://powers-git-develop-7cedars-projects.vercel.app/api/github-commits?repo=${repo}&path=${path}&author=${author}`,
    method: "GET",
    timeout: 5000
})

try {
    const [githubResponse] = await Promise.all([githubRequest])
    const commitCount = githubResponse.data.commitCount
    
    return Functions.encodeUint256(commitCount)
    
} catch (error) {
    throw Error(`Failed to check GitHub commits: ${error.message}`)
}