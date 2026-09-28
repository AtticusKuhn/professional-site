#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

host=root@209.141.42.170
url=https://atticusmkuhn.com

for command in npm tar ssh curl cmp; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Required command is missing: %s\n' "$command" >&2
    exit 1
  fi
done

if [[ ! -f index.html || ! -d assets ]]; then
  printf 'Expected index.html and assets/ beside deploy.sh.\n' >&2
  exit 1
fi

if [[ ! -x node_modules/.bin/tailwindcss ]]; then
  npm ci
fi
npm run build

printf 'Uploading site to %s (SSH may ask for your password)...\n' "$host"
tar -czf - index.html assets | ssh -o StrictHostKeyChecking=accept-new "$host" '
  set -eu
  live=/var/www/atticusmkuhn.com
  test -d "$live"
  systemctl is-active --quiet nginx
  nginx -t >/dev/null

  stage=$(mktemp -d /var/www/atticusmkuhn.com.stage.XXXXXX)
  backup=
  cleanup() {
    status=$?
    trap - EXIT
    if [ "$status" -ne 0 ] && [ -n "$backup" ] && [ -d "$backup" ] && [ ! -e "$live" ]; then
      mv -- "$backup" "$live"
    fi
    if [ -d "$stage" ]; then
      rm -rf -- "$stage"
    fi
    exit "$status"
  }
  trap cleanup EXIT

  tar -xzf - -C "$stage"
  test -f "$stage/index.html"
  test -f "$stage/assets/site.css"
  chown -R root:root "$stage"
  find "$stage" -type d -exec chmod 755 {} +
  find "$stage" -type f -exec chmod 644 {} +

  backup="${live}.backup.$(date -u +%Y%m%dT%H%M%SZ).$$"
  test ! -e "$backup"
  mv -- "$live" "$backup"
  mv -- "$stage" "$live"
  printf "Published. Previous version: %s\n" "$backup"
'

printf 'Checking public site...\n'
curl -4 -fsS --retry 3 --max-time 20 "$url/" | cmp - index.html
curl -4 -fsS --retry 3 --max-time 20 "$url/assets/site.css" | cmp - assets/site.css
printf 'Deployment verified at %s/\n' "$url"
