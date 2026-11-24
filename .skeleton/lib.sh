# Helpers shared by install.sh and the add-ons.

# setenv FILE KEY VALUE: set KEY=VALUE (also replaces a commented-out KEY), or append it
setenv() {
  local file="$1" key="$2" value="$3"
  if grep -Eq "^#? ?${key}=" "$file"; then
    # | as the sed delimiter; the values used here never contain it
    sed -i "s|^#\? \?${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

# Set a variable in the files that document it and in the live one
setenv_all() {
  for f in .env .env.example; do setenv "$f" "$1" "$2"; done
}

# keep_block FILE NAME: drop only the marker lines of a block. drop_block FILE NAME: drop the block.
keep_block() { sed -i "/^ *# >>> $2\$/d;/^ *# <<< $2\$/d" "$1"; }
drop_block() { sed -i "/^ *# >>> $2\$/,/^ *# <<< $2\$/d" "$1"; }

# GitHub's download API answers 504 now and then; a retry is enough. Exported, so the add-on and
# stub scripts get it too.
composer() {
  local attempt
  for attempt in 1 2 3; do
    command composer "$@" && return 0
    echo "composer $1 failed (attempt $attempt of 3)" >&2
    sleep 5
  done
  return 1
}
export -f composer
