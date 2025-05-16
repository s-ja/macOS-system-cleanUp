# Installation Guide

## Prerequisites

- macOS operating system
- Bash shell
- Homebrew package manager
- Internet connection

## Basic Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/macos-system-cleanup.git
   cd macos-system-cleanup
   ```

2. Make scripts executable:

   ```bash
   chmod +x src/cleanup/system_cleanup.sh
   chmod +x src/upgrade/system_upgrade.sh
   ```

3. (Optional) Create symbolic links:
   ```bash
   sudo ln -s $(pwd)/src/cleanup/system_cleanup.sh /usr/local/bin/system_cleanup
   sudo ln -s $(pwd)/src/upgrade/system_upgrade.sh /usr/local/bin/system_upgrade
   ```

## Permission Setup

Ensure proper permissions for:

- Homebrew directories
- System cache directories
- Temporary directories

## Environment Setup

1. Verify Homebrew installation:

   ```bash
   brew doctor
   ```

2. Install required dependencies:

   ```bash
   brew install ruby
   ```

3. Configure shell environment:
   ```bash
   echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```
