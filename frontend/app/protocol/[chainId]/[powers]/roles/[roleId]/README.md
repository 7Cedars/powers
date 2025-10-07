# Role Members Page

This page displays all members (holders) of a specific role in a Powers organization.

## Features

- Displays role information (name, ID, thumbnail)
- Lists all addresses that hold the specific role
- Fetches data directly from the contract using `getRoleHolders(roleId)`
- Refresh functionality to update member list
- Clean table layout matching other list pages

## Route Structure

`/protocol/[chainId]/[powers]/roles/[roleId]`

- `chainId`: The blockchain network ID
- `powers`: The Powers contract address
- `roleId`: The specific role ID to display members for

## Components

- `page.tsx`: Main page component with role info header
- `MemberList.tsx`: Table component displaying all role members

