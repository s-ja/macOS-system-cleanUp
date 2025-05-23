⏺ Created a comprehensive system cleanup script! Here's what it includes:

🧹 Cleanup Operations:

- User & system caches
- Log files (keeping recent ones)
- Temporary files
- Browser data
- Old downloads (30+ days)
- Trash emptying
- Development caches (npm, Docker, etc.)

💾 Storage Analysis:

- Shows disk usage before/after
- Calculates space freed per operation
- Total cleanup summary

🛡️ Safety Features:

- Dry-run mode to preview changes
- Interactive confirmations
- Excludes critical system files
- Error handling

Usage:

# Interactive mode

./cleanup_system.sh

# Clean everything automatically

./cleanup_system.sh --all

# Preview what would be cleaned

./cleanup_system.sh --dry-run

The script is now ready to use and will help optimize your storage space
safely.
