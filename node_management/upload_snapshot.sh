#!/bin/bash

# Directory to watch
WATCH_DIR="$HOME/snapshot"
RCLONE_REMOTE="cloudflare-r2:testnet-archive-snapshot/snapshots"
SNAPSHOT_INFO_FILE="$WATCH_DIR/latest_snapshot_info"
LOG_FILE="$HOME/sync_snapshots.log"
LOCK_FILE=UPLOAD_IN_PROGRESS
UPLOADER_IP_FILE=UPLOADER_IP

function log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

function check_active_uploader() {
    CURRENT_UPLOADER_IP="$(rclone cat "$RCLONE_REMOTE/$UPLOADER_IP_FILE")"
    LOCAL_IP="$(curl https://ipinfo.io/ip 2>/dev/null)"

    if [ -n "$CURRENT_UPLOADER_IP" ] && [[ "$LOCAL_IP" != "$CURRENT_UPLOADER_IP" ]]; then
        echo "Error: $CURRENT_UPLOADER_IP is already registered as the uploader for $RCLONE_REMOTE." >&2
        echo "       If you intend to change the uploader, then please manually remove $RCLONE_REMOTE/$UPLOADER_IP_FILE" >&2
        echo "       before continuing." >&2
        exit 1
    fi
}

function register_active_uploader() {
    curl https://ipinfo.io/ip 2>/dev/null >"$UPLOADER_IP_FILE"
    rclone copy "$UPLOADER_IP_FILE" "$RCLONE_REMOTE"
}

function sync_snapshot() {
    local snapshot_info_file="$1"

    log "Starting new sync for snapshot info: $snapshot_info_file"
    # Read the JSON file to extract the paths
    store_path=$(jq -r '.store' "$snapshot_info_file")
    archive_path=$(jq -r '.archive' "$snapshot_info_file")

    if [[ -d "$store_path" && -d "$archive_path" ]]; then
        # Upload the marker to indicate that an upload is in progress.
        date >"$LOCK_FILE"
        rclone copy "$LOCK_FILE" "$RCLONE_REMOTE"

        # Sync the store directory with time tracking
        log "Syncing store directory: $store_path"
        time rclone sync --checkers=32 "$store_path" "$RCLONE_REMOTE/store" 2>&1 | tee -a "$LOG_FILE"

        # Sync the archive directory with time tracking
        log "Syncing archive directory: $archive_path"
        time rclone sync --checkers=32 "$archive_path" "$RCLONE_REMOTE/archive" 2>&1 | tee -a "$LOG_FILE"

        # Remove the marker.
        rclone delete "$RCLONE_REMOTE/$LOCK_FILE"
        log "Sync completed."
    else
        log "Error: Store or archive paths are invalid."
    fi
}

function main() {
    # Check if there is already an uploader active to help to avoid accidental overwrites.
    check_active_uploader
    # Register this node as the active uploader.
    register_active_uploader

    # Monitor the file for modification events
    inotifywait -m -e modify "$SNAPSHOT_INFO_FILE" | while read; do
        sync_snapshot "$SNAPSHOT_INFO_FILE"
    done
}

main "$@"
