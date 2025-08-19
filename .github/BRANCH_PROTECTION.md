# Branch Protection Rules

This document outlines the recommended branch protection rules for the Powers repository.

## Main Branch Protection

### Required Settings

1. **Require a pull request before merging**
   - ✅ Enable
   - ✅ Require approvals: 1
   - ✅ Dismiss stale PR approvals when new commits are pushed
   - ✅ Require review from code owners

2. **Require status checks to pass before merging**
   - ✅ Require branches to be up to date before merging
   - ✅ Status checks that are required:
     - `solidity-tests`
     - `frontend-tests`
     - `security-audit`
     - `dependency-check`

3. **Require conversation resolution before merging**
   - ✅ Enable

4. **Require signed commits**
   - ✅ Enable (recommended for security)

5. **Require linear history**
   - ✅ Enable (prevents merge commits)

6. **Include administrators**
   - ✅ Enable (applies rules to admins too)

### Optional Settings

1. **Restrict pushes that create files that are larger than 100 MB**
   - ✅ Enable

2. **Require deployments to succeed before merging**
   - ⚠️ Enable if you have deployment workflows

## Develop Branch Protection

Apply the same rules as main branch, but with:
- Require approvals: 1 (can be reduced from main)
- Status checks: Same as main

## Feature Branch Guidelines

- No protection rules needed
- Use descriptive names: `feature/descriptive-name`
- Delete after merge

## Setting Up Branch Protection

1. Go to your repository on GitHub
2. Navigate to Settings > Branches
3. Click "Add rule" or edit existing rules
4. Apply the settings above for `main` and `develop` branches

## Code Owners

Create a `.github/CODEOWNERS` file with:

```
# Global owners
* @7Cedars

# Solidity contracts
/solidity/ @7Cedars

# Frontend
/frontend/ @7Cedars

# Documentation
/gitbook/ @7Cedars
/docs/ @7Cedars
```

## Benefits

- **Code Quality**: Ensures all code is reviewed
- **Security**: Prevents unauthorized changes to main branches
- **Collaboration**: Encourages proper PR workflow
- **Automation**: Leverages CI/CD for quality checks
- **History**: Maintains clean git history
