import { NavLink, Outlet, Link, useNavigate } from 'react-router-dom'
import { NAV_ITEMS } from '../modules/navigation'
import { useAuth } from '../modules/auth/useAuth'

export default function AppLayout() {
  const { user, role, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  // Role-based sidebar menu filtering
  const visibleNavItems = NAV_ITEMS.filter((item) => {
    if (!item.roles || item.roles.length === 0) return true
    return item.roles.includes(role)
  })

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="brand">
          SUNRA <span>Showroom</span>
        </div>
        <nav>
          {visibleNavItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.path === '/'}
              className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
      </aside>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        {/* Header with user profile and action menu */}
        <header style={{
          background: 'var(--panel)',
          borderBottom: '1px solid #e3e7ec',
          padding: '12px 36px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'flex-end',
          gap: 16
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 14 }}>
            <span style={{ fontWeight: 600 }}>{user?.fullName || user?.username || 'User'}</span>
            <span style={{
              background: '#eef2f7',
              color: 'var(--sidebar)',
              fontSize: 11,
              fontWeight: 700,
              padding: '2px 8px',
              borderRadius: 12,
              textTransform: 'uppercase'
            }}>
              {role}
            </span>
          </div>

          <Link
            to="/change-password"
            style={{
              color: 'var(--muted)',
              fontSize: 13,
              textDecoration: 'none',
              padding: '6px 10px',
              borderRadius: 4
            }}
          >
            Change Password
          </Link>

          <button
            onClick={handleLogout}
            style={{
              background: 'transparent',
              border: '1px solid #d2d8e0',
              borderRadius: 6,
              padding: '6px 12px',
              fontSize: 13,
              fontWeight: 500,
              cursor: 'pointer',
              color: 'var(--text)'
            }}
          >
            Sign Out
          </button>
        </header>

        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
