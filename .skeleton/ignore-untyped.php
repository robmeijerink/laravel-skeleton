<?php

declare(strict_types=1);

// Reads the output of `pest --type-coverage` on stdin and appends `// @pest-ignore-type` to every line
// that Pest lists as untyped (e.g. `app/Foo.php .... pa30 75%` = a parameter on line 30). Used once by
// `task init` for code that came from the Laravel installer and that Pun's lint could not type, so the
// minimum can stay at 100 for everything written afterwards. Prints one line per marked location.

$marked = 0;

while (($line = fgets(STDIN)) !== false) {
    $line = (string) preg_replace('/\e\[[0-9;]*m/', '', $line);

    if (preg_match('~^\s*(\S+\.php)\s+\.+\s+(.*?)\s*\d+%~', $line, $match) !== 1) {
        continue;
    }

    preg_match_all('/\b[a-z]{2}(\d+)\b/', $match[2], $lines);

    $file = $match[1];
    $contents = is_file($file) ? file($file) : false;

    if ($contents === false) {
        continue;
    }

    foreach (array_unique($lines[1]) as $number) {
        $index = (int) $number - 1;

        if (! isset($contents[$index]) || str_contains($contents[$index], '@pest-ignore-type')) {
            continue;
        }

        $contents[$index] = rtrim($contents[$index], "\r\n").' // @pest-ignore-type'.PHP_EOL;
        $marked++;
        fwrite(STDERR, "  marked {$file}:{$number}\n");
    }

    file_put_contents($file, implode('', $contents));
}

echo $marked, PHP_EOL;
