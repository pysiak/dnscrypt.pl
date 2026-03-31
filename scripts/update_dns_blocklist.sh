#!/bin/bash
#
# update_blocklists.sh — Download, merge, and deploy DNS blocklists
# for dnscrypt.pl (Guardian & Armada profiles)
#
# Usage:  ./update_blocklists.sh [-v|--verbose] [-d|--dry-run]
# Cron:   0 4 * * * /opt/dnscrypt/update_blocklists.sh >> /var/log/blocklist-update.log 2>&1
#
set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────
BLOCKFILE_GUARDIAN="/etc/guardian.txt"
BLOCKFILE_ARMADA="/etc/armada.txt"
UNDELEGATED="/etc/undelegated.txt"
WHITELIST="/etc/unbound/whitelist.conf"
MANUALBLOCKS="/etc/unbound/manualblocks.conf"
WEBROOT="/var/www"
TMPDIR="$(mktemp -d /tmp/blocklists.XXXXXX)"

VERBOSE=false
DRY_RUN=false

# ── Colors & logging ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { printf "${CYAN}[%s]${RESET} %s\n" "$(date '+%H:%M:%S')" "$*"; }
ok()   { printf "${GREEN}[%s] ✓${RESET} %s\n" "$(date '+%H:%M:%S')" "$*"; }
warn() { printf "${YELLOW}[%s] ⚠${RESET} %s\n" "$(date '+%H:%M:%S')" "$*" >&2; }
err()  { printf "${RED}[%s] ✗${RESET} %s\n" "$(date '+%H:%M:%S')" "$*" >&2; }
step() { printf "\n${BOLD}── %s ──${RESET}\n" "$1"; }

# ── Argument parsing ────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=true ;;
        -d|--dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [-v|--verbose] [-d|--dry-run] [-h|--help]"
            exit 0
            ;;
    esac
done

$VERBOSE && set -x

# ── Cleanup trap ────────────────────────────────────────────────────
cleanup() {
    rm -rf "$TMPDIR"
    log "Temp directory cleaned up"
}
trap cleanup EXIT

# ── Helpers ─────────────────────────────────────────────────────────
# Download a URL to a file. Returns 0 on success, 1 on failure (non-fatal).
fetch() {
    local url="$1" dest="$2" label="${3:-}"
    [[ -n "$label" ]] && log "Downloading: $label"
    if wget -q --timeout=30 --tries=2 -O "$dest" "$url"; then
        ok "$(basename "$dest")  ($(wc -l < "$dest") lines)"
        return 0
    else
        warn "Failed to download: $url"
        touch "$dest"   # ensure file exists so merges don't break
        return 1
    fi
}

# Strip comment lines and blank lines from a file
strip_comments() {
    grep -vE '^\s*(#|$)' "$1" 2>/dev/null || true
}

count() {
    wc -l < "$1" | tr -d ' '
}

# ── Source definitions ──────────────────────────────────────────────
# Each source: URL  LOCAL_FILE  LABEL
#
# Sources are split into two tiers:
#   GUARDIAN — core security lists (malware, phishing, spyware)
#   ARMADA   — guardian + extended coverage (ad domains, extra phishing)

GUARDIAN_SOURCES=(
    "https://hole.cert.pl/domains/domains.txt"
    "$TMPDIR/cert.txt"
    "CERT.PL (Polish CSIRT)"

    "https://phishing.army/download/phishing_army_blocklist_extended.txt"
    "$TMPDIR/phishingarmy.txt"
    "Phishing Army (extended)"

    "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
    "$TMPDIR/notrack.txt"
    "NoTrack malware"

    "https://raw.githubusercontent.com/olbat/ut1-blacklists/master/blacklists/malware/domains"
    "$TMPDIR/malware.txt"
    "UT1 malware"

    "https://raw.githubusercontent.com/olbat/ut1-blacklists/master/blacklists/phishing/domains"
    "$TMPDIR/phishing.txt"
    "UT1 phishing"
)

ARMADA_EXTRA_SOURCES=(
    "https://joewein.net/dl/bl/dom-bl-base.txt"
    "$TMPDIR/dombl.txt"
    "JoeWein domain blocklist"

    "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADomains.txt"
    "$TMPDIR/kad.txt"
    "KADhosts (Polish filters)"

    "https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-domains-ACTIVE.txt"
    "$TMPDIR/phishing_krogza.txt"
    "Krogza phishing DB"

    "https://openphish.com/feed.txt"
    "$TMPDIR/openphish.txt"
    "OpenPhish"

    "https://v.firebog.net/hosts/Prigent-Malware.txt"
    "$TMPDIR/prigent-malware.txt"
    "Prigent malware"
)

AMNESTY_INVESTIGATIONS=(
    "2021-07-18_nso/domains.txt"
    "2021-05-28_qatar/domains.txt"
    "2020-09-25_finfisher/domains.txt"
    "2020-06-15_india/domains.txt"
    "2019-10-10_nso_morocco/domains.txt"
    "2019-08-16_evolving_phishing/domains.txt"
    "2019-03-06_egypt_oauth/domains.txt"
    "2018-12-19_best_practice/domains.txt"
)

AMNESTY_BASE="https://raw.githubusercontent.com/AmnestyTech/investigations/master"

# ── Download phase ──────────────────────────────────────────────────
step "Downloading sources"
FAIL_COUNT=0

# Undelegated TLD list
fetch \
    "https://github.com/jedisct1/encrypted-dns-server/raw/master/undelegated.txt" \
    "$UNDELEGATED" \
    "Undelegated TLDs" || ((FAIL_COUNT++))

# Guardian sources
for ((i = 0; i < ${#GUARDIAN_SOURCES[@]}; i += 3)); do
    fetch "${GUARDIAN_SOURCES[i]}" "${GUARDIAN_SOURCES[i+1]}" "${GUARDIAN_SOURCES[i+2]}" \
        || ((FAIL_COUNT++))
done

# Armada-only sources
for ((i = 0; i < ${#ARMADA_EXTRA_SOURCES[@]}; i += 3)); do
    fetch "${ARMADA_EXTRA_SOURCES[i]}" "${ARMADA_EXTRA_SOURCES[i+1]}" "${ARMADA_EXTRA_SOURCES[i+2]}" \
        || ((FAIL_COUNT++))
done

# Manual blocks & whitelist
fetch \
    "https://raw.githubusercontent.com/pysiak/dnscrypt.pl/main/configs/manualblocks.conf" \
    "$MANUALBLOCKS" \
    "Manual blocks" || ((FAIL_COUNT++))

fetch \
    "https://raw.githubusercontent.com/pysiak/dnscrypt.pl/main/configs/whitelist.conf" \
    "$WHITELIST" \
    "Whitelist" || ((FAIL_COUNT++))

# Amnesty Tech investigations
log "Downloading: Amnesty Tech investigations"
for inv in "${AMNESTY_INVESTIGATIONS[@]}"; do
    slug="${inv%%/*}"
    wget -q --timeout=30 --tries=2 \
        "${AMNESTY_BASE}/${inv}" \
        -O "$TMPDIR/at_${slug}.txt" 2>/dev/null || true
done

# Amnesty CSV (NSO 2018 — indicators, not plain domains)
if wget -q --timeout=30 --tries=2 \
    "${AMNESTY_BASE}/2018-08-01_nso/indicators.csv" \
    -O "$TMPDIR/at_nso_csv.txt"; then
    awk -F, 'NR > 1 { gsub(/"/, "", $1); print $1 }' "$TMPDIR/at_nso_csv.txt" \
        | sort -u > "$TMPDIR/at_nso_domains.txt"
else
    touch "$TMPDIR/at_nso_domains.txt"
fi

# Merge all Amnesty into one file
cat "$TMPDIR"/at_*.txt 2>/dev/null | sort -u > "$TMPDIR/amnesty_all.txt"
ok "Amnesty Tech  ($(count "$TMPDIR/amnesty_all.txt") domains)"

[[ $FAIL_COUNT -gt 0 ]] && warn "$FAIL_COUNT source(s) failed to download"

# ── Build Guardian ──────────────────────────────────────────────────
step "Building Guardian blocklist"

{
    cat "$TMPDIR/cert.txt"
    strip_comments "$TMPDIR/phishingarmy.txt"
    strip_comments "$TMPDIR/notrack.txt"
    cat "$TMPDIR/malware.txt"
    cat "$TMPDIR/phishing.txt"
    cat "$TMPDIR/amnesty_all.txt"
} | sort -u > "$BLOCKFILE_GUARDIAN"

ok "Guardian raw: $(count "$BLOCKFILE_GUARDIAN") unique domains"

# ── Build Armada ────────────────────────────────────────────────────
step "Building Armada blocklist"

{
    cat "$BLOCKFILE_GUARDIAN"

    cat "$TMPDIR/dombl.txt"

    strip_comments "$TMPDIR/kad.txt" | grep '\.'

    cat "$TMPDIR/phishing_krogza.txt"

    # OpenPhish: extract domain from full URLs
    awk -F/ '{ print $3 }' "$TMPDIR/openphish.txt" 2>/dev/null

    cat "$TMPDIR/prigent-malware.txt"

    strip_comments "$MANUALBLOCKS"

    cat "$TMPDIR/amnesty_all.txt"
} | sort -u > "$BLOCKFILE_ARMADA"

ok "Armada raw: $(count "$BLOCKFILE_ARMADA") unique domains"

# ── Whitelist removal ───────────────────────────────────────────────
step "Applying whitelist"

if [[ -s "$WHITELIST" ]]; then
    for blocklist in "$BLOCKFILE_GUARDIAN" "$BLOCKFILE_ARMADA"; do
        before=$(count "$blocklist")
        grep -Fvx -f "$WHITELIST" "$blocklist" > "${blocklist}.tmp"
        mv "${blocklist}.tmp" "$blocklist"
        after=$(count "$blocklist")
        ok "$(basename "$blocklist"): $before → $after  ($(( before - after )) whitelisted)"
    done
else
    warn "Whitelist is empty — skipping"
fi

# ── Deploy ──────────────────────────────────────────────────────────
step "Deploying"

if $DRY_RUN; then
    warn "Dry-run mode — skipping service restarts and web copy"
else
    log "Restarting encdns2054 (Guardian)…"
    systemctl restart encdns2054
    ok "encdns2054 restarted"

    log "Restarting encdns2055 (Armada)…"
    systemctl restart encdns2055
    ok "encdns2055 restarted"

    log "Publishing to webroot…"
    cp "$BLOCKFILE_GUARDIAN" "$WEBROOT/guardian.txt"
    cp "$BLOCKFILE_ARMADA"   "$WEBROOT/armada.txt"
    count "$BLOCKFILE_GUARDIAN" > "$WEBROOT/guardian_count.txt"
    count "$BLOCKFILE_ARMADA"   > "$WEBROOT/armada_count.txt"
    ok "Web files updated"
fi

# ── Summary ─────────────────────────────────────────────────────────
step "Summary"
printf "  ${BOLD}Guardian${RESET}  %s domains\n" "$(count "$BLOCKFILE_GUARDIAN")"
printf "  ${BOLD}Armada${RESET}    %s domains\n" "$(count "$BLOCKFILE_ARMADA")"
[[ $FAIL_COUNT -gt 0 ]] && printf "  ${YELLOW}Warnings${RESET}  %s source(s) failed\n" "$FAIL_COUNT"
echo ""
ok "All done!"

