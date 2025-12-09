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
    url: `https://api.github.com/repos/${repo}/commits`,
    method: "GET",
    headers: {
        'Accept': 'application/vnd.github+json',
        'Authorization': `Bearer ${secrets.githubApiKey}`,
        'X-GitHub-Api-Version': '2022-11-28'
    },
    params: {
        path: path,
        since: sinceDate,
        per_page: 100,
        sort: 'committer-date',
        direction: 'desc'
    },
    timeout: 9000
})

try {
    const [githubResponse] = await Promise.all([githubRequest])
    
    if (githubResponse.status !== 200) {
        console.log("GitHub API error:", githubResponse.status, githubResponse.data)
        throw Error(`GitHub API returned status ${githubResponse.status}`)
    }
    
    const commits = githubResponse.data || []
    const matchingCommits = commits.filter(commit => commit.committer && commit.committer.login === author)
    
    console.log(`Found ${matchingCommits.length} commits by ${author} in path "${path}" in the last 90 days`)
    
    return Functions.encodeUint256(matchingCommits.length)
    
} catch (error) {
    throw Error(`Failed to check GitHub commits: ${error.message}`)
}