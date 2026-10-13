#!/bin/bash
set -uo pipefail

DATA=/data
EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904

log() {
    echo "$(date -Is) $*"
}

git_data() {
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null git -C "$DATA" \
        -c core.hooksPath=/dev/null -c core.fsmonitor=false -c core.autocrlf=false \
        -c core.excludesFile=/dev/null -c "attr.tree=$EMPTY_TREE" \
        -c user.name=backup -c user.email=backup@localhost "$@"
}

if ! [[ "$BACKUP_INTERVAL" =~ ^[1-9][0-9]*$ ]]; then
    log "BACKUP_INTERVAL=$BACKUP_INTERVAL is not a positive number of seconds"
    exit 1
fi

[ -d "$DATA/.git" ] || git_data init -q -b main
log "container started, image $IMAGE_VERSION, a copy of $SOURCE_FOLDER every $BACKUP_INTERVAL s"

while true; do
    start=$(date +%s)
    if ! rsync -rlpt --delete --no-specials --no-devices --exclude .git "$SOURCE_FOLDER/" "$DATA/"; then
        log "the copy is incomplete"
    fi
    git_data add --all --force .
    if git_data diff --cached --quiet; then
        log "nothing changed"
    else
        git_data commit -q -m "$(date -Is)"
        log "copied:$(git_data show --shortstat --format= HEAD)"
    fi
    next=$((start + BACKUP_INTERVAL))
    now=$(date +%s)
    [ "$next" -gt "$now" ] && sleep $((next - now))
done
