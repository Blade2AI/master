#!/usr/bin/env python3
"""
Script to identify non-essential files on PC for moving to NAS storage.
This script scans common directories for files that can be safely moved to NAS.
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime, timedelta
import argparse

# Common non-essential file patterns and directories
NON_ESSENTIAL_PATTERNS = {
    'cache_dirs': [
        '~/.cache',
        '~/AppData/Local/Temp',
        '~/AppData/LocalLow/Temp',
        '/tmp',
        '/var/tmp',
        '~/.npm/_cacache',
        '~/.yarn/cache',
        '~/Library/Caches'
    ],
    'browser_cache': [
        '~/.mozilla/firefox/*/storage',
        '~/AppData/Local/Google/Chrome/User Data/*/Cache',
        '~/AppData/Local/Microsoft/Edge/User Data/*/Cache',
        '~/Library/Caches/Google/Chrome'
    ],
    'old_downloads': [
        '~/Downloads',
        '~/Desktop'
    ],
    'temp_files': [
        '*.tmp',
        '*.temp',
        '*.log',
        '*.bak',
        '*.swp',
        '*~'
    ],
    'large_media': [
        '*.mp4',
        '*.avi',
        '*.mkv',
        '*.mov',
        '*.wmv',
        '*.iso',
        '*.dmg'
    ],
    'development_artifacts': [
        'node_modules',
        '.git',
        '__pycache__',
        '*.pyc',
        'build',
        'dist',
        'target'
    ]
}

class FileAnalyzer:
    def __init__(self, output_file=None, older_than_days=30, min_size_mb=10):
        self.output_file = output_file or 'non_essential_files.json'
        self.older_than_days = older_than_days
        self.min_size_mb = min_size_mb
        self.cutoff_date = datetime.now() - timedelta(days=older_than_days)
        self.min_size_bytes = min_size_mb * 1024 * 1024
        
    def is_old_file(self, file_path):
        """Check if file is older than cutoff date"""
        try:
            mod_time = datetime.fromtimestamp(os.path.getmtime(file_path))
            return mod_time < self.cutoff_date
        except (OSError, ValueError):
            return False
    
    def is_large_file(self, file_path):
        """Check if file is larger than minimum size"""
        try:
            return os.path.getsize(file_path) >= self.min_size_bytes
        except OSError:
            return False
    
    def scan_directory(self, directory, patterns=None):
        """Scan directory for files matching patterns"""
        files_found = []
        directory = Path(directory).expanduser()
        
        if not directory.exists():
            return files_found
        
        try:
            for item in directory.rglob('*'):
                if item.is_file():
                    file_info = {
                        'path': str(item),
                        'size_mb': round(item.stat().st_size / (1024 * 1024), 2),
                        'modified': datetime.fromtimestamp(item.stat().st_mtime).isoformat(),
                        'is_old': self.is_old_file(item),
                        'is_large': self.is_large_file(item)
                    }
                    
                    # Check if file matches any patterns or criteria
                    if patterns:
                        for pattern in patterns:
                            if item.match(pattern):
                                file_info['reason'] = f'matches_pattern_{pattern}'
                                files_found.append(file_info)
                                break
                    elif self.is_old_file(item) or self.is_large_file(item):
                        file_info['reason'] = 'old_or_large'
                        files_found.append(file_info)
                        
        except PermissionError:
            print(f"Permission denied: {directory}")
        except Exception as e:
            print(f"Error scanning {directory}: {e}")
            
        return files_found
    
    def identify_non_essential_files(self):
        """Main method to identify all non-essential files"""
        all_files = {
            'scan_date': datetime.now().isoformat(),
            'criteria': {
                'older_than_days': self.older_than_days,
                'min_size_mb': self.min_size_mb
            },
            'categories': {}
        }
        
        print("Scanning for non-essential files...")
        
        # Scan cache directories
        print("Scanning cache directories...")
        all_files['categories']['cache_files'] = []
        for cache_dir in NON_ESSENTIAL_PATTERNS['cache_dirs']:
            files = self.scan_directory(cache_dir)
            all_files['categories']['cache_files'].extend(files)
        
        # Scan browser cache
        print("Scanning browser cache...")
        all_files['categories']['browser_cache'] = []
        for browser_cache in NON_ESSENTIAL_PATTERNS['browser_cache']:
            files = self.scan_directory(browser_cache)
            all_files['categories']['browser_cache'].extend(files)
        
        # Scan downloads for old files
        print("Scanning downloads for old files...")
        all_files['categories']['old_downloads'] = []
        for download_dir in NON_ESSENTIAL_PATTERNS['old_downloads']:
            files = self.scan_directory(download_dir)
            all_files['categories']['old_downloads'].extend(files)
        
        # Scan for large media files
        print("Scanning for large media files...")
        all_files['categories']['large_media'] = []
        home_dir = Path.home()
        for item in home_dir.rglob('*'):
            if item.is_file() and any(item.match(pattern) for pattern in NON_ESSENTIAL_PATTERNS['large_media']):
                if self.is_large_file(item):
                    file_info = {
                        'path': str(item),
                        'size_mb': round(item.stat().st_size / (1024 * 1024), 2),
                        'modified': datetime.fromtimestamp(item.stat().st_mtime).isoformat(),
                        'reason': 'large_media_file'
                    }
                    all_files['categories']['large_media'].append(file_info)
        
        # Calculate totals
        total_files = sum(len(files) for files in all_files['categories'].values())
        total_size_mb = sum(
            sum(file_info['size_mb'] for file_info in files)
            for files in all_files['categories'].values()
        )
        
        all_files['summary'] = {
            'total_files': total_files,
            'total_size_mb': round(total_size_mb, 2),
            'total_size_gb': round(total_size_mb / 1024, 2)
        }
        
        # Save results
        with open(self.output_file, 'w') as f:
            json.dump(all_files, f, indent=2)
        
        print(f"\nScan complete!")
        print(f"Found {total_files} non-essential files")
        print(f"Total size: {all_files['summary']['total_size_gb']} GB")
        print(f"Results saved to: {self.output_file}")
        
        return all_files

def main():
    parser = argparse.ArgumentParser(description='Identify non-essential files for NAS migration')
    parser.add_argument('--output', '-o', default='non_essential_files.json',
                        help='Output file for results (default: non_essential_files.json)')
    parser.add_argument('--older-than', '-t', type=int, default=30,
                        help='Consider files older than N days (default: 30)')
    parser.add_argument('--min-size', '-s', type=int, default=10,
                        help='Minimum file size in MB to consider (default: 10)')
    
    args = parser.parse_args()
    
    analyzer = FileAnalyzer(
        output_file=args.output,
        older_than_days=args.older_than,
        min_size_mb=args.min_size
    )
    
    try:
        analyzer.identify_non_essential_files()
    except KeyboardInterrupt:
        print("\nScan interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"Error during scan: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()