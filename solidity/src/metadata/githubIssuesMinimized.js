const repo = args[0]
const path = args[1]
const author = args[2]

// Validate inputs
if (!repo || !path || !author || !secrets.githubApiKey) {
    throw Error("Missing required arguments: repo, path, author, or githubApiKey")
}

const ninetyDaysAgo = new Date()
ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)
const sinceDate = ninetyDaysAgo.toISOString()

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
        throw Error(`GitHub API returned status ${githubResponse.status}`)
    }    
    const commits = githubResponse.data || []
    const matchingCommits = commits.filter(commit => commit.committer && commit.committer.login === author)
    
    return Functions.encodeUint256(matchingCommits.length)
} catch (error) {
    throw Error(`Failed to check GitHub commits: ${error.message}`)
}