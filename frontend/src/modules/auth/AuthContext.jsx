import { useState, useEffect } from 'react'
import api, { TOKEN_KEY, USER_KEY } from '../../api/client'
import { AuthContext } from './AuthContextDefinition'

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem(TOKEN_KEY))
  const [user, setUser] = useState(() => {
    try {
      const saved = localStorage.getItem(USER_KEY)
      return saved ? JSON.parse(saved) : null
    } catch {
      return null
    }
  })
  const [loading, setLoading] = useState(false)

  const role = user?.role || null
  const isAuthenticated = Boolean(token && user)

  const login = async (credentials) => {
    setLoading(true)
    try {
      const res = await api.post('/auth/login', credentials)
      const { token: receivedToken, user: receivedUser } = res.data

      localStorage.setItem(TOKEN_KEY, receivedToken)
      localStorage.setItem(USER_KEY, JSON.stringify(receivedUser))

      setToken(receivedToken)
      setUser(receivedUser)
      return receivedUser
    } finally {
      setLoading(false)
    }
  }

  const logout = () => {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
    setToken(null)
    setUser(null)
  }

  // Refreshes profile on initial mount if token exists
  useEffect(() => {
    if (token && !user) {
      api.get('/auth/me')
        .then((res) => {
          setUser(res.data)
          localStorage.setItem(USER_KEY, JSON.stringify(res.data))
        })
        .catch(() => logout())
    }
  }, [token, user])

  return (
    <AuthContext.Provider
      value={{
        token,
        user,
        role,
        isAuthenticated,
        loading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}
