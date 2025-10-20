# Organization System - Usage Examples

This document provides practical examples of using the new modular organization system.

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Creating a Simple Organization](#creating-a-simple-organization)
3. [Creating an Organization with Form Fields](#creating-an-organization-with-form-fields)
4. [Using Mock Contracts](#using-mock-contracts)
5. [Complex Governance Flows](#complex-governance-flows)
6. [Validation and Error Handling](#validation-and-error-handling)

## Basic Usage

### Accessing Organizations

```typescript
import { 
  organizations, 
  getOrganizationById, 
  getEnabledOrganizations 
} from "@/organisations";

// Get all organizations
const allOrgs = organizations;

// Get a specific organization
const powerBase = getOrganizationById("power-base");

// Get organizations available for deployment
const availableOrgs = getEnabledOrganizations(isLocalhost);
```

### Using in Components

```typescript
import { getEnabledOrganizations } from "@/organisations";

function MyComponent() {
  const isLocalhost = typeof window !== 'undefined' && 
    window.location.hostname === 'localhost';
  
  const orgs = getEnabledOrganizations(isLocalhost);
  
  return (
    <div>
      {orgs.map(org => (
        <div key={org.metadata.id}>
          <h3>{org.metadata.title}</h3>
          <p>{org.metadata.description}</p>
        </div>
      ))}
    </div>
  );
}
```

## Creating a Simple Organization

Here's a minimal organization with no user input required:

```typescript
// organisations/SimpleDAO.ts
import { Organization } from "./types";
import { LawInitData, createConditions } from "@/public/createLawInitData";
import { getConstants } from "@/context/constants";

const getLawAddress = (lawName: string, chainId: number): `0x${string}` => {
  const constants = getConstants(chainId);
  return constants.LAW_ADDRESSES[constants.LAW_NAMES.indexOf(lawName)];
};

export const SimpleDAO: Organization = {
  metadata: {
    id: "simple-dao",
    title: "Simple DAO",
    uri: "ipfs://your-metadata-uri",
    banner: "ipfs://your-banner-uri",
    description: "A basic DAO with admin-only governance",
    disabled: false,
    onlyLocalhost: false
  },

  fields: [], // No user input needed

  createLawInitData: (powersAddress, formData, chainId) => {
    return [
      {
        nameDescription: "Admin can execute any action",
        targetLaw: getLawAddress("OpenAction", chainId),
        config: "0x",
        conditions: createConditions({
          allowedRole: 0n // Admin only
        })
      }
    ];
  }
};
```

Then register it:

```typescript
// organisations/index.ts
import { SimpleDAO } from "./SimpleDAO";

export const organizations: Organization[] = [
  Powers101,
  PowerBase,
  SimpleDAO, // Add here
];
```

## Creating an Organization with Form Fields

Example organization that requires user input:

```typescript
// organisations/TreasuryDAO.ts
import { Organization } from "./types";
import { LawInitData, createConditions } from "@/public/createLawInitData";
import { encodeAbiParameters, encodeFunctionData } from "viem";

export const TreasuryDAO: Organization = {
  metadata: {
    id: "treasury-dao",
    title: "Treasury DAO",
    uri: "ipfs://metadata",
    banner: "ipfs://banner",
    description: "DAO with configurable treasury and voting token",
    disabled: false,
    onlyLocalhost: false
  },

  fields: [
    {
      name: "treasuryAddress",
      placeholder: "Treasury address (0x...)",
      type: "text",
      required: true
    },
    {
      name: "votingToken",
      placeholder: "Voting token address (0x...)",
      type: "text",
      required: true
    },
    {
      name: "quorumPercentage",
      placeholder: "Quorum percentage (e.g., 50)",
      type: "number",
      required: false
    }
  ],

  createLawInitData: (powersAddress, formData, chainId) => {
    // Access form data
    const treasury = formData.treasuryAddress as `0x${string}`;
    const token = formData.votingToken as `0x${string}`;
    const quorum = formData.quorumPercentage 
      ? BigInt(formData.quorumPercentage) 
      : 50n;

    return [
      {
        nameDescription: "Transfer from treasury",
        targetLaw: getLawAddress("BespokeActionSimple", chainId),
        config: encodeAbiParameters(
          [
            { name: 'target', type: 'address' },
            { name: 'functionSelector', type: 'bytes4' },
            { name: 'inputParams', type: 'string[]' }
          ],
          [
            treasury,
            "0xa9059cbb" as `0x${string}`, // transfer(address,uint256)
            ["address to", "uint256 amount"]
          ]
        ),
        conditions: createConditions({
          allowedRole: 1n,
          quorum: quorum,
          succeedAt: 51n,
          votingPeriod: 100n
        })
      }
    ];
  },

  // Optional validation
  validateFormData: (formData) => {
    const errors: string[] = [];
    
    if (!formData.treasuryAddress?.match(/^0x[a-fA-F0-9]{40}$/)) {
      errors.push("Invalid treasury address");
    }
    
    if (!formData.votingToken?.match(/^0x[a-fA-F0-9]{40}$/)) {
      errors.push("Invalid voting token address");
    }
    
    const quorum = parseInt(formData.quorumPercentage);
    if (quorum && (quorum < 1 || quorum > 100)) {
      errors.push("Quorum must be between 1 and 100");
    }
    
    return {
      valid: errors.length === 0,
      errors: errors.length > 0 ? errors : undefined
    };
  }
};
```

## Using Mock Contracts

Organizations can specify mock contracts that need to be deployed:

```typescript
// organisations/GrantDAO.ts
import { Organization } from "./types";

export const GrantDAO: Organization = {
  metadata: {
    id: "grant-dao",
    title: "Grant DAO",
    uri: "ipfs://metadata",
    banner: "ipfs://banner",
    description: "DAO with grant management",
    disabled: false,
    onlyLocalhost: true // Only available on localhost for testing
  },

  fields: [
    {
      name: "initialBudget",
      placeholder: "Initial budget in ETH",
      type: "number",
      required: true
    }
  ],

  createLawInitData: (powersAddress, formData, chainId) => {
    const grantAddress = getMockAddress("GrantMock", chainId);
    
    return [
      {
        nameDescription: "Submit grant proposal",
        targetLaw: getLawAddress("BespokeActionSimple", chainId),
        config: encodeAbiParameters(
          [
            { name: 'target', type: 'address' },
            { name: 'functionSelector', type: 'bytes4' },
            { name: 'inputParams', type: 'string[]' }
          ],
          [
            grantAddress,
            "0x12345678" as `0x${string}`, // submitProposal selector
            ["string uri", "uint256 amount"]
          ]
        ),
        conditions: createConditions({
          allowedRole: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFn
        })
      }
    ];
  },

  // Specify mock contracts to deploy
  getMockContracts: (formData) => {
    return [
      {
        name: "GrantMock",
        contractName: "Grant",
        constructorArgs: [
          formData.initialBudget || "1000000000000000000" // 1 ETH default
        ]
      }
    ];
  }
};
```

## Complex Governance Flows

Example showing law dependencies and multi-step flows:

```typescript
// organisations/ComplexDAO.ts
import { Organization } from "./types";
import { LawInitData, createConditions } from "@/public/createLawInitData";

const daysToBlocks = (days: number, chainId: number): bigint => {
  const constants = getConstants(chainId);
  return BigInt(Math.floor(days * constants.BLOCKS_PER_HOUR * 24));
};

export const ComplexDAO: Organization = {
  metadata: {
    id: "complex-dao",
    title: "Complex DAO",
    uri: "ipfs://metadata",
    banner: "ipfs://banner",
    description: "Multi-stage governance with proposals, vetos, and execution",
    disabled: false,
    onlyLocalhost: false
  },

  fields: [],

  createLawInitData: (powersAddress, formData, chainId) => {
    const lawInitData: LawInitData[] = [];

    // Law 1: Create proposal (Members only, requires vote)
    lawInitData.push({
      nameDescription: "Create Proposal: Members vote to create a proposal",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: encodeAbiParameters(
        [{ name: 'inputParams', type: 'string[]' }],
        [["address[] targets", "uint256[] values", "bytes[] calldatas"]]
      ),
      conditions: createConditions({
        allowedRole: 1n, // Members
        votingPeriod: daysToBlocks(7, chainId),
        quorum: 33n,
        succeedAt: 51n
      })
    });

    // Law 2: Veto proposal (Security council, requires high threshold)
    lawInitData.push({
      nameDescription: "Veto Proposal: Security council can veto",
      targetLaw: getLawAddress("StatementOfIntent", chainId),
      config: encodeAbiParameters(
        [{ name: 'inputParams', type: 'string[]' }],
        [["uint256 proposalId"]]
      ),
      conditions: createConditions({
        allowedRole: 2n, // Security Council
        needFulfilled: 1n, // Requires Law 1 to have passed
        votingPeriod: daysToBlocks(3, chainId),
        quorum: 66n,
        succeedAt: 66n
      })
    });

    // Law 3: Execute proposal (Executor role, requires Law 1, blocks if Law 2)
    lawInitData.push({
      nameDescription: "Execute Proposal: Execute after delay if not vetoed",
      targetLaw: getLawAddress("OpenAction", chainId),
      config: "0x",
      conditions: createConditions({
        allowedRole: 3n, // Executors
        needFulfilled: 1n, // Requires Law 1 (proposal created)
        needNotFulfilled: 2n, // Blocked if Law 2 (veto) passed
        delayExecution: daysToBlocks(2, chainId)
      })
    });

    // Law 4: Emergency execute (Admin, bypasses normal flow)
    lawInitData.push({
      nameDescription: "Emergency Execute: Admin can execute immediately",
      targetLaw: getLawAddress("OpenAction", chainId),
      config: "0x",
      conditions: createConditions({
        allowedRole: 0n // Admin only
      })
    });

    return lawInitData;
  }
};
```

## Validation and Error Handling

Advanced example with comprehensive validation:

```typescript
// organisations/ValidatedDAO.ts
import { Organization } from "./types";

export const ValidatedDAO: Organization = {
  metadata: {
    id: "validated-dao",
    title: "Validated DAO",
    uri: "ipfs://metadata",
    banner: "ipfs://banner",
    description: "DAO with strict input validation",
    disabled: false,
    onlyLocalhost: false
  },

  fields: [
    {
      name: "multisigAddress",
      placeholder: "Multisig address (0x...)",
      type: "text",
      required: true
    },
    {
      name: "minSignatures",
      placeholder: "Minimum signatures required",
      type: "number",
      required: true
    },
    {
      name: "timelock",
      placeholder: "Timelock in days",
      type: "number",
      required: true
    }
  ],

  validateFormData: (formData) => {
    const errors: string[] = [];

    // Validate address
    if (!formData.multisigAddress) {
      errors.push("Multisig address is required");
    } else if (!formData.multisigAddress.match(/^0x[a-fA-F0-9]{40}$/)) {
      errors.push("Invalid multisig address format");
    }

    // Validate min signatures
    const minSigs = parseInt(formData.minSignatures);
    if (!minSigs) {
      errors.push("Minimum signatures is required");
    } else if (minSigs < 1 || minSigs > 20) {
      errors.push("Minimum signatures must be between 1 and 20");
    }

    // Validate timelock
    const timelock = parseInt(formData.timelock);
    if (!timelock) {
      errors.push("Timelock is required");
    } else if (timelock < 1 || timelock > 365) {
      errors.push("Timelock must be between 1 and 365 days");
    }

    // Cross-field validation
    if (minSigs && timelock && minSigs > 10 && timelock < 2) {
      errors.push("High signature requirements should have longer timelocks");
    }

    return {
      valid: errors.length === 0,
      errors: errors.length > 0 ? errors : undefined
    };
  },

  createLawInitData: (powersAddress, formData, chainId) => {
    const timelock = daysToBlocks(parseInt(formData.timelock), chainId);
    
    return [
      {
        nameDescription: "Execute with timelock",
        targetLaw: getLawAddress("OpenAction", chainId),
        config: "0x",
        conditions: createConditions({
          allowedRole: 1n,
          delayExecution: timelock
        })
      }
    ];
  }
};
```

## Helper Patterns

### Reusable Helper Functions

```typescript
// organisations/helpers.ts
import { getConstants } from "@/context/constants";

export const getLawAddress = (lawName: string, chainId: number): `0x${string}` => {
  const constants = getConstants(chainId);
  const address = constants.LAW_ADDRESSES[constants.LAW_NAMES.indexOf(lawName)];
  if (!address) {
    throw new Error(`Law address not found for: ${lawName}`);
  }
  return address;
};

export const getMockAddress = (mockName: string, chainId: number): `0x${string}` => {
  const constants = getConstants(chainId);
  const address = constants.MOCK_ADDRESSES[constants.MOCK_NAMES.indexOf(mockName)];
  if (!address) {
    throw new Error(`Mock address not found for: ${mockName}`);
  }
  return address;
};

export const daysToBlocks = (days: number, chainId: number): bigint => {
  const constants = getConstants(chainId);
  return BigInt(Math.floor(days * constants.BLOCKS_PER_HOUR * 24));
};

export const minutesToBlocks = (minutes: number, chainId: number): bigint => {
  const constants = getConstants(chainId);
  return BigInt(Math.floor(minutes * constants.BLOCKS_PER_HOUR / 60));
};

// Role constants
export const ADMIN_ROLE = 0n;
export const PUBLIC_ROLE = 115792089237316195423570985008687907853269984665640564039457584007913129639935n;
```

### Using Helpers in Organizations

```typescript
import { Organization } from "./types";
import { 
  getLawAddress, 
  daysToBlocks, 
  ADMIN_ROLE, 
  PUBLIC_ROLE 
} from "./helpers";

export const MyDAO: Organization = {
  // ... metadata and fields
  
  createLawInitData: (powersAddress, formData, chainId) => {
    return [
      {
        nameDescription: "Public proposal creation",
        targetLaw: getLawAddress("StatementOfIntent", chainId),
        config: "0x",
        conditions: createConditions({
          allowedRole: PUBLIC_ROLE,
          votingPeriod: daysToBlocks(7, chainId)
        })
      }
    ];
  }
};
```

## Testing Organizations

```typescript
// organisations/__tests__/MyDAO.test.ts
import { MyDAO } from "../MyDAO";

describe("MyDAO", () => {
  it("should have correct metadata", () => {
    expect(MyDAO.metadata.id).toBe("my-dao");
    expect(MyDAO.metadata.title).toBe("My DAO");
    expect(MyDAO.metadata.disabled).toBe(false);
  });

  it("should generate law init data", () => {
    const powersAddress = "0x1234567890123456789012345678901234567890" as `0x${string}`;
    const formData = {};
    const chainId = 11155420; // Optimism Sepolia

    const laws = MyDAO.createLawInitData(powersAddress, formData, chainId);
    
    expect(laws).toHaveLength(3);
    expect(laws[0].nameDescription).toContain("Initial");
  });

  it("should validate form data", () => {
    if (MyDAO.validateFormData) {
      const result = MyDAO.validateFormData({
        treasuryAddress: "0x1234567890123456789012345678901234567890"
      });
      
      expect(result.valid).toBe(true);
    }
  });
});
```

## Summary

This new organization system provides:

1. **Modularity**: Each organization in its own file
2. **Type Safety**: Full TypeScript support
3. **Reusability**: Shared helpers and patterns
4. **Validation**: Built-in form validation
5. **Flexibility**: Easy to add/remove organizations
6. **Testing**: Each organization can be tested independently

For more details, see the main [README.md](./README.md).

