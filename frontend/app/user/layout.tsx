import { UserNavigation } from '@/app/user/UserNavigation'

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
