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
    // MODIFIED: Added new search parameter for the folder
    const folderName = searchParams.get('folderName') 
    const githubApiKey = process.env.GITHUB_API_KEY

    // MODIFIED: Updated validation check
    if (!repo || !branch || !commitHash || !githubApiKey || !maxAgeCommitInDays || !folderName) {
      return NextResponse.json(
        { 
          error: "Missing required parameters: repo, branch, commitHash, maxAgeCommitInDays, folderName, or GITHUB_API_KEY environment variable" 
        },
        { status: 400 }
      )
    }

    // MODIFIED: Normalize folder name to ensure it ends with a slash for accurate path matching
    const normalizedFolderName = folderName.endsWith('/') ? folderName : `${folderName}/`;

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
      console.log("GitHub API error (compare):", compareResponse.status, compareResponse.statusText)
      return NextResponse.json(
        { error: `GitHub API (compare) returned status ${compareResponse.status}` },
        { status: compareResponse.status }
      )
    }

    const compareDataResponse = await compareResponse.json()
    if (compareDataResponse.status !== 'behind' && compareDataResponse.status !== 'identical') {
      console.log(`Commit ${commitHash} is not in the history of branch ${branch}.`);
      return NextResponse.json(
        { error: `Commit ${commitHash} is not in the history of branch ${branch}.` },
        { status: 400 }
      )
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Step 2: Get commit data, check age, AND check file paths                                  // 
    ///////////////////////////////////////////////////////////////////////////////////////////////
    
    // MODIFIED: Changed endpoint from /git/commits/... to /commits/...
    const commitResponse = await fetch(
      `https://api.github.com/repos/${repo}/commits/${commitHash}`,
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
      console.log("GitHub API error (commit):", commitResponse.status, commitResponse.statusText)
      return NextResponse.json(
        { error: `GitHub API (commit) returned status ${commitResponse.status}` },
        { status: commitResponse.status }
      )
    }

    const commitData = await commitResponse.json()

    // MODIFIED: Data structure is different. Message/date are nested under `commit`
    const commitMessage = commitData.commit.message;
    const commitDate = new Date(commitData.commit.committer.date);
    // MODIFIED: Get the files array from the response
    const filesChanged = commitData.files; 

    // --- Age Check ---
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

    // --- MODIFIED: New check for folder path ---
    if (!Array.isArray(filesChanged)) {
        console.log(`Could not retrieve file list for commit ${commitHash}.`);
        return NextResponse.json(
          { error: `Could not retrieve file list for commit ${commitHash}.` },
          { status: 500 } // This is unexpected, so 500
        )
    }

    // Check if at least one file in the commit starts with the specified folder path
    const modifiedFolder = filesChanged.some(
      (file: { filename: string }) => file.filename.startsWith(normalizedFolderName)
    );

    if (!modifiedFolder) {
      console.log(`Commit ${commitHash} did not modify any files in ${normalizedFolderName}.`);
      return NextResponse.json(
        { error: `Commit ${commitHash} did not modify any files in ${normalizedFolderName}.` },
        { status: 400 } // 400 because the commit doesn't meet our criteria
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

// ... (rest of your file) ...