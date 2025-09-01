#!/bin/bash
# UGREEN NAS RAID Configuration Script
# This script helps configure RAID settings on UGREEN NAS servers

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="ugreen_nas_config.json"

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for RAID configuration"
        exit 1
    fi
}

# Check system compatibility
check_system() {
    log "Checking system compatibility..."
    
    # Check if mdadm is available
    if ! command -v mdadm &> /dev/null; then
        error "mdadm is required but not installed. Install with: apt-get install mdadm"
        exit 1
    fi
    
    # Check if lsblk is available
    if ! command -v lsblk &> /dev/null; then
        error "lsblk is required but not available"
        exit 1
    fi
    
    success "System compatibility check passed"
}

# Display available disks
show_disks() {
    log "Available storage devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL | grep -E "(disk|NAME)"
    echo ""
}

# Get disk information
get_disk_info() {
    local disk=$1
    if [[ ! -b "/dev/$disk" ]]; then
        error "Disk /dev/$disk not found"
        return 1
    fi
    
    local size=$(lsblk -b -d -o SIZE "/dev/$disk" | tail -n1)
    local model=$(lsblk -d -o MODEL "/dev/$disk" | tail -n1 | xargs)
    
    echo "Disk: /dev/$disk, Size: $((size / 1024 / 1024 / 1024))GB, Model: $model"
}

# Create RAID configuration
create_raid() {
    local raid_level=$1
    local raid_name=$2
    shift 2
    local disks=("$@")
    
    log "Creating RAID $raid_level array '$raid_name' with disks: ${disks[*]}"
    
    # Validate disk count for RAID level
    case $raid_level in
        0)
            if [[ ${#disks[@]} -lt 2 ]]; then
                error "RAID 0 requires at least 2 disks"
                return 1
            fi
            ;;
        1)
            if [[ ${#disks[@]} -ne 2 ]]; then
                error "RAID 1 requires exactly 2 disks"
                return 1
            fi
            ;;
        5)
            if [[ ${#disks[@]} -lt 3 ]]; then
                error "RAID 5 requires at least 3 disks"
                return 1
            fi
            ;;
        6)
            if [[ ${#disks[@]} -lt 4 ]]; then
                error "RAID 6 requires at least 4 disks"
                return 1
            fi
            ;;
        10)
            if [[ ${#disks[@]} -lt 4 ]] || [[ $((${#disks[@]} % 2)) -ne 0 ]]; then
                error "RAID 10 requires at least 4 disks and an even number of disks"
                return 1
            fi
            ;;
        *)
            error "Unsupported RAID level: $raid_level"
            return 1
            ;;
    esac
    
    # Prepare disk devices
    local disk_devices=()
    for disk in "${disks[@]}"; do
        if [[ ! -b "/dev/$disk" ]]; then
            error "Disk /dev/$disk not found"
            return 1
        fi
        disk_devices+=("/dev/$disk")
        
        # Check if disk is already in use
        if lsblk "/dev/$disk" | grep -q "part\|raid"; then
            warning "Disk /dev/$disk appears to be in use. Continue? (y/N)"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                error "Operation cancelled"
                return 1
            fi
        fi
    done
    
    # Create RAID array
    local md_device="/dev/md/$raid_name"
    
    log "Creating RAID array with command:"
    echo "mdadm --create $md_device --level=$raid_level --raid-devices=${#disk_devices[@]} ${disk_devices[*]}"
    
    if mdadm --create "$md_device" --level="$raid_level" --raid-devices="${#disk_devices[@]}" "${disk_devices[@]}"; then
        success "RAID array $md_device created successfully"
        
        # Save configuration
        mdadm --detail --scan >> /etc/mdadm/mdadm.conf
        update-initramfs -u
        
        # Show array status
        show_raid_status "$raid_name"
        
        return 0
    else
        error "Failed to create RAID array"
        return 1
    fi
}

# Show RAID status
show_raid_status() {
    local raid_name=${1:-}
    
    if [[ -n "$raid_name" ]]; then
        if [[ -b "/dev/md/$raid_name" ]]; then
            log "Status for RAID array: $raid_name"
            mdadm --detail "/dev/md/$raid_name"
        else
            error "RAID array /dev/md/$raid_name not found"
            return 1
        fi
    else
        log "All RAID arrays status:"
        cat /proc/mdstat
        echo ""
        
        # Show detailed status for each array
        for md_device in /dev/md*; do
            if [[ -b "$md_device" ]]; then
                echo "Details for $md_device:"
                mdadm --detail "$md_device" 2>/dev/null || true
                echo ""
            fi
        done
    fi
}

# Monitor RAID array
monitor_raid() {
    local raid_name=$1
    local md_device="/dev/md/$raid_name"
    
    if [[ ! -b "$md_device" ]]; then
        error "RAID array $md_device not found"
        return 1
    fi
    
    log "Monitoring RAID array: $raid_name"
    log "Press Ctrl+C to stop monitoring"
    
    while true; do
        clear
        echo "RAID Monitoring - $(date)"
        echo "================================"
        mdadm --detail "$md_device"
        echo ""
        echo "Press Ctrl+C to stop..."
        sleep 5
    done
}

# Format and mount RAID array
format_and_mount_raid() {
    local raid_name=$1
    local mount_point=$2
    local filesystem=${3:-ext4}
    
    local md_device="/dev/md/$raid_name"
    
    if [[ ! -b "$md_device" ]]; then
        error "RAID array $md_device not found"
        return 1
    fi
    
    log "Formatting RAID array $md_device with $filesystem filesystem..."
    
    case $filesystem in
        ext4)
            mkfs.ext4 -F "$md_device"
            ;;
        xfs)
            mkfs.xfs -f "$md_device"
            ;;
        btrfs)
            mkfs.btrfs -f "$md_device"
            ;;
        *)
            error "Unsupported filesystem: $filesystem"
            return 1
            ;;
    esac
    
    # Create mount point
    mkdir -p "$mount_point"
    
    # Mount the array
    mount "$md_device" "$mount_point"
    
    # Add to fstab for persistent mounting
    echo "$md_device $mount_point $filesystem defaults 0 2" >> /etc/fstab
    
    success "RAID array formatted and mounted at $mount_point"
    
    # Show mount information
    df -h "$mount_point"
}

# Save NAS configuration
save_nas_config() {
    local config_data='
{
  "nas_config": {
    "creation_date": "'$(date -Iseconds)'",
    "raid_arrays": [],
    "mount_points": [],
    "network_shares": []
  }
}'
    
    echo "$config_data" > "$CONFIG_FILE"
    log "NAS configuration template saved to $CONFIG_FILE"
}

# Show help
show_help() {
    echo "UGREEN NAS RAID Configuration Tool"
    echo "=================================="
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  show-disks              Show available storage devices"
    echo "  create-raid LEVEL NAME DISK1 DISK2 [DISK3...]"
    echo "                         Create RAID array"
    echo "  show-status [NAME]     Show RAID array status"
    echo "  monitor NAME           Monitor RAID array"
    echo "  format-mount NAME MOUNT_POINT [FILESYSTEM]"
    echo "                         Format and mount RAID array"
    echo "  save-config            Save NAS configuration template"
    echo "  help                   Show this help"
    echo ""
    echo "RAID Levels:"
    echo "  0    - Striping (no redundancy, better performance)"
    echo "  1    - Mirroring (redundancy, same capacity as single disk)"
    echo "  5    - Striping with parity (good balance of performance and redundancy)"
    echo "  6    - Striping with double parity (better redundancy than RAID 5)"
    echo "  10   - Mirrored striping (high performance and redundancy)"
    echo ""
    echo "Examples:"
    echo "  $0 show-disks"
    echo "  $0 create-raid 1 storage sdb sdc"
    echo "  $0 show-status storage"
    echo "  $0 format-mount storage /mnt/nas ext4"
    echo ""
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local command=$1
    shift
    
    case $command in
        check-system)
            check_system
            ;;
        show-disks)
            show_disks
            ;;
        create-raid)
            check_root
            check_system
            if [[ $# -lt 3 ]]; then
                error "Usage: create-raid LEVEL NAME DISK1 DISK2 [DISK3...]"
                exit 1
            fi
            create_raid "$@"
            ;;
        show-status)
            show_raid_status "${1:-}"
            ;;
        monitor)
            if [[ $# -ne 1 ]]; then
                error "Usage: monitor RAID_NAME"
                exit 1
            fi
            monitor_raid "$1"
            ;;
        format-mount)
            check_root
            if [[ $# -lt 2 ]]; then
                error "Usage: format-mount RAID_NAME MOUNT_POINT [FILESYSTEM]"
                exit 1
            fi
            format_and_mount_raid "$@"
            ;;
        save-config)
            save_nas_config
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"