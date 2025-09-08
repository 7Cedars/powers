import { PortalNavigation } from '@/components/PortalNavigation'

export default function PortalLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <PortalNavigation>
      {children}
    </PortalNavigation>
  )
}
