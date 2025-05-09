#!/bin/bash

# system_cleanup.sh - Automated System Cleanup Script
# This script performs various system cleanup tasks to free up disk space
# and maintain system health.

# Print help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --help          Show this help message"
    echo "  --auto-clean    Run all cleanup operations without prompts"
    echo "  --dry-run       Show what would be cleaned without actually cleaning"
    echo "  --no-brew       Skip Homebrew cleanup"
    echo "  --no-npm        Skip npm cache cleanup"
    echo "  --no-docker     Skip Docker cleanup"
    echo "  --no-android    Skip Android Studio cleanup"
    echo
    echo "Example: $0 --auto-clean --no-docker"
    exit 0
}

# Process command line arguments
DRY_RUN=false
SKIP_BREW=false
SKIP_NPM=false
SKIP_DOCKER=false
SKIP_ANDROID=false

for arg in "$@"; do
    case $arg in
        --help)
            show_help
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --no-brew)
            SKIP_BREW=true
            ;;
        --no-npm)
            SKIP_NPM=true
            ;;
        --no-docker)
            SKIP_DOCKER=true
            ;;
        --no-android)
            SKIP_ANDROID=true
            ;;
    esac
done

# Set up logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/cleanup_$(date +"%Y%m%d_%H%M%S").log"

# Create the log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "ERROR: $error_message" | tee -a "$LOG_FILE"
    echo "Continuing with next task..." | tee -a "$LOG_FILE"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | tee -a "$LOG_FILE"
}

# Function to calculate total space saved
calculate_space_saved() {
    local before=$1
    local after=$2
    
    if [[ $before =~ ^[0-9]+$ ]] && [[ $after =~ ^[0-9]+$ ]]; then
        local saved=$((after - before))
        if [ $saved -ge 1073741824 ]; then
            echo "$(echo "scale=2; $saved/1073741824" | bc)GB"
        elif [ $saved -ge 1048576 ]; then
            echo "$(echo "scale=2; $saved/1048576" | bc)MB"
        elif [ $saved -ge 1024 ]; then
            echo "$(echo "scale=2; $saved/1024" | bc)KB"
        else
            echo "${saved}B"
        fi
    else
        echo "Unable to calculate"
    fi
}

# Function to format disk space
format_disk_space() {
    local space=$1
    if [ $space -ge 1073741824 ]; then
        echo "$(echo "scale=2; $space/1073741824" | bc)GB"
    elif [ $space -ge 1048576 ]; then
        echo "$(echo "scale=2; $space/1048576" | bc)MB"
    elif [ $space -ge 1024 ]; then
        echo "$(echo "scale=2; $space/1024" | bc)KB"
    else
        echo "${space}B"
    fi
}

# Start logging
log_message "Starting system cleanup process"
log_message "========================================="

# Record initial system state
INITIAL_FREE_SPACE=$(df -k / | awk 'NR==2 {print $4}')
log_message "Initial free space: $(df -h / | awk 'NR==2 {print $4}')"

# Section 1: System Overview
log_message "SECTION 1: System Overview"
df -h / | tee -a "$LOG_FILE"
log_message "----------------------------------------"

# Section 2: System Library and Cache Cleanup
log_message "SECTION 2: System Library and Cache Cleanup"

if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would clean system library caches and logs"
else
    # System library cache cleanup
    log_message "Checking system library cache cleanup permissions..."
    if [ "$(id -u)" = "0" ] || sudo -n true 2>/dev/null; then
        log_message "Cleaning system library caches..."
        if sudo rm -rf /Library/Caches/* 2>/dev/null; then
            log_message "Successfully cleaned system library caches"
        else
            handle_error "Failed to clean system library caches"
        fi
    else
        log_message "Skipping system library cache cleanup - requires root privileges"
        log_message "To enable this feature, run the script with sudo or enter your password when prompted"
    fi
    
    # System logs cleanup
    log_message "Checking system logs cleanup permissions..."
    if [ "$(id -u)" = "0" ] || sudo -n true 2>/dev/null; then
        log_message "Cleaning system logs..."
        # 보존해야 할 중요한 로그 파일들
        if sudo find /var/log -type f -not -name "system.log" -not -name "secure.log" -not -name "auth.log" -delete 2>/dev/null; then
            log_message "Successfully cleaned system logs (preserving critical logs)"
        else
            handle_error "Failed to clean system logs"
        fi
    else
        log_message "Skipping system logs cleanup - requires root privileges"
        log_message "To enable this feature, run the script with sudo or enter your password when prompted"
    fi
    
    # User library cache cleanup
    log_message "Checking user library cache cleanup permissions..."
    if [ -w "$HOME/Library/Caches" ]; then
        log_message "Cleaning user library caches..."
        if rm -rf ~/Library/Caches/* 2>/dev/null; then
            log_message "Successfully cleaned user library caches"
        else
            handle_error "Failed to clean user library caches"
        fi
    else
        log_message "Skipping user library cache cleanup - insufficient permissions"
    fi
    
    # Temporary items cleanup
    log_message "Checking temporary items cleanup permissions..."
    if [ -w "$HOME/Library/TemporaryItems" ] || sudo -n true 2>/dev/null; then
        log_message "Cleaning temporary items..."
        if sudo rm -rf ~/Library/TemporaryItems/* 2>/dev/null; then
            log_message "Successfully cleaned temporary items"
        else
            handle_error "Failed to clean temporary items"
        fi
    else
        log_message "Skipping temporary items cleanup - insufficient permissions"
        log_message "To enable this feature, run the script with sudo or enter your password when prompted"
    fi
fi

log_message "----------------------------------------"

# Section 3: Time Machine Local Snapshots
log_message "SECTION 3: Time Machine Local Snapshots"

if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would check and manage Time Machine local snapshots"
else
    if command -v tmutil &>/dev/null; then
        # List local snapshots
        log_message "Checking Time Machine local snapshots..."
        local_snapshots=$(tmutil listlocalsnapshots / 2>/dev/null)
        
        if [ -n "$local_snapshots" ]; then
            log_message "Found the following local snapshots:"
            echo "$local_snapshots" | tee -a "$LOG_FILE"
            
            # Check if we have sudo privileges
            if ! sudo -n true 2>/dev/null; then
                log_message "WARNING: sudo privileges required for removing local snapshots"
                log_message "Please run the script with sudo or enter your password when prompted"
            fi
            
            if [[ "$1" == "--auto-clean" ]]; then
                log_message "Auto-cleaning local snapshots..."
                if sudo tmutil thinlocalsnapshots / 9999999999999999 1 2>&1 | tee -a "$LOG_FILE"; then
                    log_message "Successfully removed local snapshots"
                else
                    handle_error "Failed to remove local snapshots - sudo privileges may be required"
                fi
            else
                read -p "Would you like to remove local snapshots? (y/n): " remove_snapshots
                if [[ "$remove_snapshots" == "y" || "$remove_snapshots" == "Y" ]]; then
                    log_message "Removing local snapshots..."
                    if sudo tmutil thinlocalsnapshots / 9999999999999999 1 2>&1 | tee -a "$LOG_FILE"; then
                        log_message "Successfully removed local snapshots"
                    else
                        handle_error "Failed to remove local snapshots - sudo privileges may be required"
                    fi
                else
                    log_message "Skipping local snapshots cleanup"
                fi
            fi
        else
            log_message "No local snapshots found"
        fi
    else
        log_message "tmutil command not found, skipping Time Machine cleanup"
    fi
fi

log_message "----------------------------------------"

# Section 4: Development Tools Cleanup
log_message "SECTION 4: Development Tools Cleanup"

# Subsection 4.1: Homebrew Cleanup
if [ "$SKIP_BREW" = true ]; then
    log_message "Skipping Homebrew cleanup (--no-brew flag detected)"
else
    if command -v brew &>/dev/null; then
        # Get initial size of Homebrew cache
        brew_cache_dir=$(brew --cache)
        brew_cache_size_before=$(du -sh "$brew_cache_dir" 2>/dev/null | awk '{print $1}')
        log_message "Homebrew cache size before cleaning: $brew_cache_size_before"
        
        if [ "$DRY_RUN" = true ]; then
            log_message "DRY RUN: Would update Homebrew and installed packages"
            log_message "DRY RUN: Would run brew doctor"
            log_message "DRY RUN: Would check for outdated packages"
            log_message "DRY RUN: Would remove unused dependencies"
            log_message "DRY RUN: Would clean up Homebrew cache and old versions"
        else
            # Update Homebrew and upgrade all installed packages
            log_message "Updating Homebrew and upgrading installed packages..."
            brew update 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to update Homebrew"
            brew upgrade 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to upgrade packages"
            
            # Run brew doctor to check for potential problems
            log_message "Running brew doctor to check for potential problems..."
            brew doctor 2>&1 | tee -a "$LOG_FILE" || handle_error "Brew doctor check failed"
            
            # Check for outdated packages
            log_message "Checking for outdated packages..."
            brew outdated 2>&1 | tee -a "$LOG_FILE"
            
            # Check for unused dependencies
            log_message "Checking for unused dependencies..."
            brew autoremove -n 2>&1 | tee -a "$LOG_FILE"
            
            if [[ "$1" == "--auto-clean" ]]; then
                log_message "Auto-removing unused dependencies..."
                brew autoremove 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to remove unused dependencies"
            fi
            
            # Clean up Homebrew
            log_message "Cleaning up Homebrew cache and old versions..."
            brew cleanup --prune=all 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Homebrew"
            
            # Get cache size after cleaning
            brew_cache_size_after=$(du -sh "$brew_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "Homebrew cache size after cleaning: $brew_cache_size_after"
        fi
    else
        log_message "Homebrew is not installed on this system"
    fi
fi

# Subsection 4.2: npm Cleanup
if [ "$SKIP_NPM" = true ]; then
    log_message "Skipping npm cache cleanup (--no-npm flag detected)"
else
    if command -v npm &>/dev/null; then
        # Get npm cache size before cleaning
        npm_cache_dir=$(npm config get cache)
        if [ -d "$npm_cache_dir" ]; then
            npm_cache_size_before=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "npm cache size before cleaning: $npm_cache_size_before"
            
            if [ "$DRY_RUN" = true ]; then
                log_message "DRY RUN: Would clean npm cache"
                log_message "DRY RUN: Would free approximately $npm_cache_size_before"
            else
                # Clean npm cache with verification
                log_message "Cleaning npm cache..."
                if npm cache clean --force 2>&1 | tee -a "$LOG_FILE"; then
                    # Verify cache was actually cleaned
                    npm_cache_size_after=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
                    log_message "npm cache size after cleaning: $npm_cache_size_after"
                    
                    if [ "$npm_cache_size_after" = "$npm_cache_size_before" ]; then
                        log_message "WARNING: npm cache size did not change. This might indicate a permission issue."
                    fi
                else
                    handle_error "Failed to clean npm cache"
                fi
                
                # Check for global packages and prune if auto-clean is enabled
                if [[ "$1" == "--auto-clean" ]]; then
                    log_message "Checking for outdated and unused global npm packages..."
                    
                    # Get list of global packages
                    global_packages=$(npm list -g --depth=0 2>/dev/null)
                    
                    # Check for outdated packages
                    npm_outdated=$(npm outdated -g 2>/dev/null)
                    if [ -n "$npm_outdated" ]; then
                        log_message "Found outdated global packages:"
                        echo "$npm_outdated" | tee -a "$LOG_FILE"
                        
                        # Ask for confirmation before removing outdated packages
                        read -p "Would you like to update outdated global packages? (y/n): " update_global
                        if [[ "$update_global" == "y" || "$update_global" == "Y" ]]; then
                            log_message "Updating outdated global packages..."
                            if npm update -g 2>&1 | tee -a "$LOG_FILE"; then
                                log_message "Successfully updated global packages"
                            else
                                handle_error "Failed to update global packages"
                            fi
                        fi
                    else
                        log_message "No outdated global packages found"
                    fi
                    
                    # Check for unused packages
                    log_message "Checking for unused global packages..."
                    if npm prune -g --dry-run 2>&1 | tee -a "$LOG_FILE"; then
                        read -p "Would you like to remove unused global packages? (y/n): " prune_global
                        if [[ "$prune_global" == "y" || "$prune_global" == "Y" ]]; then
                            log_message "Removing unused global packages..."
                            if npm prune -g 2>&1 | tee -a "$LOG_FILE"; then
                                log_message "Successfully removed unused global packages"
                            else
                                handle_error "Failed to remove unused global packages"
                            fi
                        fi
                    fi
                fi
            fi
        else
            log_message "npm cache directory not found"
        fi
    else
        log_message "npm is not installed on this system"
    fi
fi

# Subsection 4.3: Yarn Cache Cleanup
if command -v yarn &>/dev/null; then
    log_message "Yarn is installed. Checking cache..."
    
    # Get yarn cache directory
    yarn_cache_dir=$(yarn cache dir 2>/dev/null)
    
    if [ -d "$yarn_cache_dir" ]; then
        yarn_cache_size=$(du -sh "$yarn_cache_dir" 2>/dev/null | awk '{print $1}')
        log_message "Yarn cache size: $yarn_cache_size"
        
        if [ "$DRY_RUN" = true ]; then
            log_message "DRY RUN: Would clean Yarn cache"
        elif [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning Yarn cache..."
            yarn cache clean 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Yarn cache"
            
            # Verify cleaning was successful
            yarn_cache_size_after=$(du -sh "$yarn_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "Yarn cache size after cleaning: $yarn_cache_size_after"
        else
            read -p "Would you like to clean the Yarn cache? (y/n): " yarn_clean
            if [[ "$yarn_clean" == "y" || "$yarn_clean" == "Y" ]]; then
                log_message "Cleaning Yarn cache..."
                yarn cache clean 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Yarn cache"
            else
                log_message "Skipping Yarn cache cleanup"
            fi
        fi
    else
        log_message "Yarn cache directory not found"
    fi
else
    log_message "Yarn is not installed on this system"
fi

# Subsection 4.4: node_modules Cleanup
log_message "Checking for large node_modules directories..."

# Find large node_modules directories
if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would scan for large node_modules directories"
else
    # Find top 10 largest node_modules directories
    large_dirs=$(find "$HOME" -type d -name "node_modules" -not -path "*/\.*" -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)
    
    if [ -n "$large_dirs" ]; then
        log_message "Found the following large node_modules directories:"
        echo "$large_dirs" | tee -a "$LOG_FILE"
        
        if [[ "$1" == "--auto-clean" ]]; then
            log_message "Checking for unused node_modules (projects not modified in last 90 days)..."
            
            # Find project directories with node_modules that haven't been modified in over 90 days
            old_projects=$(find "$HOME" -type d -name "node_modules" -not -path "*/\.*" -mtime +90 -exec dirname {} \; 2>/dev/null)
            
            if [ -n "$old_projects" ]; then
                log_message "Found the following potentially unused projects (not modified in 90+ days):"
                echo "$old_projects" | tee -a "$LOG_FILE"
                log_message "You may want to consider removing these manually."
            else
                log_message "No potentially unused node_modules directories found."
            fi
        fi
    else
        log_message "No large node_modules directories found."
    fi
fi

# Subsection 4.5: Docker Cleanup
if [ "$SKIP_DOCKER" = true ]; then
    log_message "Skipping Docker cleanup (--no-docker flag detected)"
else
    if command -v docker &>/dev/null; then
        log_message "Docker is installed. Checking Docker disk usage..."
        docker system df 2>&1 | tee -a "$LOG_FILE"
        
        if [ "$DRY_RUN" = true ]; then
            # Dry run mode - show what would be cleaned
            log_message "DRY RUN: Would clean the following Docker resources:"
            docker images --filter "dangling=true" --format "{{.Repository}}:{{.Tag}} ({{.Size}})" 2>/dev/null | tee -a "$LOG_FILE"
            docker ps -a --filter "status=exited" --format "{{.Names}} ({{.Image}})" 2>/dev/null | tee -a "$LOG_FILE"
            docker volume ls --filter "dangling=true" --format "{{.Name}}" 2>/dev/null | tee -a "$LOG_FILE"
        elif [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning Docker resources (--auto-clean flag detected)..."
            docker_before=$(docker system df --format '{{.TotalSize}}' 2>/dev/null)
            docker system prune -af 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Docker resources"
            docker volume prune -f 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Docker volumes"
            docker_after=$(docker system df --format '{{.TotalSize}}' 2>/dev/null)
            log_message "Docker cleanup complete. Space reclaimed: $((docker_before - docker_after)) bytes"
        else
            read -p "Would you like to clean unused Docker resources? (y/n): " docker_clean
            if [[ "$docker_clean" == "y" || "$docker_clean" == "Y" ]]; then
                log_message "Cleaning Docker resources..."
                docker system prune -f 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Docker resources"
                
                read -p "Also clean unused Docker volumes? This will delete ALL volumes not used by at least one container (y/n): " docker_vol_clean
                if [[ "$docker_vol_clean" == "y" || "$docker_vol_clean" == "Y" ]]; then
                    log_message "Cleaning Docker volumes..."
                    docker volume prune -f 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Docker volumes"
                else
                    log_message "Skipping Docker volumes cleanup"
                fi
            else
                log_message "Skipping Docker cleanup"
            fi
        fi
    else
        log_message "Docker is not installed on this system"
    fi
fi

# Subsection 4.6: Android Studio Cleanup
if [ "$SKIP_ANDROID" = true ]; then
    log_message "Skipping Android Studio cleanup (--no-android flag detected)"
else
    if [ -d "$HOME/Library/Android" ] || [ -d "$HOME/Android" ]; then
        log_message "Android Studio is installed. Checking for cleanable files..."
        
        # 1. Calculate sizes before cleaning
        # Gradle caches
        if [ -d "$HOME/.gradle/caches" ]; then
            gradle_cache_size=$(du -sh "$HOME/.gradle/caches" 2>/dev/null | awk '{print $1}')
            log_message "Gradle cache size: $gradle_cache_size"
        fi
        
        # Android build directories
        android_builds=$(find "$HOME" -type d -name "build" -path "*/app/build" 2>/dev/null)
        if [ -n "$android_builds" ]; then
            build_size=$(du -ch $android_builds 2>/dev/null | grep total$ | cut -f1)
            log_message "Android build directories total size: $build_size"
        fi
        
        # Android SDK temp files
        if [ -d "$HOME/Library/Android/sdk/temp" ]; then
            sdk_temp_size=$(du -sh "$HOME/Library/Android/sdk/temp" 2>/dev/null | awk '{print $1}')
            log_message "Android SDK temp files size: $sdk_temp_size"
        fi
        
        # Check AVD directory size
        if [ -d "$HOME/.android/avd" ]; then
            avd_size=$(du -sh "$HOME/.android/avd" 2>/dev/null | awk '{print $1}')
            log_message "Android Virtual Device (AVD) files size: $avd_size"
            log_message "WARNING: AVD files will be preserved to maintain virtual device settings and data"
        fi
        
        # 2. Perform cleanups based on mode
        if [ "$DRY_RUN" = true ]; then
            log_message "DRY RUN: Would clean the following Android Studio related files:"
            log_message "DRY RUN: - Gradle caches older than 30 days"
            log_message "DRY RUN: - Android SDK temp files"
            log_message "DRY RUN: - Android build directories in inactive projects"
            log_message "DRY RUN: - AVD files will be preserved"
        elif [[ "$1" == "--auto-clean" ]]; then
            # Auto-clean mode - be careful with what we auto-clean
            log_message "Auto-cleaning Android Studio files..."
            
            # Clean Gradle cache - only files older than 30 days
            if [ -d "$HOME/.gradle/caches" ]; then
                log_message "Cleaning Gradle cache files older than 30 days..."
                if find "$HOME/.gradle/caches" -type f -atime +30 -delete 2>/dev/null; then
                    log_message "Successfully cleaned Gradle cache files"
                else
                    handle_error "Failed to clean Gradle cache files"
                fi
            fi
            
            # Clean Android SDK temp files - these are safe to remove
            if [ -d "$HOME/Library/Android/sdk/temp" ]; then
                log_message "Cleaning Android SDK temp files..."
                if rm -rf "$HOME/Library/Android/sdk/temp"/* 2>/dev/null; then
                    log_message "Successfully cleaned Android SDK temp files"
                else
                    handle_error "Failed to clean Android SDK temp files"
                fi
            fi
            
            # Note: We're NOT auto-cleaning AVD files as requested
            log_message "Skipping Android Virtual Devices (AVD) to preserve settings and data"
            
            # Note: We're being cautious with build directories - only suggest them
            if [ -n "$android_builds" ]; then
                log_message "Found the following Android build directories you may want to clean manually:"
                echo "$android_builds" | tee -a "$LOG_FILE"
            fi
            
            # AVD 파일 보호 강화
            log_message "Preserving Android Virtual Device (AVD) files..."
            if [ -d "$HOME/.android/avd" ]; then
                log_message "AVD directory found: $HOME/.android/avd"
                log_message "AVD files will be preserved to maintain virtual device settings and data"
            fi
        else
            # Interactive mode
            if [ -d "$HOME/.gradle/caches" ]; then
                read -p "Clean Gradle cache files older than 30 days? (y/n): " gradle_clean
                if [[ "$gradle_clean" == "y" || "$gradle_clean" == "Y" ]]; then
                    log_message "Cleaning Gradle cache files older than 30 days..."
                    find "$HOME/.gradle/caches" -type f -atime +30 -delete 2>/dev/null
                else
                    log_message "Skipping Gradle cache cleanup"
                fi
            fi
            
            if [ -d "$HOME/Library/Android/sdk/temp" ]; then
                read -p "Clean Android SDK temp files? (y/n): " sdk_temp_clean
                if [[ "$sdk_temp_clean" == "y" || "$sdk_temp_clean" == "Y" ]]; then
                    log_message "Cleaning Android SDK temp files..."
                    rm -rf "$HOME/Library/Android/sdk/temp"/* 2>/dev/null
                else
                    log_message "Skipping Android SDK temp files cleanup"
                fi
            fi
            
            # For build directories, just suggest manual cleaning
            if [ -n "$android_builds" ]; then
                log_message "Found the following Android build directories you may want to clean manually:"
                echo "$android_builds" | tee -a "$LOG_FILE"
            fi
            
            # Important warning about AVD files
            log_message "WARNING: Android Virtual Device (AVD) files are NOT being cleaned to preserve settings and data"
            log_message "If you need to clean AVD files, please do so manually through Android Studio's AVD Manager"
        fi
        
        # 3. Show unused SDK packages if sdkmanager is available
        if command -v "$HOME/Library/Android/sdk/tools/bin/sdkmanager" &>/dev/null; then
            log_message "The following Android SDK packages may be outdated (check manually):"
            "$HOME/Library/Android/sdk/tools/bin/sdkmanager" --list | grep -E "installed|Installed" | tee -a "$LOG_FILE"
        fi
    else
        log_message "Android Studio not detected on this system"
    fi
fi

# Subsection 4.7: iOS Simulator Cleanup
if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would clean iOS Simulator caches and unused simulators"
else
    if command -v xcrun &>/dev/null; then
        # Clean simulator caches
        log_message "Cleaning iOS Simulator caches..."
        rm -rf ~/Library/Developer/CoreSimulator/Caches/* 2>/dev/null || handle_error "Failed to clean simulator caches"
        
        # Remove unavailable simulators
        log_message "Removing unavailable simulators..."
        xcrun simctl delete unavailable 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to remove unavailable simulators"
    else
        log_message "xcrun command not found, skipping simulator cleanup"
    fi
fi

log_message "----------------------------------------"

# Section 5: Application Cache Cleanup
log_message "SECTION 5: Application Cache Cleanup"

# Subsection 5.1: Check for large files in Application Support
log_message "Checking for large files in Application Support..."
large_app_support=$(find "$HOME/Library/Application Support" -type f -size +100M -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)

if [ -n "$large_app_support" ]; then
    log_message "Found the following large files in Application Support:"
    echo "$large_app_support" | tee -a "$LOG_FILE"
    log_message "NOTE: These files may be important for your applications. Review manually before removing."
fi

# Subsection 5.2: XCode Cleanup
if [ -d "$HOME/Library/Developer/Xcode" ]; then
    log_message "XCode detected. Checking for cleanable files..."
    
    # Check DerivedData
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        derived_size=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | awk '{print $1}')
        log_message "XCode DerivedData size: $derived_size"
        
        if [ "$DRY_RUN" = false ] && ([[ "$1" == "--auto-clean" ]] || read -p "Clean XCode DerivedData? (y/n): " xcode_clean && [[ "$xcode_clean" == "y" || "$xcode_clean" == "Y" ]]); then
            log_message "Cleaning XCode DerivedData..."
            if rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null; then
                log_message "Successfully cleaned XCode DerivedData"
            else
                handle_error "Failed to clean XCode DerivedData"
            fi
        fi
    fi
    
    # Check iOS Device Support (can be very large)
    if [ -d "$HOME/Library/Developer/Xcode/iOS DeviceSupport" ]; then
        devicesupport_size=$(du -sh "$HOME/Library/Developer/Xcode/iOS DeviceSupport" 2>/dev/null | awk '{print $1}')
        log_message "iOS Device Support files size: $devicesupport_size"
        
        # This is a more cautious cleanup - only suggest, not auto-clean
        log_message "Consider manually removing old iOS device support files to free up space"
    fi
    
    # Check Archives
    if [ -d "$HOME/Library/Developer/Xcode/Archives" ]; then
        archives_size=$(du -sh "$HOME/Library/Developer/Xcode/Archives" 2>/dev/null | awk '{print $1}')
        log_message "XCode Archives size: $archives_size"
        
        if [ "$DRY_RUN" = false ] && ([[ "$1" == "--auto-clean" ]] || read -p "Clean old XCode Archives (older than 90 days)? (y/n): " archives_clean && [[ "$archives_clean" == "y" || "$archives_clean" == "Y" ]]); then
            log_message "Cleaning XCode Archives older than 90 days..."
            if find "$HOME/Library/Developer/Xcode/Archives" -type d -mtime +90 -exec rm -rf {} \; 2>/dev/null; then
                log_message "Successfully cleaned old XCode Archives"
            else
                handle_error "Failed to clean old XCode Archives"
            fi
        fi
    fi
else
    log_message "XCode not detected on this system"
fi

log_message "----------------------------------------"

# Section 6: System Files Cleanup
log_message "SECTION 6: System Files Cleanup"

# Subsection 6.1: .DS_Store Files Cleanup
log_message "Checking for .DS_Store files..."

if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would scan for and count .DS_Store files"
else
    # Count and calculate size of all .DS_Store files with progress
    total_found=0
    total_size=0
    
    # Find all .DS_Store files with progress
    while IFS= read -r -d '' file; do
        total_found=$((total_found + 1))
        file_size=$(du -k "$file" 2>/dev/null | cut -f1)
        total_size=$((total_size + file_size))
        
        # Show progress every 100 files
        if [ $((total_found % 100)) -eq 0 ]; then
            log_message "Found $total_found .DS_Store files so far..."
        fi
    done < <(find "$HOME" -name ".DS_Store" -type f -print0 2>/dev/null)
    
    if [ "$total_found" -gt 0 ]; then
        log_message "Found $total_found .DS_Store files, total size: $(numfmt --to=iec-i --suffix=B $((total_size * 1024)))"
        
        if [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning .DS_Store files..."
            if find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null; then
                log_message "Successfully removed .DS_Store files"
            else
                handle_error "Failed to remove .DS_Store files"
            fi
        else
            read -p "Would you like to remove all .DS_Store files? (y/n): " ds_clean
            if [[ "$ds_clean" == "y" || "$ds_clean" == "Y" ]]; then
                log_message "Removing .DS_Store files..."
                if find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null; then
                    log_message "Successfully removed .DS_Store files"
                else
                    handle_error "Failed to remove .DS_Store files"
                fi
            else
                log_message "Skipping .DS_Store cleanup"
            fi
        fi
    else
        log_message "No .DS_Store files found"
    fi
fi

# Subsection 6.2: macOS Language Resources
if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would check for unused language resources"
elif [[ "$1" == "--auto-clean" ]] || read -p "Would you like to check for unused language resources? (y/n): " lang_check && [[ "$lang_check" == "y" || "$lang_check" == "Y" ]]; then
    log_message "Checking for large language resource directories..."
    
    # Find top 10 largest localization directories
    large_locales=$(find /Applications -path "*.lproj" -type d -not -path "*/en.lproj" -not -path "*/Base.lproj" -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)
    
    if [ -n "$large_locales" ]; then
        log_message "Found the following large localization directories:"
        echo "$large_locales" | tee -a "$LOG_FILE"
        log_message "WARNING: Removing these may affect applications. Consider manual review."
    else
        log_message "No significant localization directories found."
    fi
fi

log_message "----------------------------------------"

# Section 7: Final Summary
log_message "SECTION 7: Final Summary"

# Calculate space saved
FINAL_FREE_SPACE=$(df -k / | awk 'NR==2 {print $4}')
SPACE_SAVED=$((FINAL_FREE_SPACE - INITIAL_FREE_SPACE))

# Check disk usage after cleanup
log_message "Initial disk free space: $(format_disk_space $((INITIAL_FREE_SPACE * 1024)))"
log_message "Final disk free space: $(format_disk_space $((FINAL_FREE_SPACE * 1024)))"
log_message "Total space saved: $(calculate_space_saved $INITIAL_FREE_SPACE $FINAL_FREE_SPACE)"

log_message "========================================="
log_message "System cleanup completed. Log saved to: $LOG_FILE"

# Provide some user guidance
echo ""
echo "Cleanup process completed!"
echo "Total space saved: $(calculate_space_saved $INITIAL_FREE_SPACE $FINAL_FREE_SPACE)"
echo ""
echo "For additional manual cleanup, consider:"
echo "1. Emptying the Trash (rm -rf ~/.Trash/*)"
echo "2. Cleaning browser caches"
echo "3. Removing unused applications"
echo "4. Checking Time Machine backups"
echo "5. Using tools like OmniDiskSweeper or GrandPerspective to find large files"
echo ""
echo "For additional options, run: $0 --help"
echo "Log file saved to: $LOG_FILE"

# Final system checks
if pgrep -x "Xcode" > /dev/null; then
    log_message "WARNING: XCode is running. Please close XCode before cleaning."
    exit 1
fi

log_message "Verifying system cache regeneration..."
sudo update_dyld_shared_cache 2>/dev/null || log_message "Cache regeneration may need manual intervention"