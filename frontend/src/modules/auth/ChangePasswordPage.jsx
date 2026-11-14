import { useState } from 'react'
import api from '../../api/client'

export default function ChangePasswordPage() {
  const [oldPassword, setOldPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setMessage('')
    setError('')

    if (newPassword.length < 8) {
      setError('New password must be at least 8 characters long')
      return
    }

    if (newPassword !== confirmPassword) {
      setError('New password and confirmation do not match')
      return
    }

    setLoading(true)
    try {
      await api.post('/auth/change-password', {
        oldPassword,
        newPassword
      })
      setMessage('Password changed successfully!')
      setOldPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (err) {
      setError(err.userMessage || 'Failed to change password')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ maxWidth: 440 }}>
      <h1>Change Password</h1>
      <p className="muted" style={{ marginBottom: 24 }}>
        Update your login password. Must be at least 8 characters.
      </p>

      {message && (
        <div style={{
          background: 'rgba(31, 138, 76, 0.1)',
          borderLeft: '4px solid var(--ok)',
          color: 'var(--ok)',
          padding: '10px 14px',
          borderRadius: 4,
          fontSize: 14,
          marginBottom: 20
        }}>
          {message}
        </div>
      )}

      {error && (
        <div style={{
          background: 'rgba(192, 57, 43, 0.08)',
          borderLeft: '4px solid var(--error)',
          color: 'var(--error)',
          padding: '10px 14px',
          borderRadius: 4,
          fontSize: 14,
          marginBottom: 20
        }}>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} style={{
        background: 'var(--panel)',
        padding: 24,
        borderRadius: 8,
        display: 'flex',
        flexDirection: 'column',
        gap: 16,
        boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
      }}>
        <div>
          <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>
            Current Password
          </label>
          <input
            type="password"
            required
            value={oldPassword}
            onChange={(e) => setOldPassword(e.target.value)}
            placeholder="Enter current password"
            style={{
              width: '100%',
              padding: '10px 12px',
              fontSize: 14,
              border: '1px solid #d2d8e0',
              borderRadius: 6,
              boxSizing: 'border-box'
            }}
          />
        </div>

        <div>
          <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>
            New Password (min 8 characters)
          </label>
          <input
            type="password"
            required
            minLength={8}
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            placeholder="Enter new password"
            style={{
              width: '100%',
              padding: '10px 12px',
              fontSize: 14,
              border: '1px solid #d2d8e0',
              borderRadius: 6,
              boxSizing: 'border-box'
            }}
          />
        </div>

        <div>
          <label style={{ display: 'block', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>
            Confirm New Password
          </label>
          <input
            type="password"
            required
            minLength={8}
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="Confirm new password"
            style={{
              width: '100%',
              padding: '10px 12px',
              fontSize: 14,
              border: '1px solid #d2d8e0',
              borderRadius: 6,
              boxSizing: 'border-box'
            }}
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          style={{
            marginTop: 8,
            background: loading ? '#ccc' : 'var(--accent)',
            color: '#13202f',
            border: 'none',
            padding: '11px',
            fontSize: 14,
            fontWeight: 700,
            borderRadius: 6,
            cursor: loading ? 'not-allowed' : 'pointer'
          }}
        >
          {loading ? 'Updating...' : 'Update Password'}
        </button>
      </form>
    </div>
  )
}
