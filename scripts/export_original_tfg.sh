#!/usr/bin/env bash
# Local-only collector for original June 2026 TFG source files.
# Never sends data to GitHub or any external endpoint.
set -Eeuo pipefail
umask 077

if [[ $# -ne 1 ]]; then
  echo "Usage: bash scripts/export_original_tfg.sh lb|node1|node2" >&2
  exit 2
fi
role="$1"
case "$role" in
  lb|node1|node2) ;;
  *) echo "Choose lb, node1 or node2" >&2; exit 2 ;;
esac

command -v tar >/dev/null || { echo "tar not installed" >&2; exit 1; }
echo "Checking sudo access to read original system configuration..."
sudo -v

staging="$(mktemp -d "$HOME/tfg-private-$role-XXXXXXXX")"
chmod 700 "$staging"
printf 'Role: %s\nHostname: %s\n' "$role" "$(hostname)" > "$staging/manifest.txt"

copy_original() {
  local source="$1" target
  [[ -f "$source" ]] || return 0
  target="$staging/system$source"
  mkdir -p "$(dirname "$target")"
  if sudo cat -- "$source" > "$target"; then
    chmod 600 "$target"
    echo "COPIED $source"
  else
    rm -f -- "$target"
    echo "Could not read: $source" >&2
  fi
}

for file in /etc/netplan/*.yaml /etc/netplan/*.yml; do
  [[ -f "$file" ]] && copy_original "$file"
done

if [[ "$role" == lb ]]; then
  copy_original /etc/haproxy/haproxy.cfg
else
  copy_original /etc/nginx/nginx.conf
  for file in /etc/nginx/sites-available/* /etc/nginx/conf.d/*.conf; do
    [[ -f "$file" ]] && copy_original "$file"
  done
fi

{
  echo "=== Services ==="
  systemctl is-active haproxy nginx docker 2>&1 || true
  echo "=== Docker containers ==="
  docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>&1 || true
  echo "=== Docker Compose ==="
  docker compose ls 2>&1 || true
} > "$staging/services.txt"

# Crontabs could contain passwords: KEEP THIS ARCHIVE PRIVATE.
{
  echo "=== Current user cron ==="
  crontab -l 2>&1 || true
  echo "=== Root cron ==="
  sudo crontab -l 2>&1 || true
} > "$staging/cron-private-review.txt"

# Only locate (do not copy) possible original Compose, monitoring and Bash files.
find "$HOME" -maxdepth 6 \
  \( -name .ssh -o -name .cache -o -name .git -o -name .local -o -name node_modules -o -name 'tfg-private-*' \) -prune -o \
  -type f \( -iname 'docker-compose.yml' -o -iname 'docker-compose.yaml' -o -iname 'compose.yml' \
    -o -iname 'compose.yaml' -o -iname 'prometheus.yml' -o -iname 'prometheus.yaml' \
    -o -name '*.sh' \) -print \
  > "$staging/candidates.txt" 2>/dev/null || true

archive="$staging.tar.gz"
tar -czf "$archive" -C "$staging" .
chmod 600 "$archive"
printf '\nExport saved locally: %s\n' "$archive"
echo "PRIVATE EXPORT. DO NOT UPLOAD TO PUBLIC GITHUB."
echo "Review/redact passwords, tokens and private information before sharing."
echo "Compose/Prometheus/Bash source has NOT been copied: check candidates.txt."
