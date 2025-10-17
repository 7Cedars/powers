# Quick Start Guide

Get up and running with the new organization system in 5 minutes!

## Using the New System (Right Now!)

### Step 1: Update Your UI Component

In your `app/page.tsx` or wherever you use the deployment carousel:

```typescript
// Change this:
import { SectionDeployCarousel } from "./SectionDeployCarousel";

// To this:
import { SectionDeployCarouselV2 } from "./SectionDeployCarouselV2";

export default function Home() {
  return (
    <main>
      <SectionDeployCarouselV2 />  {/* New component */}
    </main>
  );
}
```

### Step 2: That's It!

You now have access to:
- ✅ **Powers 101** - Simple DAO template
- ✅ **Power Base** - Complete grant management system

## Testing Power Base

### Deploy Power Base

1. Visit your app at `http://localhost:3000`
2. Navigate to the deployment carousel
3. Select "Power Base"
4. Click "Deploy Power Base"
5. Wait for deployment and constitution
6. Click "See Your New Powers"

### What You'll See

**40 Laws organized into categories:**

1. **Initial Setup** (Law 1)
   - Run first to assign role labels

2. **Budget Management** (Laws 2-11)
   - Propose Documentation Budget
   - Propose Frontend Budget
   - Propose Protocol Budget
   - Veto Budget
   - Set budgets (3 laws)
   - Whitelist tokens (3 laws)

3. **Documentation Grants** (Laws 12-16)
   - Submit proposal
   - Veto proposal
   - Approve grant
   - Release milestone
   - Reject grant

4. **Frontend Grants** (Laws 17-21)
   - Same as documentation grants

5. **Protocol Grants** (Laws 22-26)
   - Same as documentation grants

6. **Electoral Laws** (Laws 27-37)
   - Github to EVM mapping
   - Github to Role assignment
   - Fund Development
   - Apply for Membership
   - Veto role revocation
   - Remove roles (5 laws)

7. **Constitutional Laws** (Laws 38-40)
   - Propose law package
   - Veto law package
   - Adopt law package

## Adding Your First Organization

### 1. Create File

Create `organisations/MySimpleDAO.ts`:

```typescript
import { Organization } from "./types";
import { getLawAddress, ADMIN_ROLE, PUBLIC_ROLE } from "./helpers";
import { createConditions } from "@/public/createLawInitData";

export const MySimpleDAO: Organization = {
  metadata: {
    id: "my-simple-dao",
    title: "My Simple DAO",
    uri: "ipfs://your-metadata-uri",
    banner: "ipfs://your-banner-uri",
    description: "A simple DAO where admins can execute any action",
    disabled: false,
    onlyLocalhost: false
  },

  fields: [],

  createLawInitData: (powersAddress, formData, chainId) => {
    return [
      {
        nameDescription: "Admin can execute any action",
        targetLaw: getLawAddress("OpenAction", chainId),
        config: "0x",
        conditions: createConditions({
          allowedRole: ADMIN_ROLE
        })
      },
      {
        nameDescription: "Anyone can make proposals",
        targetLaw: getLawAddress("StatementOfIntent", chainId),
        config: "0x",
        conditions: createConditions({
          allowedRole: PUBLIC_ROLE
        })
      }
    ];
  }
};
```

### 2. Register It

Edit `organisations/index.ts`:

```typescript
import { MySimpleDAO } from "./MySimpleDAO";

export const organizations: Organization[] = [
  Powers101,
  PowerBase,
  MySimpleDAO,  // Add this line
];
```

### 3. Test It

Refresh your browser - "My Simple DAO" now appears in the carousel!

## Common Use Cases

### Use Case 1: Organization with User Input

```typescript
export const ConfigurableDAO: Organization = {
  metadata: { /* ... */ },
  
  fields: [
    {
      name: "treasuryAddress",
      placeholder: "Treasury address (0x...)",
      type: "text",
      required: true
    }
  ],
  
  createLawInitData: (powersAddress, formData, chainId) => {
    const treasury = formData.treasuryAddress as `0x${string}`;
    
    return [
      {
        nameDescription: `Transfer from ${treasury}`,
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
        conditions: createConditions({ allowedRole: ADMIN_ROLE })
      }
    ];
  }
};
```

### Use Case 2: Organization with Validation

```typescript
import { validators, createValidationResult } from "./helpers";

export const ValidatedDAO: Organization = {
  metadata: { /* ... */ },
  
  fields: [
    { name: "multisigAddress", placeholder: "0x...", type: "text", required: true }
  ],
  
  validateFormData: (formData) => {
    const errors: string[] = [];
    
    const addressError = validators.address(
      formData.multisigAddress, 
      "Multisig address"
    );
    if (addressError) errors.push(addressError);
    
    return createValidationResult(errors);
  },
  
  createLawInitData: (powersAddress, formData, chainId) => {
    // ... laws
  }
};
```

### Use Case 3: Organization with Mock Contracts

```typescript
export const GrantDAO: Organization = {
  metadata: { /* ... */ },
  fields: [],
  
  createLawInitData: (powersAddress, formData, chainId) => {
    const grantAddress = getMockAddress("GrantMock", chainId);
    // ... use grantAddress in laws
  },
  
  getMockContracts: (formData) => {
    return [
      {
        name: "GrantMock",
        contractName: "Grant"
      }
    ];
  }
};
```

## Helpful Imports

```typescript
// Core types
import { Organization, OrganizationField } from "./types";

// Law creation
import { LawInitData, createConditions } from "@/public/createLawInitData";

// Helpers
import { 
  getLawAddress,
  getMockAddress,
  daysToBlocks,
  hoursToBlocks,
  minutesToBlocks,
  ADMIN_ROLE,
  PUBLIC_ROLE,
  validators,
  createValidationResult,
  GrantFunctionSelectors
} from "./helpers";

// Viem utilities
import { encodeAbiParameters, encodeFunctionData } from "viem";

// ABIs
import { powersAbi, erc20TaxedAbi, erc20VotesAbi } from "@/context/abi";

// Constants
import { getConstants } from "@/context/constants";
```

## Available Laws

Use these law names with `getLawAddress()`:

**Executive Laws:**
- `"OpenAction"` - Execute arbitrary calls
- `"StatementOfIntent"` - Create proposals
- `"PresetAction"` - Execute pre-configured actions
- `"BespokeActionSimple"` - Execute specific function calls
- `"AdoptLawPackage"` - Adopt multiple laws at once
- `"Erc20Budget"` - Manage ERC20 budgets

**Electoral Laws:**
- `"NominateMe"` - Self-nomination
- `"SelfSelect"` - Self-selection for roles
- `"DirectSelect"` - Direct role assignment
- `"DirectDeselect"` - Direct role removal
- `"DelegateSelect"` - Token-weighted selection
- `"ElectionStart"` - Start an election
- `"ElectionList"` - Election list contract
- `"ElectionTally"` - Election tally contract
- `"RoleByGitCommit"` - Assign roles by GitHub commits
- `"RoleByRoles"` - Assign roles based on other roles
- `"BuyAccess"` - Pay for role assignment
- `"StringToAddress"` - Map strings to addresses

**Grant Laws:**
- `"GrantProgram"` - Manage grant programs
- `"Grant"` - Individual grant management
- `"EndGrant"` - End a grant
- `"GrantProposal"` - Submit grant proposals
- `"FlagActions"` - Flag actions for review
- `"NStrikesYourOut"` - Remove after N strikes

## Pro Tips

1. **Start Simple:** Copy Powers101.ts and modify it
2. **Use Helpers:** Don't duplicate utility functions
3. **Add Validation:** Use `validateFormData` for user input
4. **Test Locally:** Set `onlyLocalhost: true` while developing
5. **Document Laws:** Use descriptive `nameDescription` for each law
6. **Comment Dependencies:** Note which laws depend on others

## Troubleshooting

### Organization doesn't appear in carousel

- Check that you added it to `organisations/index.ts`
- Verify `disabled: false` in metadata
- If `onlyLocalhost: true`, ensure you're on localhost

### Deployment fails

- Check law addresses are correct for your chain
- Verify function selectors match contract ABIs
- Ensure all required fields are filled

### Type errors

- Import types from `./types`
- Use `as \`0x${string}\`` for addresses
- Check formData types match field definitions

## Next Steps

1. ✅ Try deploying Power Base
2. ✅ Create your first simple organization
3. 📖 Read README.md for details
4. 📖 Check USAGE_EXAMPLE.md for patterns
5. 📖 Review MIGRATION_GUIDE.md to migrate existing orgs

## Need Help?

- **Architecture:** See `README.md`
- **Examples:** See `USAGE_EXAMPLE.md`
- **Migration:** See `MIGRATION_GUIDE.md`
- **Reference:** See `PowerBase.ts` (comprehensive)
- **Simple Example:** See `Powers101.ts`
- **Utilities:** See `helpers.ts`

Happy coding! 🚀

