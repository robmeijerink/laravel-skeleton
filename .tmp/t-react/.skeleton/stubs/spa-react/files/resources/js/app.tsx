import { StrictMode, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';

function App() {
    const [ok, setOk] = useState<boolean | null>(null);

    useEffect(() => {
        fetch('/api/ping')
            .then((response) => response.json())
            .then((data: { ok: boolean }) => setOk(data.ok));
    }, []);

    return (
        <main className="p-8 font-sans">
            <h1 className="text-2xl font-semibold">Laravel + React SPA</h1>
            <p>API: {ok === null ? '...' : ok ? 'reachable' : 'down'}</p>
        </main>
    );
}

createRoot(document.getElementById('app')!).render(
    <StrictMode>
        <App />
    </StrictMode>,
);
