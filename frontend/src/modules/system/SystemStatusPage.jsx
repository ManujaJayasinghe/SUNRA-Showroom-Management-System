import { useEffect, useState } from 'react'
import api from '../../api/client'

// Part 1: proves React -> Spring Boot -> MySQL works end to end.
export default function SystemStatusPage() {
  const [health, setHealth] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    api
      .get('/health')
      .then((res) => setHealth(res.data))
      .catch((err) => setError(err.userMessage))
  }, [])

  return (
    <section>
      <h1>System Status</h1>
      {error && <p className="error">Backend not reachable: {error}</p>}
      {!health && !error && <p className="muted">Checking...</p>}
      {health && (
        <table className="table">
          <tbody>
            <tr><th>Status</th><td className={health.status === 'UP' ? 'ok' : 'error'}>{health.status}</td></tr>
            <tr><th>Database</th><td>{health.database}</td></tr>
            <tr><th>MySQL version</th><td>{health.mysqlVersion}</td></tr>
            <tr><th>Tables</th><td>{health.tables}</td></tr>
            <tr><th>Migrations applied</th><td>{health.migrations?.join(', ')}</td></tr>
            {health.error && <tr><th>Error</th><td className="error">{health.error}</td></tr>}
          </tbody>
        </table>
      )}
    </section>
  )
}
