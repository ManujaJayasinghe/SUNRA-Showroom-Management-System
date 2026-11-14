import axios from 'axios'

// Every module calls the backend through this client, never with raw fetch/axios.
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8080/api',
  headers: { 'Content-Type': 'application/json' },
})

// Part 2 stores the JWT and user under these keys after login
export const TOKEN_KEY = 'sunra_token'
export const USER_KEY = 'sunra_user'

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY)
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Turns backend ApiError bodies into one readable message; redirects on 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    const data = err.response?.data
    err.userMessage = data?.message || err.message || 'Request failed'

    if (err.response?.status === 401) {
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USER_KEY)
      if (typeof window !== 'undefined' && !window.location.pathname.startsWith('/login')) {
        window.location.href = '/login'
      }
    }

    return Promise.reject(err)
  },
)

export default api
