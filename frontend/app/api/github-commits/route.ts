import { NextRequest, NextResponse } from 'next/server'

/**
 * Extracts the ETH signature from a commit message.
 * @param commitMessage The full message of the commit.
 * @returns The signature hash if found, otherwise null.
 */
function extractSignature(commitMessage: string): string | null {
  const signatureRegex = /---ETH signature---([\s\S]*?)---ETH signature---/;
  const match = commitMessage.match(signatureRegex);
  return match && match[1] ? match[1].trim() : null;
}

// The actual endpoint
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const repo = searchParams.get('repo')
    const branch = searchParams.get('branch')
    const commitHash = searchParams.get('commitHash')
    const maxAgeCommitInDays = searchParams.get('maxAgeCommitInDays')
    const githubApiKey = process.env.GITHUB_API_KEY

    if (!repo || !branch || !commitHash || !githubApiKey || !maxAgeCommitInDays) {
      return NextResponse.json(
        { 
          error: "Missing required parameters: repo, branch, commitHash, maxAgeCommitInDays, or GITHUB_API_KEY environment variable" 
        },
        { status: 400 }
      )
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Step 1: Compare the commit hash to the branch to see if it is part of the branch history  // 
    ///////////////////////////////////////////////////////////////////////////////////////////////
    const compareResponse = await fetch(
      `https://api.github.com/repos/${repo}/compare/${branch}...${commitHash}`,
      {
        method: 'GET',
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': `Bearer ${githubApiKey}`,
          'X-GitHub-Api-Version': '2022-11-28'
        }
      }
    )

    if (!compareResponse.ok) {
      console.log("GitHub API error:", compareResponse.status, compareResponse.statusText)
      return NextResponse.json(
        { error: `GitHub API returned status ${compareResponse.status}` },
        { status: compareResponse.status }
      )
    }

    // The status can be 'diverged', 'ahead', 'behind', or 'identical'.
    // If the commit is behind or identical, it is part of the branch history.
    const compareDataResponse = await compareResponse.json()
    if (compareDataResponse.status !== 'behind' && compareDataResponse.status !== 'identical') {
      console.log(`Commit ${commitHash} is not in the history of branch ${branch}.`);
      return NextResponse.json(
        { error: `Commit ${commitHash} is not in the history of branch ${branch}.` },
        { status: 400 }
      )
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Step 2: Get the commit data and check if it is older than the max age                      // 
    ///////////////////////////////////////////////////////////////////////////////////////////////
    const commitResponse = await fetch(
      `https://api.github.com/repos/${repo}/git/commits/${commitHash}`,
      {
        method: 'GET',
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': `Bearer ${githubApiKey}`,
          'X-GitHub-Api-Version': '2022-11-28'
        }
      }
    )

    if (!commitResponse.ok) {
      console.log("GitHub API error:", commitResponse.status, commitResponse.statusText)
      return NextResponse.json(
        { error: `GitHub API returned status ${commitResponse.status}` },
        { status: commitResponse.status }
      )
    }

    const commitData = await commitResponse.json()
    const commitMessage = commitData.message;
    const commitDate = new Date(commitData.committer.date);

    const commitDateString = new Date(commitDate)
    const now = new Date();
    const ageInMilliseconds = now.getTime() - commitDateString.getTime();
    const ageInDays = Math.floor(ageInMilliseconds / (1000 * 60 * 60 * 24));

    if (ageInDays > Number(maxAgeCommitInDays)) {
      console.log(`Commit ${commitHash} is older than ${maxAgeCommitInDays} days.`)
      return NextResponse.json(
        { error: `Commit ${commitHash} is older than ${maxAgeCommitInDays} days.` },
        { status: 400 }
      )
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Step 3: Extract the signature from the commit message                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////
    const signature = extractSignature(commitMessage);
    if (!signature) {
      console.log(`No signature found in commit ${commitHash}.`);
      return NextResponse.json(
        { error: `No signature found in commit ${commitHash}.` },
        { status: 400 }
      )
    }

    return NextResponse.json({
      success: true,
      data: {
        signature: signature
      }
    })


  } catch (error) {
    console.error('Error fetching GitHub commits:', error)
    return NextResponse.json(
      { 
        error: `Failed to check GitHub commits: ${error instanceof Error ? error.message : 'Unknown error'}` 
      },
      { status: 500 }
    )
  }
}

// export async function POST(request: NextRequest) {
//   try {
//     const body = await request.json()
//     const { repo, path, author } = body
//     const githubApiKey = process.env.GITHUB_API_KEY

//     // Validate inputs
//     if (!repo || !path || !author || !githubApiKey) {
//       return NextResponse.json(
//         { 
//           error: "Missing required parameters: repo, path, author, or GITHUB_API_KEY environment variable" 
//         },
//         { status: 400 }
//       )
//     }

//     // Calculate date 90 days ago in ISO 8601 format
//     const ninetyDaysAgo = new Date()
//     ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)
//     const sinceDate = ninetyDaysAgo.toISOString()

//     console.log(`Searching for commits by ${author} in path "${path}" since ${sinceDate}`)

//     // Make request to GitHub Repository Commits API
//     const githubResponse = await fetch(
//       `https://api.github.com/repos/${repo}/commits?path=${encodeURIComponent(path)}&since=${encodeURIComponent(sinceDate)}&per_page=100&sort=committer-date&direction=desc`,
//       {
//         method: 'GET',
//         headers: {
//           'Accept': 'application/vnd.github+json',
//           'Authorization': `Bearer ${githubApiKey}`,
//           'X-GitHub-Api-Version': '2022-11-28'
//         }
//       }
//     ) 

//     if (!githubResponse.ok) {
//       console.log("GitHub API error:", githubResponse.status, githubResponse.statusText)
//       return NextResponse.json(
//         { error: `GitHub API returned status ${githubResponse.status}` },
//         { status: githubResponse.status }
//       )
//     }

//     const commits = await githubResponse.json()
//     const matchingCommits = (commits as GitHubCommit[]).filter((commit) => 
//       commit.committer && commit.committer.login === author
//     )

//     console.log(`Found ${matchingCommits.length} commits by ${author} in path "${path}" in the last 90 days`)

//     return NextResponse.json({
//       success: true,
//       data: {
//         commitCount: matchingCommits.length,
//         searchParams: {
//           repo,
//           path,
//           author,
//           sinceDate
//         }
//       }
//     })

//   } catch (error) {
//     console.error('Error fetching GitHub commits:', error)
//     return NextResponse.json(
//       { 
//         error: `Failed to check GitHub commits: ${error instanceof Error ? error.message : 'Unknown error'}` 
//       },
//       { status: 500 }
//     )
//   }
// }
