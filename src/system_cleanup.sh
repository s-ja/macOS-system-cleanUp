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
    local unit=$3
    
    if [[ $before =~ ^[0-9]+$ ]] && [[ $after =~ ^[0-9]+$ ]]; then
        echo "$((before - after))$unit"
    else
        echo "Unable to calculate"
    fi
}

# Start logging
log_message "Starting system cleanup process"
log_message "========================================="

# Record initial system state
INITIAL_FREE_SPACE=$(df -k / | awk 'NR==2 {print $4}')
log_message "Initial free space: $(df -h / | awk 'NR==2 {print $4}')"

# Section 1: Check disk usage
log_message "SECTION 1: Checking disk usage"
df -h / | tee -a "$LOG_FILE"
log_message "----------------------------------------"

# Section 2: Check user cache sizes
log_message "SECTION 2: Checking cache sizes"

# Check user Library cache
if [ -d "$HOME/Library/Caches" ]; then
    cache_size=$(du -sh "$HOME/Library/Caches" 2>/dev/null | awk '{print $1}')
    log_message "User Library cache size: $cache_size"
else
    log_message "User Library cache not found"
fi

# Check Downloads folder
if [ -d "$HOME/Downloads" ]; then
    downloads_size=$(du -sh "$HOME/Downloads" 2>/dev/null | awk '{print $1}')
    log_message "Downloads folder size: $downloads_size"
else
    log_message "Downloads folder not found"
fi

log_message "----------------------------------------"

# Section 3: Clean Homebrew
log_message "SECTION 3: Checking Homebrew"

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

log_message "----------------------------------------"

# Section 4: Clean npm cache
log_message "SECTION 4: Checking npm cache"

# Skip if --no-npm flag is used
if [ "$SKIP_NPM" = true ]; then
    log_message "Skipping npm cache cleanup (--no-npm flag detected)"
else
    # Check if npm is installed
    if command -v npm &>/dev/null; then
        # Get npm cache size before cleaning
        npm_cache_dir=$(npm config get cache)
        if [ -d "$npm_cache_dir" ]; then
            npm_cache_size_before=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
            log_message "npm cache size before cleaning: $npm_cache_size_before"
            
            if [ "$DRY_RUN" = true ]; then
                # Dry run mode
                log_message "DRY RUN: Would clean npm cache"
                
                # Show what would be removed
                npm_cache_size=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
                log_message "DRY RUN: Would free approximately $npm_cache_size"
            else
                # Clean npm cache
                log_message "Cleaning npm cache..."
                npm cache clean --force 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean npm cache"
                
                # Get npm cache size after cleaning
                npm_cache_size_after=$(du -sh "$npm_cache_dir" 2>/dev/null | awk '{print $1}')
                log_message "npm cache size after cleaning: $npm_cache_size_after"
                
                # Check for global packages and prune if auto-clean is enabled
                if [[ "$1" == "--auto-clean" ]]; then
                    log_message "Checking for outdated global npm packages..."
                    npm_outdated=$(npm outdated -g 2>/dev/null)
                    if [ -n "$npm_outdated" ]; then
                        log_message "Pruning outdated global npm packages..."
                        npm prune -g 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to prune npm packages"
                    else
                        log_message "No outdated global npm packages found"
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

log_message "----------------------------------------"

# Section 5: Check system logs
log_message "SECTION 5: Checking system logs"

# Check system log sizes (requires sudo)
log_message "System log sizes (requires sudo):"
sudo du -sh /var/log/* 2>/dev/null | tee -a "$LOG_FILE" || log_message "Could not access system logs (sudo may be required)"

log_message "----------------------------------------"

# Section 6: Check for Docker and clean if installed
log_message "SECTION 6: Checking Docker"

# Skip if --no-docker flag is used
if [ "$SKIP_DOCKER" = true ]; then
    log_message "Skipping Docker cleanup (--no-docker flag detected)"
else
    if command -v docker &>/dev/null; then
        log_message "Docker is installed. Checking Docker disk usage..."
        docker system df 2>&1 | tee -a "$LOG_FILE"
        
        if [ "$DRY_RUN" = true ]; then
            # Dry run mode - show what would be cleaned
            log_message "DRY RUN: Would clean the following Docker resources:"
            
            # Show unused images that would be removed
            log_message "DRY RUN: Unused images:"
            docker images --filter "dangling=true" --format "{{.Repository}}:{{.Tag}} ({{.Size}})" 2>/dev/null | tee -a "$LOG_FILE"
            
            # Show unused containers that would be removed
            log_message "DRY RUN: Stopped containers:"
            docker ps -a --filter "status=exited" --format "{{.Names}} ({{.Image}})" 2>/dev/null | tee -a "$LOG_FILE"
            
            # Show unused volumes that would be removed
            log_message "DRY RUN: Unused volumes:"
            docker volume ls --filter "dangling=true" --format "{{.Name}}" 2>/dev/null | tee -a "$LOG_FILE"
        
        # Make Docker cleanup non-interactive with a command line flag
        elif [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning Docker resources (--auto-clean flag detected)..."
            # Capture disk usage before cleaning
            docker_before=$(docker system df --format '{{.TotalSize}}' 2>/dev/null)
            
            # Perform Docker cleanup
            log_message "Cleaning Docker images, containers, and networks..."
            docker system prune -af 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Docker resources"
            
            # Include volume cleanup for more thorough cleaning
            log_message "Cleaning Docker volumes..."
            docker volume prune -f 2>&1 | tee -a "$LOG_FILE" || handle_error "Failed to clean Docker volumes"
            
            # Capture disk usage after cleaning
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
                fi
            else
                log_message "Skipping Docker cleanup"
            fi
        fi
    else
        log_message "Docker is not installed on this system"
    fi
fi

log_message "----------------------------------------"

# Section 7: Clean node_modules directories
log_message "SECTION 7: Checking for large node_modules directories"

# Function to find large node_modules directories
find_large_node_modules() {
    log_message "Searching for large node_modules directories..."
    
    # Find top 10 largest node_modules directories
    large_dirs=$(find "$HOME" -type d -name "node_modules" -not -path "*/\.*" -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)
    
    if [ -n "$large_dirs" ]; then
        log_message "Found the following large node_modules directories:"
        echo "$large_dirs" | tee -a "$LOG_FILE"
        
        if [ "$DRY_RUN" = false ] && [[ "$1" == "--auto-clean" ]]; then
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
}

# Only run if not in dry run mode or specifically requested
if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would scan for large node_modules directories"
else
    find_large_node_modules "$1"
fi

log_message "----------------------------------------"

# Section 8: Clean Yarn cache
log_message "SECTION 8: Checking Yarn cache"

# Check if yarn is installed
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

log_message "----------------------------------------"

# Section 9: Check for large .DS_Store files
log_message "SECTION 9: Checking for .DS_Store files"

if [ "$DRY_RUN" = true ]; then
    log_message "DRY RUN: Would scan for and count .DS_Store files"
else
    # Count and calculate size of all .DS_Store files with progress
    log_message "Scanning for .DS_Store files..."
    
    # Initialize counters
    total_found=0
    total_size=0
    
    # Find all .DS_Store files with progress
    while IFS= read -r -d '' file; do
        total_found=$((total_found + 1))
        file_size=$(du -h "$file" 2>/dev/null | cut -f1)
        total_size=$(echo "$total_size + $(du -k "$file" 2>/dev/null | cut -f1)" | bc)
        
        # Show progress every 100 files
        if [ $((total_found % 100)) -eq 0 ]; then
            log_message "Found $total_found .DS_Store files so far..."
        fi
    done < <(find "$HOME" -name ".DS_Store" -type f -print0)
    
    if [ "$total_found" -gt 0 ]; then
        log_message "Found $total_found .DS_Store files, total size: $(numfmt --to=iec-i --suffix=B $((total_size * 1024)))"
        
        if [[ "$1" == "--auto-clean" ]]; then
            log_message "Auto-cleaning .DS_Store files..."
            find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null
            log_message "Removed .DS_Store files"
        else
            read -p "Would you like to remove all .DS_Store files? (y/n): " ds_clean
            if [[ "$ds_clean" == "y" || "$ds_clean" == "Y" ]]; then
                log_message "Removing .DS_Store files..."
                find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null
                log_message "Removed .DS_Store files"
            else
                log_message "Skipping .DS_Store cleanup"
            fi
        fi
    else
        log_message "No .DS_Store files found"
    fi
fi

log_message "----------------------------------------"

# Section 10: Summary report
log_message "SECTION 10: Cleanup Summary"

# Section 11: Clean Android Studio files
log_message "SECTION 11: Checking Android Studio"

# Skip if --no-android flag is used (가정: 이 플래그를 추가할 경우)
if [ "$SKIP_ANDROID" = true ]; then
    log_message "Skipping Android Studio cleanup (--no-android flag detected)"
else
    # Check if Android Studio is installed
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
        
        # 2. Perform cleanups based on mode
        if [ "$DRY_RUN" = true ]; then
            # Dry run mode
            log_message "DRY RUN: Would clean the following Android Studio related files:"
            log_message "DRY RUN: - Gradle caches older than 30 days"
            log_message "DRY RUN: - Android SDK temp files"
            log_message "DRY RUN: - Android build directories in inactive projects"
            
        elif [[ "$1" == "--auto-clean" ]]; then
            # Auto-clean mode - be careful with what we auto-clean
            log_message "Auto-cleaning Android Studio files..."
            
            # Clean Gradle cache - only files older than 30 days
            if [ -d "$HOME/.gradle/caches" ]; then
                log_message "Cleaning Gradle cache files older than 30 days..."
                find "$HOME/.gradle/caches" -type f -atime +30 -delete 2>/dev/null
            fi
            
            # Clean Android SDK temp files - these are safe to remove
            if [ -d "$HOME/Library/Android/sdk/temp" ]; then
                log_message "Cleaning Android SDK temp files..."
                rm -rf "$HOME/Library/Android/sdk/temp"/* 2>/dev/null
            fi
            
            # Note: We're NOT auto-cleaning AVD files as requested
            log_message "Skipping Android Virtual Devices (AVD) to preserve settings and data"
            
            # Note: We're being cautious with build directories - only suggest them
            if [ -n "$android_builds" ]; then
                log_message "Found the following Android build directories you may want to clean manually:"
                echo "$android_builds" | tee -a "$LOG_FILE"
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


# Section 12: XCode cleanup (추가 섹션)
log_message "SECTION 12: Checking XCode related files"

if [ -d "$HOME/Library/Developer/Xcode" ]; then
    log_message "XCode detected. Checking for cleanable files..."
    
    # Check DerivedData
    if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then
        derived_size=$(du -sh "$HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null | awk '{print $1}')
        log_message "XCode DerivedData size: $derived_size"
        
        if [ "$DRY_RUN" = false ] && ([[ "$1" == "--auto-clean" ]] || read -p "Clean XCode DerivedData? (y/n): " xcode_clean && [[ "$xcode_clean" == "y" || "$xcode_clean" == "Y" ]]); then
            log_message "Cleaning XCode DerivedData..."
            rm -rf "$HOME/Library/Developer/Xcode/DerivedData"/* 2>/dev/null
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
            find "$HOME/Library/Developer/Xcode/Archives" -type d -mtime +90 -exec rm -rf {} \; 2>/dev/null
        fi
    fi
    
    # Check iOS Simulator caches
    if [ -d "$HOME/Library/Developer/CoreSimulator" ]; then
        simulator_size=$(du -sh "$HOME/Library/Developer/CoreSimulator" 2>/dev/null | awk '{print $1}')
        log_message "iOS Simulator files size: $simulator_size"
        
        if [ "$DRY_RUN" = false ] && ([[ "$1" == "--auto-clean" ]] || read -p "Delete unused iOS Simulators? (y/n): " simulator_clean && [[ "$simulator_clean" == "y" || "$simulator_clean" == "Y" ]]); then
            if command -v xcrun &>/dev/null; then
                log_message "Cleaning unused iOS Simulators..."
                xcrun simctl delete unavailable 2>&1 | tee -a "$LOG_FILE"
            else
                log_message "xcrun command not found, skipping simulator cleanup"
            fi
        fi
    fi
else
    log_message "XCode not detected on this system"
fi

# Section 13: macOS specific cleanup
log_message "SECTION 13: macOS specific cleanup"

# Check and clean Language resources (careful with this)
if [ "$DRY_RUN" = false ] && [[ "$1" == "--auto-clean" ]] || read -p "Would you like to check for unused language resources? (y/n): " lang_check && [[ "$lang_check" == "y" || "$lang_check" == "Y" ]]; then
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

# Check for large files in Application Support
log_message "Checking for large files in Application Support..."
large_app_support=$(find "$HOME/Library/Application Support" -type f -size +100M -exec du -sh {} \; 2>/dev/null | sort -hr | head -10)

if [ -n "$large_app_support" ]; then
    log_message "Found the following large files in Application Support:"
    echo "$large_app_support" | tee -a "$LOG_FILE"
    log_message "NOTE: These files may be important for your applications. Review manually before removing."
fi

# Clear system caches if requested with sudo
if [ "$DRY_RUN" = false ] && ([[ "$1" == "--auto-clean" ]] || read -p "Clear system caches (requires sudo)? (y/n): " syscache_clean && [[ "$syscache_clean" == "y" || "$syscache_clean" == "Y" ]]); then
    log_message "WARNING: System cache cleaning may affect system performance temporarily"
    log_message "Clearing system caches..."
    sudo rm -rf /Library/Caches/* 2>/dev/null
    sudo rm -rf /System/Library/Caches/* 2>/dev/null
    log_message "System caches cleared"
fi

# Check for sleepimage file (can be very large)
if [ -f "/private/var/vm/sleepimage" ]; then
    sleepimage_size=$(du -sh "/private/var/vm/sleepimage" 2>/dev/null | awk '{print $1}')
    log_message "Found sleepimage file, size: $sleepimage_size"
    log_message "WARNING: Modifying sleepimage may affect system sleep functionality. Proceed with caution."
fi
log_message "----------------------------------------"

# Calculate space saved
FINAL_FREE_SPACE=$(df -k / | awk 'NR==2 {print $4}')
SPACE_SAVED=$((FINAL_FREE_SPACE - INITIAL_FREE_SPACE))
SPACE_SAVED_MB=$((SPACE_SAVED / 1024))

# Check disk usage after cleanup
log_message "Initial disk free space: $(numfmt --to=iec-i --suffix=B $((INITIAL_FREE_SPACE * 1024)))"
log_message "Final disk free space: $(numfmt --to=iec-i --suffix=B $((FINAL_FREE_SPACE * 1024)))"
log_message "Total space saved: $(numfmt --to=iec-i --suffix=B $((SPACE_SAVED * 1024)))"

log_message "========================================="
log_message "System cleanup completed. Log saved to: $LOG_FILE"

# Provide some user guidance
echo ""
echo "Cleanup process completed!"
echo "Total space saved: $(numfmt --to=iec-i --suffix=B $((SPACE_SAVED * 1024)))"
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

if pgrep -x "Xcode" > /dev/null; then
    log_message "WARNING: XCode is running. Please close XCode before cleaning."
    exit 1
fi

log_message "Verifying system cache regeneration..."
sudo update_dyld_shared_cache 2>/dev/null || log_message "Cache regeneration may need manual intervention"