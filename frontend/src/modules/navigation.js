// Sidebar entries. When you add a page for your part, add or update its entry here.
// roles: which roles see the link. Admin sees everything.
export const NAV_ITEMS = [
  { path: '/', label: 'Dashboard', part: 9, roles: ['ADMIN', 'SALES', 'STOCK'] },
  { path: '/customers', label: 'Customers', part: 6, roles: ['ADMIN', 'SALES'] },
  { path: '/sales', label: 'Sales', part: 7, roles: ['ADMIN', 'SALES'] },
  { path: '/invoices', label: 'Invoices & Documents', part: 8, roles: ['ADMIN', 'SALES'] },
  { path: '/products', label: 'Products', part: 3, roles: ['ADMIN', 'STOCK'] },
  { path: '/inventory', label: 'Inventory', part: 4, roles: ['ADMIN', 'STOCK'] },
  { path: '/purchases', label: 'Suppliers & Purchases', part: 5, roles: ['ADMIN', 'STOCK'] },
  { path: '/reports', label: 'Reports', part: 9, roles: ['ADMIN'] },
  { path: '/users', label: 'Users', part: 2, roles: ['ADMIN'] },
  { path: '/audit', label: 'Audit Log', part: 10, roles: ['ADMIN'] },
  { path: '/system', label: 'System Status', part: 1, roles: ['ADMIN'] },
]
