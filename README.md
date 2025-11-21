# NAS File Migration and RAID Configuration

This repository contains tools for moving non-essential PC files to UGREEN NAS storage and configuring RAID settings.

## Features

- **File Identification**: Automatically identify non-essential files on PC
- **Safe Migration**: Move files to NAS with integrity verification
- **RAID Configuration**: Set up and manage RAID arrays on UGREEN NAS
- **Comprehensive Documentation**: Complete setup and usage guide

## Quick Start

1. Identify non-essential files: `python3 identify_non_essential_files.py`
2. Configure RAID: `sudo ./ugreen_nas_raid_config.sh create-raid 1 storage sdb sdc`
3. Move files to NAS: `python3 move_files_to_nas.py /mnt/storage`

See [NAS_SETUP_GUIDE.md](NAS_SETUP_GUIDE.md) for detailed instructions.
