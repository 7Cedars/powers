import { NextRequest, NextResponse } from 'next/server'

interface GitHubCommit {
  committer: {
    login: string;
  } | null;
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const repo = searchParams.get('repo')
    const path = searchParams.get('path')
    const author = searchParams.get('author')
    const githubApiKey = process.env.GITHUB_API_KEY

    // Validate inputs
    if (!repo || !path || !author || !githubApiKey) {
      return NextResponse.json(
        { 
          error: "Missing required parameters: repo, path, author, or GITHUB_API_KEY environment variable" 
        },
        { status: 400 }
      )
    }

    // Calculate date 90 days ago in ISO 8601 format
    const ninetyDaysAgo = new Date()
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)
    const sinceDate = ninetyDaysAgo.toISOString()

    console.log(`Searching for commits by ${author} in path "${path}" since ${sinceDate}`)

    // Make request to GitHub Repository Commits API
    const githubResponse = await fetch(
      `https://api.github.com/repos/${repo}/commits?path=${encodeURIComponent(path)}&since=${encodeURIComponent(sinceDate)}&per_page=100&sort=committer-date&direction=desc`,
      {
        method: 'GET',
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': `Bearer ${githubApiKey}`,
          'X-GitHub-Api-Version': '2022-11-28'
        }
      }
    )

    if (!githubResponse.ok) {
      console.log("GitHub API error:", githubResponse.status, githubResponse.statusText)
      return NextResponse.json(
        { error: `GitHub API returned status ${githubResponse.status}` },
        { status: githubResponse.status }
      )
    }

    const commits = await githubResponse.json()
    const matchingCommits = (commits as GitHubCommit[]).filter((commit) => 
      commit.committer && commit.committer.login === author
    )

    console.log(`Found ${matchingCommits.length} commits by ${author} in path "${path}" in the last 90 days`)

    return NextResponse.json({
      success: true,
      data: {
        commitCount: matchingCommits.length,
        searchParams: {
          repo,
          path,
          author,
          sinceDate
        }
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

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { repo, path, author } = body
    const githubApiKey = process.env.GITHUB_API_KEY

    // Validate inputs
    if (!repo || !path || !author || !githubApiKey) {
      return NextResponse.json(
        { 
          error: "Missing required parameters: repo, path, author, or GITHUB_API_KEY environment variable" 
        },
        { status: 400 }
      )
    }

    // Calculate date 90 days ago in ISO 8601 format
    const ninetyDaysAgo = new Date()
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90)
    const sinceDate = ninetyDaysAgo.toISOString()

    console.log(`Searching for commits by ${author} in path "${path}" since ${sinceDate}`)

    // Make request to GitHub Repository Commits API
    const githubResponse = await fetch(
      `https://api.github.com/repos/${repo}/commits?path=${encodeURIComponent(path)}&since=${encodeURIComponent(sinceDate)}&per_page=100&sort=committer-date&direction=desc`,
      {
        method: 'GET',
        headers: {
          'Accept': 'application/vnd.github+json',
          'Authorization': `Bearer ${githubApiKey}`,
          'X-GitHub-Api-Version': '2022-11-28'
        }
      }
    ) 

    if (!githubResponse.ok) {
      console.log("GitHub API error:", githubResponse.status, githubResponse.statusText)
      return NextResponse.json(
        { error: `GitHub API returned status ${githubResponse.status}` },
        { status: githubResponse.status }
      )
    }

    const commits = await githubResponse.json()
    const matchingCommits = (commits as GitHubCommit[]).filter((commit) => 
      commit.committer && commit.committer.login === author
    )

    console.log(`Found ${matchingCommits.length} commits by ${author} in path "${path}" in the last 90 days`)

    return NextResponse.json({
      success: true,
      data: {
        commitCount: matchingCommits.length,
        searchParams: {
          repo,
          path,
          author,
          sinceDate
        }
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
