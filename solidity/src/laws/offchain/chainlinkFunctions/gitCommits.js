const repo = args[0]
const path = args[1]
const author = args[2]

if (!repo || !path || !author) {
    throw Error("Missing required arguments: repo, path or author")
}

const githubRequest = Functions.makeHttpRequest({
    url: `https://powers-git-develop-7cedars-projects.vercel.app/api/github-commits?repo=${repo}&path=${path}&author=${author}`,
    method: "GET",
    timeout: 7000
})

try {
    const [githubResponse] = await Promise.all([githubRequest])
    const commitCount = githubResponse.data.commitCount
    return Functions.encodeUint256(commitCount)    
} catch (error) {
    throw Error(`Failed to check GitHub commits: ${error.message}`)
}