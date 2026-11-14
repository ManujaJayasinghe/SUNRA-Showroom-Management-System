// Temporary page shown until the owning part builds the real screen.
export default function PlaceholderPage({ title, part, todo = [] }) {
  return (
    <section>
      <h1>{title}</h1>
      <p className="muted">Owned by Part {part}. Replace this page with the real screen.</p>
      {todo.length > 0 && (
        <ul>
          {todo.map((t) => (
            <li key={t}>{t}</li>
          ))}
        </ul>
      )}
    </section>
  )
}
