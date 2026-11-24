<?php

declare(strict_types=1);

// Reads a Clover coverage report (argv[1]) and excludes every statement the tests do not reach, using
// PHPUnit's own markers: a single line gets `// @codeCoverageIgnore`, consecutive lines are wrapped in
// one `// @codeCoverageIgnoreStart` / `// @codeCoverageIgnoreEnd` pair. Used once by `task init` for
// code that came from the Laravel installer, so the coverage minimum can be 100 for everything written
// afterwards. A file that no longer passes `php -l` after marking (a statement inside a heredoc, say)
// is restored and left for the fallback. Prints one line per marked file.

$report = $argv[1] ?? '';
$xml = is_file($report) ? simplexml_load_file($report) : false;

if ($xml === false) {
    fwrite(STDERR, "No coverage report at '{$report}'\n");
    exit(1);
}

$base = getcwd().'/';

foreach ($xml->xpath('//file') ?: [] as $fileNode) {
    $file = (string) $fileNode['name'];
    $uncovered = [];

    foreach ($fileNode->line as $line) {
        if ((string) $line['type'] === 'stmt' && (int) $line['count'] === 0) {
            $uncovered[] = (int) $line['num'];
        }
    }

    if ($uncovered === [] || ! is_file($file)) {
        continue;
    }

    sort($uncovered);
    $uncovered = array_values(array_unique($uncovered));

    // Consecutive line numbers form one block
    $blocks = [];
    foreach ($uncovered as $number) {
        $last = count($blocks) - 1;
        if ($last >= 0 && $blocks[$last][1] === $number - 1) {
            $blocks[$last][1] = $number;
        } else {
            $blocks[] = [$number, $number];
        }
    }

    $original = (string) file_get_contents($file);
    $lines = explode("\n", $original);

    // Bottom to top, so inserted lines don't shift the numbers still to come
    foreach (array_reverse($blocks) as [$first, $end]) {
        if (! isset($lines[$first - 1], $lines[$end - 1]) || str_contains($lines[$first - 1], '@codeCoverageIgnore')) {
            continue;
        }

        if ($first === $end) {
            $lines[$first - 1] = rtrim($lines[$first - 1]).' // @codeCoverageIgnore';

            continue;
        }

        preg_match('/^\s*/', $lines[$first - 1], $indent);
        array_splice($lines, $end, 0, [$indent[0].'// @codeCoverageIgnoreEnd']);
        array_splice($lines, $first - 1, 0, [$indent[0].'// @codeCoverageIgnoreStart']);
    }

    file_put_contents($file, implode("\n", $lines));
    exec('php -l '.escapeshellarg($file).' 2>&1', $output, $status);

    if ($status !== 0) {
        file_put_contents($file, $original);
        fwrite(STDERR, '  skipped '.str_replace($base, '', $file)." (marking would break it)\n");

        continue;
    }

    fwrite(STDERR, '  marked '.count($uncovered).' line(s) in '.count($blocks).' place(s) in '.str_replace($base, '', $file)."\n");
}
