<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

// The SPA owns every URL except /api. Move API routes to routes/api.php (`artisan install:api`) when you need auth.
Route::get('/api/ping', fn (): array => ['ok' => true]);
Route::view('/{any?}', 'app')->where('any', '^(?!api).*$');
