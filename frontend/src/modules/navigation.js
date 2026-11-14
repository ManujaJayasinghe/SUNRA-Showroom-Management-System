// Sidebar entries. When you add a page for your part, add or update its entry here.
// roles: which roles see the link (Part 2 wires this to the logged-in user).
export const NAV_ITEMS = [
  { path: '/', label: 'Dashboard', part: 9, roles: ['ADMIN', 'SALES_ASSISTANT', 'STOCK_MANAGER'] },
  { path: '/sales', label: 'Sales', part: 7, roles: ['ADMIN', 'SALES_ASSISTANT'] },
  { path: '/customers', label: 'Customers', part: 6, roles: ['ADMIN', 'SALES_ASSISTANT'] },
  { path: '/products', label: 'Products', part: 3, roles: ['ADMIN', 'STOCK_MANAGER'] },
  { path: '/inventory', label: 'Inventory', part: 4, roles: ['ADMIN', 'STOCK_MANAGER'] },
  { path: '/purchases', label: 'Suppliers & Purchases', part: 5, roles: ['ADMIN', 'STOCK_MANAGER'] },
  { path: '/invoices', label: 'Invoices & Documents', part: 8, roles: ['ADMIN', 'SALES_ASSISTANT'] },
  { path: '/reports', label: 'Reports', part: 9, roles: ['ADMIN'] },
  { path: '/users', label: 'Users', part: 2, roles: ['ADMIN'] },
  { path: '/audit', label: 'Audit Log', part: 10, roles: ['ADMIN'] },
  { path: '/system', label: 'System Status', part: 1, roles: ['ADMIN'] },
]
