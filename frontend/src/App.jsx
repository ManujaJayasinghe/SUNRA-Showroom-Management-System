import { Route, Routes } from 'react-router-dom'
import AppLayout from './layout/AppLayout'
import PlaceholderPage from './components/PlaceholderPage'
import SystemStatusPage from './modules/system/SystemStatusPage'

// Each part replaces its PlaceholderPage with a component from src/modules/<module>/
export default function App() {
  return (
    <Routes>
      {/* Part 2: add <Route path="/login" element={<LoginPage />} /> here, outside the layout */}
      <Route element={<AppLayout />}>
        <Route index element={<PlaceholderPage title="Dashboard" part={9} todo={['Sales, stock and customer summaries', 'Recent transactions']} />} />
        <Route path="sales" element={<PlaceholderPage title="Sales" part={7} todo={['Point-of-sale screen', 'Calls sp_create_sale']} />} />
        <Route path="customers" element={<PlaceholderPage title="Customers" part={6} todo={['Customer list and search', 'Profile with purchase history']} />} />
        <Route path="products" element={<PlaceholderPage title="Products" part={3} todo={['Product list, search, add/edit']} />} />
        <Route path="inventory" element={<PlaceholderPage title="Inventory" part={4} todo={['Stock overview', 'Low-stock alerts', 'Movement history']} />} />
        <Route path="purchases" element={<PlaceholderPage title="Suppliers & Purchases" part={5} todo={['Supplier pages', 'Purchase entry form']} />} />
        <Route path="invoices" element={<PlaceholderPage title="Invoices & Documents" part={8} todo={['Invoice view and PDF download', 'Document search']} />} />
        <Route path="reports" element={<PlaceholderPage title="Reports" part={9} todo={['Daily/monthly sales', 'Stock report', 'Sales by model']} />} />
        <Route path="users" element={<PlaceholderPage title="Users" part={2} todo={['User management (admin only)']} />} />
        <Route path="audit" element={<PlaceholderPage title="Audit Log" part={10} todo={['Audit log viewer with filters']} />} />
        <Route path="system" element={<SystemStatusPage />} />
        <Route path="*" element={<PlaceholderPage title="Page not found" part={1} />} />
      </Route>
    </Routes>
  )
}
