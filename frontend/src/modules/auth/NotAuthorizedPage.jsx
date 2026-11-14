import { Link } from 'react-router-dom'
import { useAuth } from './useAuth'

export default function NotAuthorizedPage() {
  const { role } = useAuth()

  return (
    <div style={{ maxWidth: 520, margin: '60px auto', textAlign: 'center' }}>
      <h1 style={{ color: 'var(--error)', fontSize: 32, marginBottom: 8 }}>403 - Not Authorized</h1>
      <p className="muted" style={{ fontSize: 16, lineHeight: 1.5, marginBottom: 24 }}>
        Your current role (<strong>{role || 'Unknown'}</strong>) does not have permission to access this module.
      </p>
      <Link
        to="/"
        style={{
          display: 'inline-block',
          background: 'var(--accent)',
          color: '#13202f',
          textDecoration: 'none',
          fontWeight: 600,
          padding: '10px 20px',
          borderRadius: 6,
        }}
      >
        Return to Dashboard
      </Link>
    </div>
  )
}
