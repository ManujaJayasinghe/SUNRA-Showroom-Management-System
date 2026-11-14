import { useState } from 'react'
import { Navigate, useNavigate, useLocation } from 'react-router-dom'
import { useAuth } from './useAuth'

export default function LoginPage() {
  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  // Redirect to dashboard (or intended page) if already signed in
  if (isAuthenticated) {
    const destination = location.state?.from?.pathname || '/'
    return <Navigate to={destination} replace />
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSubmitting(true)

    try {
      await login({ username: username.trim(), password })
      const destination = location.state?.from?.pathname || '/'
      navigate(destination, { replace: true })
    } catch (err) {
      setError(err.userMessage || 'Invalid username or password')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'var(--bg)',
      padding: 16
    }}>
      <div style={{
        width: '100%',
        maxWidth: 380,
        background: 'var(--panel)',
        borderRadius: 8,
        padding: 32,
        boxShadow: '0 4px 20px rgba(19, 32, 47, 0.08)'
      }}>
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--sidebar)' }}>
            SUNRA <span style={{ color: 'var(--accent)', fontWeight: 500 }}>Showroom</span>
          </div>
          <p className="muted" style={{ margin: '6px 0 0', fontSize: 14 }}>
            Sign in to access your showroom terminal
          </p>
        </div>

        {error && (
          <div style={{
            background: 'rgba(192, 57, 43, 0.08)',
            borderLeft: '4px solid var(--error)',
            color: 'var(--error)',
            padding: '10px 12px',
            borderRadius: 4,
            fontSize: 14,
            marginBottom: 20
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div>
            <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 6, color: 'var(--text)' }}>
              Username
            </label>
            <input
              type="text"
              required
              autoFocus
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="e.g. admin or sales1"
              style={{
                width: '100%',
                padding: '10px 12px',
                fontSize: 14,
                border: '1px solid #d2d8e0',
                borderRadius: 6,
                outline: 'none',
                boxSizing: 'border-box'
              }}
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 6, color: 'var(--text)' }}>
              Password
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter password"
              style={{
                width: '100%',
                padding: '10px 12px',
                fontSize: 14,
                border: '1px solid #d2d8e0',
                borderRadius: 6,
                outline: 'none',
                boxSizing: 'border-box'
              }}
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            style={{
              marginTop: 8,
              background: submitting ? '#ccc' : 'var(--accent)',
              color: '#13202f',
              border: 'none',
              padding: '12px',
              fontSize: 14,
              fontWeight: 700,
              borderRadius: 6,
              cursor: submitting ? 'not-allowed' : 'pointer',
              transition: 'background 0.2s'
            }}
          >
            {submitting ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div style={{ marginTop: 24, paddingTop: 16, borderTop: '1px solid #eef1f5', fontSize: 12, color: 'var(--muted)', textAlign: 'center' }}>
          <div>Demo accounts:</div>
          <div style={{ marginTop: 4, fontFamily: 'monospace' }}>
            admin &bull; sales1 &bull; stock1
          </div>
        </div>
      </div>
    </div>
  )
}
