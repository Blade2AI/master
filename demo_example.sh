#!/bin/bash
# Example usage script for NAS migration and RAID setup

echo "UGREEN NAS Setup and File Migration Example"
echo "==========================================="
echo ""

# Check if running as root for RAID operations
if [[ $EUID -eq 0 ]]; then
    echo "Running as root - RAID operations available"
    CAN_RAID=true
else
    echo "Not running as root - RAID operations will be skipped"
    CAN_RAID=false
fi

echo ""
echo "Step 1: Identifying non-essential files on PC..."
echo "Command: python3 identify_non_essential_files.py --older-than 30 --min-size 5 --output example_files.json"

# Create a sample scan (won't find much in this environment)
python3 identify_non_essential_files.py --older-than 30 --min-size 5 --output example_files.json

echo ""
echo "Step 2: RAID Configuration (requires root privileges)"
if [[ "$CAN_RAID" == true ]]; then
    echo "Showing available disks:"
    ./ugreen_nas_raid_config.sh show-disks
    
    echo ""
    echo "To create a RAID 1 array, you would run:"
    echo "  ./ugreen_nas_raid_config.sh create-raid 1 storage sdb sdc"
    echo ""
    echo "To format and mount:"
    echo "  ./ugreen_nas_raid_config.sh format-mount storage /mnt/storage ext4"
else
    echo "RAID operations require root privileges. Run with sudo for full demo."
fi

echo ""
echo "Step 3: File migration to NAS"
echo "Creating temporary NAS directory for demo..."
mkdir -p /tmp/demo_nas

echo "Command: python3 move_files_to_nas.py /tmp/demo_nas --dry-run --input example_files.json"
python3 move_files_to_nas.py /tmp/demo_nas --dry-run --input example_files.json

echo ""
echo "Step 4: Configuration management"
echo "Saving NAS configuration template..."
./ugreen_nas_raid_config.sh save-config

echo ""
echo "Demo complete! Check the following files:"
echo "  - example_files.json: Identified files"
echo "  - ugreen_nas_config.json: NAS configuration template"
echo "  - NAS_SETUP_GUIDE.md: Complete documentation"
echo ""
echo "For production use, replace /tmp/demo_nas with your actual NAS mount point."