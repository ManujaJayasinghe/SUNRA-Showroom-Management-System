import { Route, Routes } from 'react-router-dom'
import AppLayout from './layout/AppLayout'
import PlaceholderPage from './components/PlaceholderPage'
import SystemStatusPage from './modules/system/SystemStatusPage'
import LoginPage from './modules/auth/LoginPage'
import ChangePasswordPage from './modules/auth/ChangePasswordPage'
import UserManagementPage from './modules/users/UserManagementPage'
import ProtectedRoute from './modules/auth/ProtectedRoute'
import { AuthProvider } from './modules/auth/AuthContext'

// Each part replaces its PlaceholderPage with a component from src/modules/<module>/
export default function App() {
  return (
    <AuthProvider>
      <Routes>
        {/* Public login page */}
        <Route path="/login" element={<LoginPage />} />

        {/* Protected application shell */}
        <Route
          element={
            <ProtectedRoute>
              <AppLayout />
            </ProtectedRoute>
          }
        >
          {/* General access for all authenticated roles */}
          <Route index element={<PlaceholderPage title="Dashboard" part={9} todo={['Sales, stock and customer summaries', 'Recent transactions']} />} />
          <Route path="change-password" element={<ChangePasswordPage />} />

          {/* Sales & Admin accessible routes */}
          <Route
            path="sales"
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SALES']}>
                <PlaceholderPage title="Sales" part={7} todo={['Point-of-sale screen', 'Calls sp_create_sale']} />
              </ProtectedRoute>
            }
          />
          <Route
            path="customers"
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SALES']}>
                <PlaceholderPage title="Customers" part={6} todo={['Customer list and search', 'Profile with purchase history']} />
              </ProtectedRoute>
            }
          />
          <Route
            path="invoices"
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'SALES']}>
                <PlaceholderPage title="Invoices & Documents" part={8} todo={['Invoice view and PDF download', 'Document search']} />
              </ProtectedRoute>
            }
          />

          {/* Stock & Admin accessible routes */}
          <Route
            path="products"
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'STOCK']}>
                <PlaceholderPage title="Products" part={3} todo={['Product list, search, add/edit']} />
              </ProtectedRoute>
            }
          />
          <Route
            path="inventory"
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'STOCK']}>
                <PlaceholderPage title="Inventory" part={4} todo={['Stock overview', 'Low-stock alerts', 'Movement history']} />
              </ProtectedRoute>
            }
          />
          <Route
            path="purchases"
            element={
              <ProtectedRoute allowedRoles={['ADMIN', 'STOCK']}>
                <PlaceholderPage title="Suppliers & Purchases" part={5} todo={['Supplier pages', 'Purchase entry form']} />
              </ProtectedRoute>
            }
          />

          {/* Admin only routes */}
          <Route
            path="reports"
            element={
              <ProtectedRoute allowedRoles={['ADMIN']}>
                <PlaceholderPage title="Reports" part={9} todo={['Daily/monthly sales', 'Stock report', 'Sales by model']} />
              </ProtectedRoute>
            }
          />
          <Route
            path="users"
            element={
              <ProtectedRoute allowedRoles={['ADMIN']}>
                <UserManagementPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="audit"
            element={
              <ProtectedRoute allowedRoles={['ADMIN']}>
                <PlaceholderPage title="Audit Log" part={10} todo={['Audit log viewer with filters']} />
              </ProtectedRoute>
            }
          />
          <Route
            path="system"
            element={
              <ProtectedRoute allowedRoles={['ADMIN']}>
                <SystemStatusPage />
              </ProtectedRoute>
            }
          />

          <Route path="*" element={<PlaceholderPage title="Page not found" part={1} />} />
        </Route>
      </Routes>
    </AuthProvider>
  )
}
