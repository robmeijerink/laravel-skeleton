import tailwindcss from '@tailwindcss/vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
    // Vite runs in a container: listen on all interfaces, the browser reaches HMR on localhost
    server: { host: '0.0.0.0', hmr: { host: 'localhost' } },
    plugins: [
        laravel({ input: ['resources/css/app.css', 'resources/js/app.tsx'], refresh: true }),
        react(),
        tailwindcss(),
    ],
});
