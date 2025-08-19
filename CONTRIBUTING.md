# Contributing to Powers

Thank you for your interest in contributing to Powers! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Issue Guidelines](#issue-guidelines)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Code Style](#code-style)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

1. **Install Foundry** - Required for smart contract development
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Install Node.js dependencies**
   ```bash
   yarn install
   cd frontend && yarn install
   ```

### Setting up the Development Environment

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/powers.git
   cd powers
   ```

2. **Add the upstream remote**
   ```bash
   git remote add upstream https://github.com/7Cedars/powers.git
   ```

3. **Create a new branch for your work**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

## Development Workflow

### 1. Issue First Approach

Before writing any code, please:
1. Check existing issues to see if your problem/feature is already being worked on
2. Create an issue describing the problem or feature request
3. Wait for maintainer feedback before starting implementation

### 2. Branch Naming Convention

Use descriptive branch names:
- `feature/descriptive-feature-name`
- `fix/descriptive-bug-fix`
- `docs/update-readme`
- `refactor/component-name`
- `test/add-unit-tests`

### 3. Commit Message Convention

Follow conventional commits format:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(frontend): add user authentication component
fix(solidity): resolve reentrancy vulnerability in grant function
docs(readme): update deployment instructions
```

## Issue Guidelines

### Before Creating an Issue

1. **Search existing issues** to avoid duplicates
2. **Check the documentation** to see if your question is already answered
3. **Try to reproduce the issue** and provide detailed steps

### Issue Templates

We provide templates for different types of issues:
- **Bug Report**: For reporting bugs and issues
- **Feature Request**: For suggesting new features
- **Security Vulnerability**: For reporting security issues

### Issue Labels

We use the following labels to categorize issues:
- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Improvements or additions to documentation
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention is needed
- `needs-triage`: Needs maintainer review
- `security`: Security-related issues

## Pull Request Guidelines

### Before Submitting a PR

1. **Ensure your code follows the style guidelines**
2. **Write or update tests** for your changes
3. **Update documentation** if necessary
4. **Test your changes** thoroughly
5. **Ensure all CI checks pass**

### PR Review Process

1. **Self-review**: Review your own code before submitting
2. **Maintainer review**: At least one maintainer must approve
3. **CI checks**: All automated tests must pass
4. **Documentation**: Ensure documentation is updated
5. **Merge**: Once approved, maintainers will merge

### PR Template

Use the provided PR template to ensure all necessary information is included.

## Code Style

### Solidity

- Follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Use Foundry's formatter: `forge fmt`
- Maximum line length: 120 characters
- Use meaningful variable and function names
- Add NatSpec comments for public functions

### Frontend (TypeScript/React)

- Follow the existing code style in the project
- Use TypeScript for type safety
- Use meaningful component and variable names
- Add JSDoc comments for complex functions
- Use Prettier for formatting

### General

- Write clear, readable code
- Add comments for complex logic
- Keep functions small and focused
- Follow the DRY principle

## Testing

### Solidity Tests

- Write comprehensive unit tests for all new functionality
- Use Foundry's testing framework
- Aim for high test coverage
- Test both positive and negative cases
- Use descriptive test names

```bash
# Run all tests
forge test

# Run tests with verbose output
forge test -vvv

# Run specific test file
forge test --match-contract TestContractName
```

### Frontend Tests

- Write unit tests for React components
- Test user interactions and edge cases
- Ensure accessibility standards are met

```bash
# Run frontend tests
cd frontend
yarn test
```

## Documentation

### Code Documentation

- Add inline comments for complex logic
- Use NatSpec for Solidity functions
- Use JSDoc for TypeScript/JavaScript functions
- Keep documentation up to date

### Project Documentation

- Update README.md if needed
- Update relevant documentation in the `gitbook/` directory
- Add examples for new features
- Keep deployment instructions current

## Getting Help

If you need help with your contribution:

1. **Check the documentation** in the `gitbook/` directory
2. **Search existing issues** for similar problems
3. **Ask in the issue** you're working on
4. **Join our community** (link to be added)

## Recognition

Contributors will be recognized in:
- The project README
- Release notes
- GitHub contributors list

Thank you for contributing to Powers! 🚀
