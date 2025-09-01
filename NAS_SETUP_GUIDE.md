# UGREEN NAS Setup and PC File Migration Guide

This repository contains tools and configurations for moving non-essential PC files to a UGREEN NAS server and setting up RAID configurations.

## Overview

The solution consists of three main components:

1. **File Identification Script** (`identify_non_essential_files.py`) - Scans PC for non-essential files
2. **File Migration Script** (`move_files_to_nas.py`) - Safely moves identified files to NAS
3. **RAID Configuration Tool** (`ugreen_nas_raid_config.sh`) - Sets up and manages RAID arrays on UGREEN NAS
4. **Configuration File** (`ugreen_nas_config.json`) - Defines NAS settings and migration rules

## Quick Start

### 1. Identify Non-Essential Files

First, scan your PC to identify files that can be moved to NAS:

```bash
python3 identify_non_essential_files.py --older-than 30 --min-size 10
```

This will create a `non_essential_files.json` file with categorized files.

### 2. Set Up UGREEN NAS RAID

Configure RAID arrays on your UGREEN NAS server:

```bash
# Show available disks
sudo ./ugreen_nas_raid_config.sh show-disks

# Create RAID 1 array for storage
sudo ./ugreen_nas_raid_config.sh create-raid 1 storage sdb sdc

# Format and mount the array
sudo ./ugreen_nas_raid_config.sh format-mount storage /mnt/storage ext4

# Check RAID status
./ugreen_nas_raid_config.sh show-status storage
```

### 3. Move Files to NAS

Move the identified files to your NAS:

```bash
# Dry run first to see what would be moved
python3 move_files_to_nas.py /mnt/storage --dry-run

# Perform actual move
python3 move_files_to_nas.py /mnt/storage
```

## Detailed Usage

### File Identification Script

The `identify_non_essential_files.py` script scans for various types of non-essential files:

- **Cache files**: Browser cache, application cache, temporary files
- **Old downloads**: Files older than specified days in Downloads folder
- **Large media files**: Videos, ISOs, and other large files
- **Development artifacts**: node_modules, build folders, compiled files

#### Options:

- `--older-than N`: Consider files older than N days (default: 30)
- `--min-size N`: Consider files larger than N MB (default: 10)
- `--output FILE`: Output file for results (default: non_essential_files.json)

#### Example:

```bash
# Find files older than 60 days or larger than 50MB
python3 identify_non_essential_files.py --older-than 60 --min-size 50 --output large_files.json
```

### File Migration Script

The `move_files_to_nas.py` script safely moves files to NAS with verification:

#### Features:

- **Checksum verification**: Ensures file integrity during transfer
- **Organized storage**: Files are organized by category and date
- **Conflict resolution**: Handles filename conflicts automatically
- **Detailed logging**: Comprehensive logs of all operations
- **Rollback capability**: Maintains records for potential recovery

#### Options:

- `--input FILE`: Input file with file list (default: non_essential_files.json)
- `--dry-run`: Preview operations without moving files
- `--no-verify`: Skip checksum verification for faster transfers

#### Example:

```bash
# Move files to NAS with full verification
python3 move_files_to_nas.py /path/to/nas/storage

# Quick move without verification
python3 move_files_to_nas.py /path/to/nas/storage --no-verify
```

### RAID Configuration Tool

The `ugreen_nas_raid_config.sh` script helps set up and manage RAID arrays:

#### Supported RAID Levels:

- **RAID 0**: Striping (performance, no redundancy)
- **RAID 1**: Mirroring (redundancy)
- **RAID 5**: Striping with parity (balanced)
- **RAID 6**: Striping with double parity (high redundancy)
- **RAID 10**: Mirrored striping (high performance + redundancy)

#### Commands:

```bash
# Show available disks
./ugreen_nas_raid_config.sh show-disks

# Create RAID array
./ugreen_nas_raid_config.sh create-raid LEVEL NAME DISK1 DISK2 [DISK3...]

# Show RAID status
./ugreen_nas_raid_config.sh show-status [NAME]

# Monitor RAID (real-time)
./ugreen_nas_raid_config.sh monitor NAME

# Format and mount
./ugreen_nas_raid_config.sh format-mount NAME MOUNT_POINT [FILESYSTEM]
```

#### Examples:

```bash
# Create RAID 1 for important data
sudo ./ugreen_nas_raid_config.sh create-raid 1 important sdb sdc

# Create RAID 5 for bulk storage
sudo ./ugreen_nas_raid_config.sh create-raid 5 bulk sdd sde sdf

# Format with different filesystems
sudo ./ugreen_nas_raid_config.sh format-mount important /mnt/important ext4
sudo ./ugreen_nas_raid_config.sh format-mount bulk /mnt/bulk btrfs
```

## Configuration

### NAS Configuration File

The `ugreen_nas_config.json` file contains comprehensive NAS settings:

#### Key Sections:

1. **Server Info**: IP address, hostname, ports
2. **RAID Arrays**: RAID configurations and mount points
3. **Network Shares**: SMB/NFS share definitions
4. **Migration Rules**: File categorization and retention policies
5. **Backup Strategy**: Automated backup configurations
6. **Monitoring**: Health checks and alerting
7. **Security**: Firewall rules and user accounts

#### Customization:

Edit the configuration file to match your network and requirements:

```json
{
  "nas_configuration": {
    "server_info": {
      "ip_address": "YOUR_NAS_IP",
      "hostname": "YOUR_NAS_HOSTNAME"
    }
  }
}
```

## Network Setup

### SMB Share Access

Connect to NAS shares from Windows:

1. Open File Explorer
2. In address bar, type: `\\NAS_IP_ADDRESS\pc-migration`
3. Enter credentials when prompted

### Linux/Mac Access

Mount NAS shares:

```bash
# Create mount point
sudo mkdir /mnt/nas

# Mount SMB share
sudo mount -t cifs //NAS_IP_ADDRESS/pc-migration /mnt/nas -o username=USER
```

## Maintenance

### Monitoring RAID Health

Check RAID status regularly:

```bash
# Quick status check
./ugreen_nas_raid_config.sh show-status

# Monitor specific array
./ugreen_nas_raid_config.sh monitor storage
```

### File Cleanup

Set up automated cleanup of migrated files based on retention policies defined in the configuration.

### Backup Verification

Regularly verify that your backup strategy is working:

1. Check backup completion logs
2. Test file restoration procedures
3. Verify RAID array integrity

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure scripts are run with appropriate permissions
2. **Disk Not Found**: Verify disk names with `lsblk` command
3. **Network Issues**: Check NAS connectivity and share permissions
4. **RAID Degraded**: Monitor array status and replace failed disks promptly

### Log Files

Check log files for detailed error information:

- Migration logs: `nas_move_YYYYMMDD_HHMMSS.log`
- RAID operations: System logs in `/var/log/syslog`
- Move reports: `nas_move_report_YYYYMMDD_HHMMSS.json`

## Security Considerations

1. **Network Security**: Ensure NAS is behind firewall
2. **Access Control**: Use strong passwords and appropriate user permissions
3. **Encryption**: Consider enabling SMB encryption for sensitive data
4. **Regular Updates**: Keep NAS firmware updated
5. **Backup Strategy**: Maintain offsite backups for critical data

## Support

For issues and questions:

1. Check log files for error details
2. Verify network connectivity to NAS
3. Ensure proper permissions and disk availability
4. Consult UGREEN NAS documentation for device-specific issues

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.