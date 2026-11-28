#!/usr/bin/env bash
# package-diff.sh PACKAGES — compare an image's package list with the one from
# the last good build of main, as Markdown. Needs gh and GH_TOKEN.

set -euo pipefail

new="$1"
work="$(mktemp -d)"
trap 'rm -rf "${work:?}"' EXIT

echo "## Packages"
echo
echo "$(wc -l < "$new") in this image."
echo

run="$(gh run list --workflow iso.yml --branch main --status success --limit 1 \
    --json databaseId --jq '.[0].databaseId // empty')"
if [[ -z "$run" ]] || ! gh run download "$run" --name packages --dir "$work" 2>/dev/null; then
    echo "No earlier build of main to compare with."
    exit 0
fi

# The list is one "name version" per line.
changes="$(awk '
    NR == FNR { old[$1] = $2; next }
    { new[$1] = $2 }
    END {
        for (p in new) {
            if (!(p in old)) print "| " p " | | " new[p] " |"
            else if (old[p] != new[p]) print "| " p " | " old[p] " | " new[p] " |"
        }
        for (p in old) if (!(p in new)) print "| " p " | " old[p] " | |"
    }
' "$work/$(basename "$new")" "$new" | sort)"

if [[ -z "$changes" ]]; then
    echo "Same as the last build of main."
    exit 0
fi
echo "| Package | main | here |"
echo "|---|---|---|"
echo "$changes"
