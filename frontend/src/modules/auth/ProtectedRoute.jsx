import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from './useAuth'
import NotAuthorizedPage from './NotAuthorizedPage'

export default function ProtectedRoute({ allowedRoles, children }) {
  const { isAuthenticated, role } = useAuth()
  const location = useLocation()

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  if (allowedRoles && allowedRoles.length > 0) {
    const isAuthorized = allowedRoles.some((allowed) => {
      if (allowed === role) return true
      if (allowed === 'SALES' && (role === 'SALES_ASSISTANT' || role === 'SALES')) return true
      if (allowed === 'SALES_ASSISTANT' && (role === 'SALES' || role === 'SALES_ASSISTANT')) return true
      if (allowed === 'STOCK' && (role === 'STOCK_MANAGER' || role === 'STOCK')) return true
      if (allowed === 'STOCK_MANAGER' && (role === 'STOCK' || role === 'STOCK_MANAGER')) return true
      return false
    })

    if (!isAuthorized) {
      return <NotAuthorizedPage />
    }
  }

  return children ? children : <Outlet />
}
