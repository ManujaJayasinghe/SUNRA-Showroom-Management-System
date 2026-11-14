import { useState, useEffect, useCallback } from 'react'
import api from '../../api/client'
import { useAuth } from '../auth/useAuth'

export default function UserManagementPage() {
  const { user: currentUser } = useAuth()

  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  // Filters
  const [searchTerm, setSearchTerm] = useState('')
  const [roleFilter, setRoleFilter] = useState('')

  // Modals state
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [editingUser, setEditingUser] = useState(null)
  const [roleChangingUser, setRoleChangingUser] = useState(null)
  const [statusConfirmUser, setStatusConfirmUser] = useState(null)
  const [resetPwdUser, setResetPwdUser] = useState(null)

  // Form states
  const [createForm, setCreateForm] = useState({
    username: '',
    fullName: '',
    email: '',
    phone: '',
    role: 'SALES',
    password: ''
  })

  const [editForm, setEditForm] = useState({
    fullName: '',
    email: '',
    phone: ''
  })

  const [selectedRole, setSelectedRole] = useState('SALES')
  const [newPassword, setNewPassword] = useState('')

  const fetchUsers = useCallback(async () => {
    try {
      const params = {}
      if (searchTerm.trim()) params.search = searchTerm.trim()
      if (roleFilter) params.role = roleFilter

      const res = await api.get('/users', { params })
      setUsers(res.data)
      setError('')
    } catch (err) {
      setError(err.userMessage || 'Failed to load users')
    } finally {
      setLoading(false)
    }
  }, [searchTerm, roleFilter])

  useEffect(() => {
    let ignore = false
    const params = {}
    if (searchTerm.trim()) params.search = searchTerm.trim()
    if (roleFilter) params.role = roleFilter

    api.get('/users', { params })
      .then((res) => {
        if (!ignore) {
          setUsers(res.data)
          setError('')
        }
      })
      .catch((err) => {
        if (!ignore) {
          setError(err.userMessage || 'Failed to load users')
        }
      })
      .finally(() => {
        if (!ignore) {
          setLoading(false)
        }
      })

    return () => {
      ignore = true
    }
  }, [searchTerm, roleFilter])

  const showSuccessMsg = (msg) => {
    setSuccess(msg)
    setTimeout(() => setSuccess(''), 4000)
  }

  // --- Handlers ---

  const handleCreateSubmit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await api.post('/users', createForm)
      setIsCreateOpen(false)
      setCreateForm({
        username: '',
        fullName: '',
        email: '',
        phone: '',
        role: 'SALES',
        password: ''
      })
      showSuccessMsg(`User '${createForm.username}' created successfully!`)
      fetchUsers()
    } catch (err) {
      setError(err.userMessage || 'Failed to create user')
    }
  }

  const handleEditSubmit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await api.put(`/users/${editingUser.id}`, editForm)
      setEditingUser(null)
      showSuccessMsg(`User '${editingUser.username}' updated successfully!`)
      fetchUsers()
    } catch (err) {
      setError(err.userMessage || 'Failed to update user')
    }
  }

  const handleRoleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    try {
      await api.put(`/users/${roleChangingUser.id}/role`, { role: selectedRole })
      setRoleChangingUser(null)
      showSuccessMsg(`Role for '${roleChangingUser.username}' changed to ${selectedRole}!`)
      fetchUsers()
    } catch (err) {
      setError(err.userMessage || 'Failed to change role')
    }
  }

  const handleStatusConfirm = async () => {
    setError('')
    try {
      const newStatus = !statusConfirmUser.isActive
      await api.patch(`/users/${statusConfirmUser.id}/status`, { isActive: newStatus })
      setStatusConfirmUser(null)
      showSuccessMsg(`User '${statusConfirmUser.username}' ${newStatus ? 'activated' : 'deactivated'}!`)
      fetchUsers()
    } catch (err) {
      setError(err.userMessage || 'Failed to update user status')
    }
  }

  const handleResetPasswordSubmit = async (e) => {
    e.preventDefault()
    setError('')
    if (newPassword.length < 8) {
      setError('Password must be at least 8 characters long')
      return
    }
    try {
      await api.post(`/users/${resetPwdUser.id}/reset-password`, { newPassword })
      setResetPwdUser(null)
      setNewPassword('')
      showSuccessMsg(`Password for '${resetPwdUser.username}' has been reset successfully!`)
    } catch (err) {
      setError(err.userMessage || 'Failed to reset password')
    }
  }

  const isSelf = (user) => {
    if (!currentUser) return false
    return currentUser.id === user.id || currentUser.username === user.username
  }

  return (
    <div style={{ maxWidth: 1100, margin: '0 auto' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <h1 style={{ margin: 0, fontSize: 26, fontWeight: 700 }}>User Management</h1>
          <p className="muted" style={{ margin: '4px 0 0', fontSize: 14 }}>
            Create and manage showroom staff accounts, roles, and status
          </p>
        </div>
        <button
          onClick={() => { setError(''); setIsCreateOpen(true) }}
          style={{
            background: 'var(--accent)',
            color: '#13202f',
            border: 'none',
            borderRadius: 6,
            padding: '10px 18px',
            fontSize: 14,
            fontWeight: 700,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: 6
          }}
        >
          <span>+</span> Create New User
        </button>
      </div>

      {/* Messages */}
      {success && (
        <div style={{
          background: 'rgba(31, 138, 76, 0.1)',
          borderLeft: '4px solid var(--ok)',
          color: 'var(--ok)',
          padding: '12px 16px',
          borderRadius: 4,
          fontSize: 14,
          marginBottom: 16,
          fontWeight: 500
        }}>
          {success}
        </div>
      )}

      {error && (
        <div style={{
          background: 'rgba(192, 57, 43, 0.08)',
          borderLeft: '4px solid var(--error)',
          color: 'var(--error)',
          padding: '12px 16px',
          borderRadius: 4,
          fontSize: 14,
          marginBottom: 16
        }}>
          {error}
        </div>
      )}

      {/* Filter / Search Bar */}
      <div style={{
        background: 'var(--panel)',
        padding: '14px 18px',
        borderRadius: 8,
        display: 'flex',
        gap: 12,
        alignItems: 'center',
        marginBottom: 20,
        boxShadow: '0 1px 3px rgba(0,0,0,0.05)'
      }}>
        <div style={{ flex: 1 }}>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by username, full name, or email..."
            style={{
              width: '100%',
              padding: '9px 12px',
              fontSize: 14,
              border: '1px solid #d2d8e0',
              borderRadius: 6,
              boxSizing: 'border-box'
            }}
          />
        </div>

        <div>
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            style={{
              padding: '9px 12px',
              fontSize: 14,
              border: '1px solid #d2d8e0',
              borderRadius: 6,
              background: '#fff'
            }}
          >
            <option value="">All Roles</option>
            <option value="ADMIN">ADMIN</option>
            <option value="SALES">SALES</option>
            <option value="STOCK">STOCK</option>
          </select>
        </div>

        {(searchTerm || roleFilter) && (
          <button
            onClick={() => { setSearchTerm(''); setRoleFilter('') }}
            style={{
              background: '#f1f3f5',
              border: '1px solid #d2d8e0',
              padding: '8px 12px',
              borderRadius: 6,
              fontSize: 13,
              cursor: 'pointer'
            }}
          >
            Clear Filters
          </button>
        )}
      </div>

      {/* Users Table */}
      <div style={{
        background: 'var(--panel)',
        borderRadius: 8,
        overflow: 'hidden',
        boxShadow: '0 1px 4px rgba(0,0,0,0.06)'
      }}>
        <table className="table" style={{ width: '100%', minWidth: 800 }}>
          <thead>
            <tr style={{ background: '#f8fafc', borderBottom: '1px solid #e3e7ec' }}>
              <th style={{ width: 60, padding: '12px 14px' }}>ID</th>
              <th style={{ width: 140 }}>Username</th>
              <th>Full Name</th>
              <th>Email / Phone</th>
              <th style={{ width: 120 }}>Role</th>
              <th style={{ width: 100 }}>Status</th>
              <th style={{ width: 220, textAlign: 'right', paddingRight: 18 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '32px 0', color: 'var(--muted)' }}>
                  Loading users...
                </td>
              </tr>
            ) : users.length === 0 ? (
              <tr>
                <td colSpan="7" style={{ textAlign: 'center', padding: '32px 0', color: 'var(--muted)' }}>
                  No users found matching your filters.
                </td>
              </tr>
            ) : (
              users.map((u) => {
                const self = isSelf(u)
                return (
                  <tr key={u.id} style={{ borderBottom: '1px solid #eef1f5' }}>
                    <td style={{ fontWeight: 600, color: 'var(--muted)' }}>{u.id}</td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{u.username}</div>
                      {self && (
                        <span style={{ fontSize: 11, color: 'var(--accent)', fontWeight: 600 }}>
                          (You)
                        </span>
                      )}
                    </td>
                    <td>{u.fullName}</td>
                    <td>
                      <div>{u.email}</div>
                      {u.phone && <div className="muted" style={{ fontSize: 12 }}>{u.phone}</div>}
                    </td>
                    <td>
                      <span style={{
                        display: 'inline-block',
                        padding: '3px 8px',
                        borderRadius: 12,
                        fontSize: 12,
                        fontWeight: 700,
                        background: u.role === 'ADMIN' ? '#eef2ff' : u.role === 'SALES' ? '#f0fdf4' : '#fefce8',
                        color: u.role === 'ADMIN' ? '#3730a3' : u.role === 'SALES' ? '#166534' : '#854d0e',
                        border: '1px solid rgba(0,0,0,0.06)'
                      }}>
                        {u.role}
                      </span>
                    </td>
                    <td>
                      <span style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: 6,
                        fontSize: 13,
                        fontWeight: 600,
                        color: u.isActive ? 'var(--ok)' : 'var(--muted)'
                      }}>
                        <span style={{
                          width: 8,
                          height: 8,
                          borderRadius: '50%',
                          background: u.isActive ? 'var(--ok)' : '#94a3b8'
                        }} />
                        {u.isActive ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right', paddingRight: 18 }}>
                      <div style={{ display: 'inline-flex', gap: 6 }}>
                        {/* Edit Button */}
                        <button
                          onClick={() => {
                            setEditingUser(u)
                            setEditForm({ fullName: u.fullName, email: u.email, phone: u.phone || '' })
                          }}
                          style={btnStyle}
                          title="Edit details"
                        >
                          Edit
                        </button>

                        {/* Change Role Button */}
                        <button
                          disabled={self}
                          onClick={() => {
                            setRoleChangingUser(u)
                            setSelectedRole(u.role)
                          }}
                          style={{
                            ...btnStyle,
                            opacity: self ? 0.4 : 1,
                            cursor: self ? 'not-allowed' : 'pointer'
                          }}
                          title={self ? 'Cannot change your own role' : 'Change role'}
                        >
                          Role
                        </button>

                        {/* Status Toggle Button */}
                        <button
                          disabled={self}
                          onClick={() => setStatusConfirmUser(u)}
                          style={{
                            ...btnStyle,
                            color: u.isActive ? 'var(--error)' : 'var(--ok)',
                            opacity: self ? 0.4 : 1,
                            cursor: self ? 'not-allowed' : 'pointer'
                          }}
                          title={self ? 'Cannot deactivate your own account' : u.isActive ? 'Deactivate' : 'Activate'}
                        >
                          {u.isActive ? 'Disable' : 'Enable'}
                        </button>

                        {/* Reset Password Button */}
                        <button
                          onClick={() => {
                            setResetPwdUser(u)
                            setNewPassword('')
                          }}
                          style={{ ...btnStyle, borderColor: '#cbd5e1' }}
                          title="Set new password"
                        >
                          Reset Pwd
                        </button>
                      </div>
                    </td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>

      {/* --- CREATE USER MODAL --- */}
      {isCreateOpen && (
        <Modal title="Create New User" onClose={() => setIsCreateOpen(false)}>
          <form onSubmit={handleCreateSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <label style={labelStyle}>Username (min 4 chars)</label>
              <input
                type="text"
                required
                minLength={4}
                value={createForm.username}
                onChange={(e) => setCreateForm({ ...createForm, username: e.target.value })}
                placeholder="e.g. sales2"
                style={inputStyle}
              />
            </div>
            <div>
              <label style={labelStyle}>Full Name</label>
              <input
                type="text"
                required
                value={createForm.fullName}
                onChange={(e) => setCreateForm({ ...createForm, fullName: e.target.value })}
                placeholder="e.g. Kasun Perera"
                style={inputStyle}
              />
            </div>
            <div>
              <label style={labelStyle}>Email Address</label>
              <input
                type="email"
                required
                value={createForm.email}
                onChange={(e) => setCreateForm({ ...createForm, email: e.target.value })}
                placeholder="e.g. kasun@sunra-showroom.local"
                style={inputStyle}
              />
            </div>
            <div>
              <label style={labelStyle}>Phone (optional)</label>
              <input
                type="text"
                value={createForm.phone}
                onChange={(e) => setCreateForm({ ...createForm, phone: e.target.value })}
                placeholder="e.g. 0771234567"
                style={inputStyle}
              />
            </div>
            <div>
              <label style={labelStyle}>Role</label>
              <select
                value={createForm.role}
                onChange={(e) => setCreateForm({ ...createForm, role: e.target.value })}
                style={inputStyle}
              >
                <option value="ADMIN">ADMIN</option>
                <option value="SALES">SALES</option>
                <option value="STOCK">STOCK</option>
              </select>
            </div>
            <div>
              <label style={labelStyle}>Initial Password (min 8 chars)</label>
              <input
                type="password"
                required
                minLength={8}
                value={createForm.password}
                onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
                placeholder="At least 8 characters"
                style={inputStyle}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 12 }}>
              <button type="button" onClick={() => setIsCreateOpen(false)} style={cancelBtnStyle}>
                Cancel
              </button>
              <button type="submit" style={submitBtnStyle}>
                Create User
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* --- EDIT USER MODAL --- */}
      {editingUser && (
        <Modal title={`Edit User: ${editingUser.username}`} onClose={() => setEditingUser(null)}>
          <form onSubmit={handleEditSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div>
              <label style={labelStyle}>Full Name</label>
              <input
                type="text"
                required
                value={editForm.fullName}
                onChange={(e) => setEditForm({ ...editForm, fullName: e.target.value })}
                style={inputStyle}
              />
            </div>
            <div>
              <label style={labelStyle}>Email Address</label>
              <input
                type="email"
                required
                value={editForm.email}
                onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                style={inputStyle}
              />
            </div>
            <div>
              <label style={labelStyle}>Phone</label>
              <input
                type="text"
                value={editForm.phone}
                onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                style={inputStyle}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 12 }}>
              <button type="button" onClick={() => setEditingUser(null)} style={cancelBtnStyle}>
                Cancel
              </button>
              <button type="submit" style={submitBtnStyle}>
                Save Changes
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* --- CHANGE ROLE MODAL --- */}
      {roleChangingUser && (
        <Modal title={`Change Role: ${roleChangingUser.username}`} onClose={() => setRoleChangingUser(null)}>
          <form onSubmit={handleRoleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <p className="muted" style={{ margin: 0, fontSize: 14 }}>
              Current role: <strong>{roleChangingUser.role}</strong>
            </p>
            <div>
              <label style={labelStyle}>New Role</label>
              <select
                value={selectedRole}
                onChange={(e) => setSelectedRole(e.target.value)}
                style={inputStyle}
              >
                <option value="ADMIN">ADMIN</option>
                <option value="SALES">SALES</option>
                <option value="STOCK">STOCK</option>
              </select>
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 12 }}>
              <button type="button" onClick={() => setRoleChangingUser(null)} style={cancelBtnStyle}>
                Cancel
              </button>
              <button type="submit" style={submitBtnStyle}>
                Update Role
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* --- STATUS TOGGLE CONFIRM MODAL --- */}
      {statusConfirmUser && (
        <Modal
          title={statusConfirmUser.isActive ? 'Deactivate User Account' : 'Activate User Account'}
          onClose={() => setStatusConfirmUser(null)}
        >
          <div style={{ fontSize: 14, lineHeight: 1.5, marginBottom: 20 }}>
            {statusConfirmUser.isActive ? (
              <p>
                Are you sure you want to deactivate <strong>{statusConfirmUser.username}</strong> ({statusConfirmUser.fullName})?
                The user will be blocked from logging into the showroom system.
              </p>
            ) : (
              <p>
                Activate user account for <strong>{statusConfirmUser.username}</strong>?
                They will regain login access.
              </p>
            )}
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
            <button type="button" onClick={() => setStatusConfirmUser(null)} style={cancelBtnStyle}>
              Cancel
            </button>
            <button
              type="button"
              onClick={handleStatusConfirm}
              style={{
                ...submitBtnStyle,
                background: statusConfirmUser.isActive ? 'var(--error)' : 'var(--ok)',
                color: '#fff'
              }}
            >
              {statusConfirmUser.isActive ? 'Yes, Deactivate' : 'Yes, Activate'}
            </button>
          </div>
        </Modal>
      )}

      {/* --- RESET PASSWORD MODAL --- */}
      {resetPwdUser && (
        <Modal title={`Reset Password: ${resetPwdUser.username}`} onClose={() => setResetPwdUser(null)}>
          <form onSubmit={handleResetPasswordSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <p className="muted" style={{ margin: 0, fontSize: 14 }}>
              Set a temporary or replacement password for this user (min 8 characters).
            </p>
            <div>
              <label style={labelStyle}>New Password</label>
              <input
                type="password"
                required
                minLength={8}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="At least 8 characters"
                style={inputStyle}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 12 }}>
              <button type="button" onClick={() => setResetPwdUser(null)} style={cancelBtnStyle}>
                Cancel
              </button>
              <button type="submit" style={submitBtnStyle}>
                Reset Password
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}

function Modal({ title, children, onClose }) {
  return (
    <div style={{
      position: 'fixed',
      inset: 0,
      background: 'rgba(19, 32, 47, 0.45)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1000,
      padding: 16
    }}>
      <div style={{
        background: '#fff',
        borderRadius: 8,
        width: '100%',
        maxWidth: 480,
        padding: 24,
        boxShadow: '0 8px 30px rgba(0,0,0,0.15)'
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
          <h2 style={{ margin: 0, fontSize: 18, fontWeight: 700 }}>{title}</h2>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              fontSize: 20,
              cursor: 'pointer',
              color: 'var(--muted)',
              padding: '0 4px'
            }}
          >
            &times;
          </button>
        </div>
        {children}
      </div>
    </div>
  )
}

const labelStyle = {
  display: 'block',
  fontSize: 13,
  fontWeight: 600,
  marginBottom: 5
}

const inputStyle = {
  width: '100%',
  padding: '9px 12px',
  fontSize: 14,
  border: '1px solid #d2d8e0',
  borderRadius: 6,
  boxSizing: 'border-box'
}

const btnStyle = {
  background: '#fff',
  border: '1px solid #d2d8e0',
  borderRadius: 4,
  padding: '4px 8px',
  fontSize: 12,
  fontWeight: 600,
  cursor: 'pointer'
}

const cancelBtnStyle = {
  background: '#f1f5f9',
  border: '1px solid #cbd5e1',
  borderRadius: 6,
  padding: '8px 16px',
  fontSize: 13,
  fontWeight: 600,
  cursor: 'pointer'
}

const submitBtnStyle = {
  background: 'var(--accent)',
  color: '#13202f',
  border: 'none',
  borderRadius: 6,
  padding: '8px 16px',
  fontSize: 13,
  fontWeight: 700,
  cursor: 'pointer'
}
