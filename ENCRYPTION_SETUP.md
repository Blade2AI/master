# Sovereign Drives Encryption Setup

This guide ensures external drives (PC3, PC4) are encrypted before mirroring sovereign data.

Windows (BitLocker):
1. Open Control Panel > System and Security > BitLocker Drive Encryption
2. Turn on BitLocker for the target drive (e.g., D:, E:)
3. Choose password or TPM + PIN, save recovery key offline
4. Choose Encrypt entire drive, start encryption (can take hours)
5. Verify: manage-bde -status

Linux (LUKS):
1. sudo cryptsetup luksFormat /dev/sdX
2. sudo cryptsetup open /dev/sdX sovereign_backup
3. sudo mkfs.ntfs -f /dev/mapper/sovereign_backup (or ext4)
4. sudo cryptsetup close sovereign_backup
5. Verify: cryptsetup status sovereign_backup

macOS (APFS):
1. Disk Utility > Erase > APFS (Encrypted)
2. Name and set strong password; store in password manager
3. Verify: diskutil apfs list

Checklist:
- D: and E: show ENCRYPTED ?
- Recovery keys stored securely ?
- Test mount/unmount cycle ?
