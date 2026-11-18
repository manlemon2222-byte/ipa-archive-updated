#!/usr/bin/env bash
# ==============================================================================
# Script: download_mega_zip.sh
# Purpose: Automatically download a MEGA public folder and compress it into a .zip
# Target URL: https://mega.nz/folder/B2pShKDY#xl5HF4oL7cS8fvKxtCoaiA
# ==============================================================================

set -e

MEGA_URL="${1:-https://mega.nz/folder/B2pShKDY#xl5HF4oL7cS8fvKxtCoaiA}"
DEST_DIR="/storage/emulated/0/Download/TestflightMega"
ZIP_FILE="/storage/emulated/0/Download/TestflightMega.zip"

echo "======================================================"
echo " MEGA Folder Downloader & ZIP Packager"
echo "======================================================"
echo "URL:         $MEGA_URL"
echo "Download to: $DEST_DIR"
echo "Output ZIP:  $ZIP_FILE"
echo "======================================================"

# 1. Ensure tools are available
if ! command -v mega-get >/dev/null 2>&1; then
    echo "[!] Error: mega-get (MEGAcmd) not found. Installing..."
    pkg install -y megacmd
fi

if ! command -v zip >/dev/null 2>&1; then
    echo "[!] Error: zip not found. Installing..."
    pkg install -y zip
fi

# 2. Prepare destination directory
mkdir -p "$DEST_DIR"

# 3. Clean up any stale active transfers before starting
echo "[*] Initializing MEGAcmd transfer queue..."
mega-transfers -c -a >/dev/null 2>&1 || true

# 4. Enqueue the folder download (-q for background queue, -m for resumable merge)
echo "[*] Queuing MEGA folder download..."
mega-get -m -q "$MEGA_URL" "$DEST_DIR/"

sleep 3

# 5. Monitor transfer progress
echo "[*] Downloading files... (Press Ctrl+C to cancel)"
while true; do
    # Get summary line
    SUMMARY=$(mega-transfers --summary 2>/dev/null | tail -n 1 || true)
    
    # Read active download count (first column)
    ACTIVE_COUNT=$(echo "$SUMMARY" | awk '{print $1}')
    
    if [ -z "$ACTIVE_COUNT" ] || [ "$ACTIVE_COUNT" = "0" ]; then
        # Check if there are any files downloaded
        DOWNLOAD_COUNT=$(find "$DEST_DIR" -type f | wc -l)
        if [ "$DOWNLOAD_COUNT" -gt 0 ]; then
            echo ""
            echo "[+] All downloads completed successfully! Total files: $DOWNLOAD_COUNT"
            break
        fi
    fi
    
    # Print formatted progress line
    DOWNLOADED=$(echo "$SUMMARY" | awk '{print $2, $3}')
    TOTAL=$(echo "$SUMMARY" | awk '{print $4, $5}')
    PERCENT=$(echo "$SUMMARY" | awk '{print $6}')
    
    printf "\r[*] Queue: %s active | Progress: %s / %s (%s)      " "$ACTIVE_COUNT" "$DOWNLOADED" "$TOTAL" "$PERCENT"
    sleep 3
done

# 6. Compress into .zip
echo ""
echo "[*] Compressing downloaded files into $ZIP_FILE..."
cd "/storage/emulated/0/Download"
zip -r -q "TestflightMega.zip" "TestflightMega"

# 7. Final Report
ZIP_SIZE=$(du -h "$ZIP_FILE" | awk '{print $1}')
echo "======================================================"
echo "[SUCCESS] Archive created successfully!"
echo "ZIP Location: $ZIP_FILE"
echo "ZIP Size:     $ZIP_SIZE"
echo "======================================================"
