import { UserNavigation } from '@/components/UserNavigation'

export default function UserLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <UserNavigation>
      {children}
    </UserNavigation>
  )
}
