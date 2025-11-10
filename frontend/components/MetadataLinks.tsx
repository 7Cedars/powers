'use client'

import { 
  GlobeAltIcon, 
  DocumentTextIcon, 
  ScaleIcon,
  ChatBubbleLeftRightIcon,
  VideoCameraIcon,
  CodeBracketIcon,
  BookOpenIcon
} from '@heroicons/react/24/outline'
import { CommunicationChannels } from '@/context/types'

// SVG icons for social platforms (as heroicons doesn't have them all)
const DiscordIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515a.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0a12.64 12.64 0 0 0-.617-1.25a.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057a19.9 19.9 0 0 0 5.993 3.03a.078.078 0 0 0 .084-.028a14.09 14.09 0 0 0 1.226-1.994a.076.076 0 0 0-.041-.106a13.107 13.107 0 0 1-1.872-.892a.077.077 0 0 1-.008-.128a10.2 10.2 0 0 0 .372-.292a.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127a12.299 12.299 0 0 1-1.873.892a.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028a19.839 19.839 0 0 0 6.002-3.03a.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.956-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.955-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.946 2.418-2.157 2.418z"/>
  </svg>
)

const TelegramIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12a12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472c-.18 1.898-.962 6.502-1.36 8.627c-.168.9-.499 1.201-.82 1.23c-.696.065-1.225-.46-1.9-.902c-1.056-.693-1.653-1.124-2.678-1.8c-1.185-.78-.417-1.21.258-1.91c.177-.184 3.247-2.977 3.307-3.23c.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345c-.48.33-.913.49-1.302.48c-.428-.008-1.252-.241-1.865-.44c-.752-.245-1.349-.374-1.297-.789c.027-.216.325-.437.893-.663c3.498-1.524 5.83-2.529 6.998-3.014c3.332-1.386 4.025-1.627 4.476-1.635z"/>
  </svg>
)

const XIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
  </svg>
)

const FacebookIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
  </svg>
)

const YoutubeIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
  </svg>
)

const GithubIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>
  </svg>
)

const ParagraphIcon = ({ className }: { className?: string }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M13 4a4 4 0 0 1 4 4a4 4 0 0 1-4 4H9V4h4m2 14h2V4h-2v14m-4 0h2V4H9v14M3 4v2h4V4H3m0 14h4v-2H3v2Z"/>
  </svg>
)

type MetadataLinksProps = {
  website?: string;
  codeOfConduct?: string;
  disputeResolution?: string;
  communicationChannels?: CommunicationChannels;
}

export function MetadataLinks({ 
  website, 
  codeOfConduct, 
  disputeResolution, 
  communicationChannels 
}: MetadataLinksProps) {
  // Extract the first communication communicationChannels object (if it exists)

  // Helper function to check if a value is a valid link
  const isValidLink = (link?: string): link is string => {
    return !!link && link.trim() !== ''
  }

  // Main links configuration
  const mainLinks = [
    { url: website, icon: GlobeAltIcon, label: 'Website' },
    { url: codeOfConduct, icon: DocumentTextIcon, label: 'Code of Conduct' },
    { url: disputeResolution, icon: ScaleIcon, label: 'Dispute Resolution' }
  ].filter(link => isValidLink(link.url))

  // Communication communicationChannels configuration
  const socialLinks = communicationChannels ? [
    { url: communicationChannels.discord, icon: DiscordIcon, label: 'Discord' },
    { url: communicationChannels.telegram, icon: TelegramIcon, label: 'Telegram' },
    { url: communicationChannels.x, icon: XIcon, label: 'X (Twitter)' },
    { url: communicationChannels.paragraph, icon: ParagraphIcon, label: 'Paragraph' },
    { url: communicationChannels.youtube, icon: YoutubeIcon, label: 'YouTube' },
    { url: communicationChannels.facebook, icon: FacebookIcon, label: 'Facebook' },
    { url: communicationChannels.github, icon: GithubIcon, label: 'GitHub' },
    { url: communicationChannels.forum, icon: ChatBubbleLeftRightIcon, label: 'Forum' },
    { url: communicationChannels.documentation, icon: BookOpenIcon, label: 'Documentation' }
  ].filter(link => isValidLink(link.url)) : []

  // Don't render anything if there are no valid links
  if (mainLinks.length === 0 && socialLinks.length === 0) {
    return null
  }

  return (
    <section className="w-full h-fit flex flex-col gap-3 justify-left items-start border border-slate-300 rounded-md bg-slate-50 lg:max-w-full max-w-3xl p-4">
      {/* Main Links */}
      {mainLinks.length > 0 && (
        <div className="flex flex-wrap gap-3 items-center">
          {mainLinks.map((link, index) => {
            const Icon = link.icon
            return (
              <a
                key={index}
                href={link.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 px-3 py-2 rounded-md bg-white border border-slate-300 hover:border-slate-400 hover:shadow-sm transition-all duration-200 text-slate-700 hover:text-slate-900"
                title={link.label}
              >
                <Icon className="w-5 h-5" />
                <span className="text-sm font-medium">{link.label}</span>
              </a>
            )
          })}
        </div>
      )}

      {/* Communication communicationChannels */}
      {socialLinks.length > 0 && (
        <div className="w-full">
          {/* <div className="text-sm font-medium text-slate-600 mb-2">
            Communication communicationChannels
          </div> */}
          <div className="flex flex-wrap gap-2 items-center">
            {socialLinks.map((link, index) => {
              const Icon = link.icon
              return (
                <a
                  key={index}
                  href={link.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="p-2 rounded-md bg-white border border-slate-300 hover:border-slate-400 hover:shadow-sm transition-all duration-200 text-slate-600 hover:text-slate-900"
                  title={link.label}
                >
                  <Icon className="w-5 h-5" />
                </a>
              )
            })}
          </div>
        </div>
      )}
    </section>
  )
}

