#!/usr/bin/env bash
# Process S&P 500 company CSV data from a remote URL.

set -euo pipefail

CSV_URL="${1:-}"

if [[ -z "$CSV_URL" ]]; then
    echo "Error: CSV URL is required." >&2
    echo "Usage: $0 \"DATASET_URL\"" >&2
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed." >&2
    exit 1
fi

tmp_file="$(mktemp)"
cleanup() {
    rm -f "$tmp_file"
}
trap cleanup EXIT

if ! curl -fsSL "$CSV_URL" -o "$tmp_file"; then
    echo "Error: Failed to retrieve CSV data from '$CSV_URL'." >&2
    exit 1
fi

if [[ ! -s "$tmp_file" ]]; then
    echo "Error: Retrieved CSV data is empty." >&2
    exit 1
fi

# FPAT supports quoted CSV fields that contain commas.
awk '
BEGIN {
    FPAT = "([^,]+|\"[^\"]+\")"
    OFS = "\t"
}

function strip_quotes(value) {
    sub(/^"/, "", value)
    sub(/"$/, "", value)
    return value
}

function founding_sort_key(value,    match_result) {
    if (match(value, /[0-9]{4}/)) {
        return substr(value, RSTART, 4) + 0
    }
    return 9999
}

NR == 1 {
    next
}

{
    company = strip_quotes($2)
    location = strip_quotes($5)
    founded = strip_quotes($8)
    key = sprintf("%04d|%s", founding_sort_key(founded), company)
    records[key] = company OFS location OFS founded
    keys[++count] = key
}

END {
    if (count == 0) {
        print "Error: No company records found." > "/dev/stderr"
        exit 1
    }

    n = asort(keys)
    print "Company Name", "Location", "Founding Year"
    print "------------", "--------", "-------------"

    for (i = 1; i <= n; i++) {
        print records[keys[i]]
    }
}
' "$tmp_file" | column -t -s $'\t'
