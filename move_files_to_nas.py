#!/usr/bin/env python3
"""
Script to move non-essential files from PC to NAS storage.
This script safely moves files identified by identify_non_essential_files.py to NAS.
"""

import os
import sys
import json
import shutil
import hashlib
from pathlib import Path
from datetime import datetime
import argparse
import logging

class NASMover:
    def __init__(self, nas_path, input_file='non_essential_files.json', dry_run=False, verify_checksums=True):
        self.nas_path = Path(nas_path)
        self.input_file = input_file
        self.dry_run = dry_run
        self.verify_checksums = verify_checksums
        self.moved_files = []
        self.failed_moves = []
        self.total_moved_size = 0
        
        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(f'nas_move_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def validate_nas_connection(self):
        """Validate that NAS path is accessible"""
        if not self.nas_path.exists():
            raise ValueError(f"NAS path does not exist: {self.nas_path}")
        
        if not self.nas_path.is_dir():
            raise ValueError(f"NAS path is not a directory: {self.nas_path}")
        
        # Test write permissions
        test_file = self.nas_path / f".test_write_{datetime.now().timestamp()}"
        try:
            test_file.write_text("test")
            test_file.unlink()
            self.logger.info(f"NAS connection validated: {self.nas_path}")
        except Exception as e:
            raise ValueError(f"Cannot write to NAS path {self.nas_path}: {e}")
    
    def calculate_checksum(self, file_path):
        """Calculate MD5 checksum of a file"""
        hash_md5 = hashlib.md5()
        try:
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_md5.update(chunk)
            return hash_md5.hexdigest()
        except Exception as e:
            self.logger.error(f"Error calculating checksum for {file_path}: {e}")
            return None
    
    def create_nas_structure(self, category):
        """Create directory structure on NAS for organizing files"""
        nas_category_path = self.nas_path / "pc_migration" / category / datetime.now().strftime("%Y-%m-%d")
        if not self.dry_run:
            nas_category_path.mkdir(parents=True, exist_ok=True)
        return nas_category_path
    
    def move_file_to_nas(self, source_path, dest_dir, category):
        """Move a single file to NAS with verification"""
        source = Path(source_path)
        if not source.exists():
            self.logger.warning(f"Source file no longer exists: {source}")
            return False
        
        # Create destination path maintaining relative structure
        rel_path = source.name
        dest_path = dest_dir / rel_path
        
        # Handle filename conflicts
        counter = 1
        while dest_path.exists():
            stem = source.stem
            suffix = source.suffix
            dest_path = dest_dir / f"{stem}_{counter}{suffix}"
            counter += 1
        
        if self.dry_run:
            self.logger.info(f"[DRY RUN] Would move: {source} -> {dest_path}")
            return True
        
        try:
            # Calculate source checksum if verification is enabled
            source_checksum = None
            if self.verify_checksums:
                source_checksum = self.calculate_checksum(source)
            
            # Copy file to NAS
            shutil.copy2(source, dest_path)
            
            # Verify checksum if enabled
            if self.verify_checksums and source_checksum:
                dest_checksum = self.calculate_checksum(dest_path)
                if source_checksum != dest_checksum:
                    dest_path.unlink()  # Remove corrupted copy
                    raise ValueError(f"Checksum mismatch for {source}")
            
            # Remove original file after successful copy
            source.unlink()
            
            file_size = dest_path.stat().st_size
            self.total_moved_size += file_size
            
            move_info = {
                'source': str(source),
                'destination': str(dest_path),
                'size_bytes': file_size,
                'category': category,
                'timestamp': datetime.now().isoformat(),
                'checksum': source_checksum if self.verify_checksums else None
            }
            self.moved_files.append(move_info)
            
            self.logger.info(f"Moved: {source} -> {dest_path} ({file_size / (1024*1024):.2f} MB)")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to move {source}: {e}")
            self.failed_moves.append({
                'source': str(source),
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            })
            return False
    
    def process_file_list(self):
        """Process the list of non-essential files and move them to NAS"""
        if not os.path.exists(self.input_file):
            raise FileNotFoundError(f"Input file not found: {self.input_file}")
        
        with open(self.input_file, 'r') as f:
            file_data = json.load(f)
        
        total_files = file_data['summary']['total_files']
        self.logger.info(f"Processing {total_files} files from {self.input_file}")
        
        if not self.dry_run:
            self.validate_nas_connection()
        
        processed_count = 0
        
        for category, files in file_data['categories'].items():
            if not files:
                continue
                
            self.logger.info(f"Processing category: {category} ({len(files)} files)")
            nas_category_dir = self.create_nas_structure(category)
            
            for file_info in files:
                source_path = file_info['path']
                success = self.move_file_to_nas(source_path, nas_category_dir, category)
                processed_count += 1
                
                if processed_count % 10 == 0:
                    progress = (processed_count / total_files) * 100
                    self.logger.info(f"Progress: {processed_count}/{total_files} ({progress:.1f}%)")
        
        # Save move report
        self.save_move_report()
        
        # Print summary
        self.print_summary()
    
    def save_move_report(self):
        """Save detailed report of move operation"""
        report = {
            'operation': 'nas_move',
            'timestamp': datetime.now().isoformat(),
            'nas_path': str(self.nas_path),
            'dry_run': self.dry_run,
            'verify_checksums': self.verify_checksums,
            'summary': {
                'total_files_processed': len(self.moved_files) + len(self.failed_moves),
                'successful_moves': len(self.moved_files),
                'failed_moves': len(self.failed_moves),
                'total_size_moved_mb': round(self.total_moved_size / (1024 * 1024), 2)
            },
            'moved_files': self.moved_files,
            'failed_moves': self.failed_moves
        }
        
        report_file = f"nas_move_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        self.logger.info(f"Move report saved to: {report_file}")
    
    def print_summary(self):
        """Print operation summary"""
        print("\n" + "="*50)
        print("NAS MOVE OPERATION SUMMARY")
        print("="*50)
        print(f"Mode: {'DRY RUN' if self.dry_run else 'LIVE RUN'}")
        print(f"NAS Path: {self.nas_path}")
        print(f"Files successfully moved: {len(self.moved_files)}")
        print(f"Files failed to move: {len(self.failed_moves)}")
        print(f"Total size moved: {self.total_moved_size / (1024*1024*1024):.2f} GB")
        
        if self.failed_moves:
            print("\nFailed moves:")
            for fail in self.failed_moves[:5]:  # Show first 5 failures
                print(f"  - {fail['source']}: {fail['error']}")
            if len(self.failed_moves) > 5:
                print(f"  ... and {len(self.failed_moves) - 5} more")

def main():
    parser = argparse.ArgumentParser(description='Move non-essential files to NAS storage')
    parser.add_argument('nas_path', help='Path to NAS storage directory')
    parser.add_argument('--input', '-i', default='non_essential_files.json',
                        help='Input file with list of files to move (default: non_essential_files.json)')
    parser.add_argument('--dry-run', '-d', action='store_true',
                        help='Perform dry run without actually moving files')
    parser.add_argument('--no-verify', action='store_true',
                        help='Skip checksum verification (faster but less safe)')
    
    args = parser.parse_args()
    
    try:
        mover = NASMover(
            nas_path=args.nas_path,
            input_file=args.input,
            dry_run=args.dry_run,
            verify_checksums=not args.no_verify
        )
        
        mover.process_file_list()
        
    except KeyboardInterrupt:
        print("\nOperation interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"Error during move operation: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()