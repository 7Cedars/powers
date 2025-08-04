import React from 'react';
import Image from 'next/image';
import { Powers } from '@/context/types';
import { bigintToRole } from '@/utils/bigintTo';

/**
 * Props for DynamicThumbnail component.
 */
interface DynamicThumbnailProps {
  roleId: bigint | number | string;
  powers: Powers;
  /**
   * Optionally override the image size (default 64)
   */
  size?: number;
  /**
   * Optionally override the className for the image
   */
  className?: string;
}

/**
 * Returns the best-matching thumbnail filename for a given role label or roleId.
 * @param labelOrId The role label or roleId as string
 * @returns The filename if found, or undefined
 */
function findMatchingThumbnail(labelOrId: string): string | undefined {
  // List of available PNG files in /public/roleThumbnails (update if new files are added)
  const files = [
    'admin.png', 'public.png', 'delega.png', 'devrel.png', 'hodl.png', 'holder.png', 'whale.png', 'dev.png', 'subscr.png', 'exec.png', 'memb.png', 'guard.png', 'security.png', 'user.png',
    '1.png', '2.png', '3.png', '4.png', '5.png', '6.png', 'select.png', 'unknown.png',
    'scop.png', 'techn.png', 'finan.png', 'imburs.png', 'judge.png', 'grant.png'
  ];
  // Lowercase for case-insensitive matching
  const lower = labelOrId.toLowerCase();
  // Try exact match first
  let match = files.find(f => f.replace('.png','').toLowerCase() === lower);
  if (match) return match;
  // Try partial match
  match = files.find(f => lower && lower.includes(f.replace('.png','').toLowerCase()));
  return match;
}

/**
 * DynamicThumbnail component: shows a role thumbnail based on roleId and label.
 * Falls back to unknown.png if no match is found.
 */
const DynamicThumbnail: React.FC<DynamicThumbnailProps> = ({ roleId, powers, size = 64, className = '' }) => {
  // Get the label for the roleId (e.g., 'Admin', 'Public', or custom label)
  let label = '';
  if (typeof roleId === 'bigint' || typeof roleId === 'number') {
    label = bigintToRole(BigInt(roleId), powers);
  } else if (typeof roleId === 'string') {
    // Try to parse as bigint, fallback to string
    try {
      label = bigintToRole(BigInt(roleId), powers);
    } catch {
      label = roleId;
    }
  }
  // Try to find a matching thumbnail by label, then by roleId
  let file = findMatchingThumbnail(label) || findMatchingThumbnail(String(roleId));
  if (!file) file = 'unknown.png';
  // Images in public/ are referenced from root
  const src = `/roleThumbnails/${file}`;
  return (
    <Image
      src={src}
      alt={`Role thumbnail for ${label}`}
      width={size}
      height={size}
      className={className || 'object-cover rounded-md bg-slate-50 bg-opacity-0'}
      unoptimized
    />
  );
};

export default DynamicThumbnail; 