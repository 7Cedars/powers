import { Organization } from "./types";
import { Powers101 } from "./Powers101"; 
import { PowerLabs } from "./PowerLabs";
import { PowerLabsChild } from "./PowerLabsChild";
import { Bicameralism } from "./Bicameralism";
import { NestedGovernanceChild } from "./NestedGovernanceChild";
import { NestedGovernanceParent } from "./NestedGovernanceParent";
import { OpenElections } from "./OpenElections";
import { OptimisticExecution } from "./OptimisticExecution";
import { TokenDelegates } from "./TokenDelegates";

/**
 * Registry of all available organizations
 * Add new organizations here to make them available for deployment
 */
export const organizations: Organization[] = [
  Powers101,
  PowerLabs, 
  PowerLabsChild,
  Bicameralism,
  NestedGovernanceChild,
  NestedGovernanceParent,
  OpenElections,
  OptimisticExecution,
  TokenDelegates
  // Add more organizations here as they are implemented
];

/**
 * Get an organization by its ID
 */
export function getOrganizationById(id: string): Organization | undefined {
  return organizations.find(org => org.metadata.id === id);
}

/**
 * Get an organization by its title
 */
export function getOrganizationByTitle(title: string): Organization | undefined {
  return organizations.find(org => org.metadata.title === title);
}

/**
 * Get all organizations that should be visible on localhost
 */
export function getLocalHostOrganizations(): Organization[] {
  return organizations.filter(org => org.metadata.onlyLocalhost);
}

/**
 * Get all organizations that should be visible everywhere
 */
export function getPublicOrganizations(): Organization[] {
  return organizations.filter(org => !org.metadata.onlyLocalhost);
}

/**
 * Get all enabled organizations
 */
export function getEnabledOrganizations(isLocalhost: boolean = false): Organization[] {
  return organizations.filter(org => 
    !org.metadata.disabled && 
    (!org.metadata.onlyLocalhost || (org.metadata.onlyLocalhost && isLocalhost))
  );
}

// Re-export types for convenience
export type { Organization, OrganizationField, OrganizationMetadata, DeployableContract } from "./types";

