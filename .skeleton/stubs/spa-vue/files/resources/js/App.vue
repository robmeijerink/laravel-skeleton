<script setup lang="ts">
import { onMounted, ref } from 'vue';

const ok = ref<boolean | null>(null);

onMounted(async () => {
    const response = await fetch('/api/ping');
    ok.value = ((await response.json()) as { ok: boolean }).ok;
});
</script>

<template>
    <main class="p-8 font-sans">
        <h1 class="text-2xl font-semibold">Laravel + Vue SPA</h1>
        <p>API: {{ ok === null ? '...' : ok ? 'reachable' : 'down' }}</p>
    </main>
</template>
