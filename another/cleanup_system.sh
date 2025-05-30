#!/bin/bash

# macOS System Cleanup Script
# Safely removes temporary files, caches, logs, and other unnecessary data
# Author: Claude Code
# Version: 1.1

# set -e  # Exit on any error (제거됨)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
TOTAL_CLEANED=0
DRY_RUN=false

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to get directory size in bytes
get_size() {
    local path="$1"
    if [[ -d "$path" ]]; then
        du -sk "$path" 2>/dev/null | awk '{print $1*1024}' || echo "0"
    else
        echo "0"
    fi
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [[ $bytes -eq 0 ]]; then
        echo "0 B"
    elif [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(($bytes / 1024)) KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(($bytes / 1048576)) MB"
    else
        echo "$(($bytes / 1073741824)) GB"
    fi
}

# Function to show disk usage
show_disk_usage() {
    print_color $BLUE "=== Disk Usage ==="
    df -h / | head -2
    echo
}

# Function to clean directory safely
clean_directory() {
    local dir="$1"
    local description="$2"
    local exclude_pattern="$3"
    
    if [[ ! -d "$dir" ]]; then
        print_color $YELLOW "Directory $dir does not exist, skipping..."
        return 0
    fi
    
    local size_before=$(get_size "$dir")
    print_color $BLUE "Cleaning $description ($dir)..."
    
    if [[ $DRY_RUN == true ]]; then
        print_color $YELLOW "DRY RUN: Would clean $description"
        if [[ -n "$exclude_pattern" ]]; then
            find "$dir" -type f ! -path "$exclude_pattern" 2>/dev/null | wc -l | xargs echo "Files to clean:"
        else
            find "$dir" -type f 2>/dev/null | wc -l | xargs echo "Files to clean:"
        fi
    else
        if [[ -n "$exclude_pattern" ]]; then
            find "$dir" -type f ! -path "$exclude_pattern" -delete 2>/dev/null || true
        else
            find "$dir" -type f -delete 2>/dev/null || true
        fi
        # Remove empty directories
        find "$dir" -type d -empty -delete 2>/dev/null || true
    fi
    
    local size_after=$(get_size "$dir")
    local cleaned=$((size_before - size_after))
    TOTAL_CLEANED=$((TOTAL_CLEANED + cleaned))
    
    print_color $GREEN "Cleaned $(format_bytes $cleaned) from $description"
    echo
}

# Function to clean user caches
clean_user_caches() {
    print_color $YELLOW "=== Cleaning User Caches ==="
    
    # User Library Caches
    clean_directory "$HOME/Library/Caches" "User Library Caches"
    
    # User Application Support caches
    if [[ -d "$HOME/Library/Application Support" ]]; then
        find "$HOME/Library/Application Support" -name "*cache*" -type d 2>/dev/null | while read -r cache_dir; do
            clean_directory "$cache_dir" "App Support Cache: $(basename "$cache_dir")"
        done
    fi
}

# Function to clean system caches
clean_system_caches() {
    print_color $YELLOW "=== Cleaning System Caches ==="
    
    # System-wide caches (requires sudo)
    if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
        sudo find /Library/Caches -type f -delete 2>/dev/null || true
        sudo find /System/Library/Caches -type f -delete 2>/dev/null || true
        print_color $GREEN "Cleaned system caches"
    else
        print_color $YELLOW "Skipping system caches (requires sudo)"
    fi
}

# Function to clean logs
clean_logs() {
    print_color $YELLOW "=== Cleaning Log Files ==="
    
    # User logs
    clean_directory "$HOME/Library/Logs" "User Logs"
    
    # System logs (requires sudo)
    if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
        # Keep recent logs (last 7 days)
        sudo find /var/log -name "*.log" -mtime +7 -delete 2>/dev/null || true
        sudo find /var/log -name "*.log.*" -delete 2>/dev/null || true
        print_color $GREEN "Cleaned system logs"
    else
        print_color $YELLOW "Skipping system logs (requires sudo)"
    fi
    
    # Console logs
    if [[ -d "$HOME/Library/Logs/DiagnosticReports" ]]; then
        clean_directory "$HOME/Library/Logs/DiagnosticReports" "Diagnostic Reports"
    fi
}

# Function to clean temporary files
clean_temp_files() {
    print_color $YELLOW "=== Cleaning Temporary Files ==="
    
    # User temp files
    clean_directory "$TMPDIR" "User Temp Directory"
    
    # System temp files (requires sudo)
    if [[ $EUID -eq 0 ]] || sudo -n true 2>/dev/null; then
        sudo find /tmp -type f -mtime +1 -delete 2>/dev/null || true
        sudo find /var/tmp -type f -mtime +1 -delete 2>/dev/null || true
        print_color $GREEN "Cleaned system temp files"
    else
        print_color $YELLOW "Skipping system temp files (requires sudo)"
    fi
}

# Function to clean browser caches
clean_browser_caches() {
    print_color $YELLOW "=== Cleaning Browser Caches ==="
    
    # Safari
    if [[ -d "$HOME/Library/Caches/com.apple.Safari" ]]; then
        clean_directory "$HOME/Library/Caches/com.apple.Safari" "Safari Cache"
    fi
    
    # Chrome
    if [[ -d "$HOME/Library/Caches/Google/Chrome" ]]; then
        clean_directory "$HOME/Library/Caches/Google/Chrome" "Chrome Cache"
    fi
    
    # Firefox
    if [[ -d "$HOME/Library/Caches/Firefox" ]]; then
        clean_directory "$HOME/Library/Caches/Firefox" "Firefox Cache"
    fi
    
    # Edge
    if [[ -d "$HOME/Library/Caches/com.microsoft.edgemac" ]]; then
        clean_directory "$HOME/Library/Caches/com.microsoft.edgemac" "Edge Cache"
    fi
}

# Function to clean downloads
clean_downloads() {
    print_color $YELLOW "=== Cleaning Downloads ==="
    
    local downloads_dir="$HOME/Downloads"
    if [[ -d "$downloads_dir" ]]; then
        print_color $BLUE "Found $(find "$downloads_dir" -type f | wc -l | xargs) files in Downloads"
        read -p "Remove files older than 30 days from Downloads? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local size_before=$(get_size "$downloads_dir")
            find "$downloads_dir" -type f -mtime +30 -delete 2>/dev/null || true
            local size_after=$(get_size "$downloads_dir")
            local cleaned=$((size_before - size_after))
            TOTAL_CLEANED=$((TOTAL_CLEANED + cleaned))
            print_color $GREEN "Cleaned $(format_bytes $cleaned) from Downloads"
        fi
    fi
}

# Function to clean trash
clean_trash() {
    print_color $YELLOW "=== Cleaning Trash ==="
    
    local trash_dir="$HOME/.Trash"
    if [[ -d "$trash_dir" ]]; then
        local size_before=$(get_size "$trash_dir")
        if [[ $DRY_RUN == true ]]; then
            print_color $YELLOW "DRY RUN: Would empty trash"
        else
            rm -rf "$trash_dir"/* 2>/dev/null || true
        fi
        local size_after=$(get_size "$trash_dir")
        local cleaned=$((size_before - size_after))
        TOTAL_CLEANED=$((TOTAL_CLEANED + cleaned))
        print_color $GREEN "Cleaned $(format_bytes $cleaned) from Trash"
    fi
}

# Function to clean development caches
clean_dev_caches() {
    print_color $YELLOW "=== Cleaning Development Caches ==="
    
    # Node.js npm cache
    if command -v npm >/dev/null 2>&1; then
        local npm_cache=$(npm config get cache 2>/dev/null || echo "$HOME/.npm")
        if [[ -d "$npm_cache" ]]; then
            clean_directory "$npm_cache" "npm Cache"
        fi
    fi
    
    # Yarn cache
    if command -v yarn >/dev/null 2>&1; then
        local yarn_cache=$(yarn cache dir 2>/dev/null || echo "$HOME/.yarn/cache")
        if [[ -d "$yarn_cache" ]]; then
            clean_directory "$yarn_cache" "Yarn Cache"
        fi
    fi
    
    # pip cache
    if command -v pip >/dev/null 2>&1; then
        local pip_cache="$HOME/Library/Caches/pip"
        if [[ -d "$pip_cache" ]]; then
            clean_directory "$pip_cache" "pip Cache"
        fi
    fi
    
    # CocoaPods cache
    if command -v pod >/dev/null 2>&1; then
        local pods_cache="$HOME/Library/Caches/CocoaPods"
        if [[ -d "$pods_cache" ]]; then
            clean_directory "$pods_cache" "CocoaPods Cache"
        fi
    fi
    
    # Xcode derived data
    if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
        clean_directory "$HOME/Library/Developer/Xcode/DerivedData" "Xcode DerivedData"
    fi
    
    # Docker (if present)
    if command -v docker >/dev/null 2>&1; then
        print_color $BLUE "Docker found. Cleaning unused Docker data..."
        if [[ $DRY_RUN == false ]]; then
            print_color $YELLOW "Running docker system prune..."
            docker system prune -f
            print_color $GREEN "Docker system cleanup completed"
        else
            print_color $YELLOW "DRY RUN: Would clean Docker system data"
        fi
    fi
}

# Function to show menu
show_menu() {
    print_color $BLUE "=== macOS System Cleanup Script ==="
    echo "1. Clean User Caches"
    echo "2. Clean System Caches (requires sudo)"
    echo "3. Clean Log Files"
    echo "4. Clean Temporary Files"
    echo "5. Clean Browser Caches"
    echo "6. Clean Downloads (files older than 30 days)"
    echo "7. Empty Trash"
    echo "8. Clean Development Caches"
    echo "9. Clean All (1-8)"
    echo "10. Dry Run (show what would be cleaned)"
    echo "0. Exit"
    echo
}

# 각 단계별 에러 핸들링 래퍼 함수 추가
run_step() {
    local step_name="$1"
    shift
    if ! "$@"; then
        print_color $RED "Error: ${step_name} 단계에서 에러가 발생했습니다. 다음 단계로 넘어갑니다."
    fi
}

# Function to run cleanup based on choice
run_cleanup() {
    local choice=$1
    case $choice in
        1) run_step "User Caches" clean_user_caches ;;
        2) run_step "System Caches" clean_system_caches ;;
        3) run_step "Log Files" clean_logs ;;
        4) run_step "Temporary Files" clean_temp_files ;;
        5) run_step "Browser Caches" clean_browser_caches ;;
        6) run_step "Downloads" clean_downloads ;;
        7) run_step "Trash" clean_trash ;;
        8) run_step "Development Caches" clean_dev_caches ;;
        9)
            run_step "User Caches" clean_user_caches
            run_step "System Caches" clean_system_caches
            run_step "Log Files" clean_logs
            run_step "Temporary Files" clean_temp_files
            run_step "Browser Caches" clean_browser_caches
            run_step "Downloads" clean_downloads
            run_step "Trash" clean_trash
            run_step "Development Caches" clean_dev_caches
            ;;
        10)
            DRY_RUN=true
            run_step "User Caches" clean_user_caches
            run_step "System Caches" clean_system_caches
            run_step "Log Files" clean_logs
            run_step "Temporary Files" clean_temp_files
            run_step "Browser Caches" clean_browser_caches
            run_step "Downloads" clean_downloads
            run_step "Trash" clean_trash
            run_step "Development Caches" clean_dev_caches
            ;;
        0) exit 0 ;;
        *) print_color $RED "Invalid option" ;;
    esac
}

# Main function
main() {
    print_color $GREEN "Starting macOS System Cleanup..."
    echo
    
    # Show initial disk usage
    print_color $BLUE "=== Before Cleanup ==="
    show_disk_usage
    
    # Check if running with arguments
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --dry-run)
                DRY_RUN=true
                run_cleanup 9
                ;;
            --all)
                run_cleanup 9
                ;;
            --help|-h)
                echo "Usage: $0 [--dry-run|--all|--help]"
                echo "  --dry-run: Show what would be cleaned without actually cleaning"
                echo "  --all: Run all cleanup operations"
                echo "  --help: Show this help message"
                exit 0
                ;;
            *)
                print_color $RED "Unknown option: $1"
                exit 1
                ;;
        esac
    else
        # Interactive mode
        while true; do
            show_menu
            read -p "Enter your choice (0-10): " choice
            echo
            
            if [[ "$choice" == "0" ]]; then
                break
            fi
            
            run_cleanup "$choice"
            
            print_color $BLUE "Press Enter to continue..."
            read
            clear
        done
    fi
    
    # Show final results
    echo
    print_color $GREEN "=== Cleanup Complete ==="
    print_color $GREEN "Total space cleaned: $(format_bytes $TOTAL_CLEANED)"
    echo
    
    # Show final disk usage
    print_color $BLUE "=== After Cleanup ==="
    show_disk_usage
    
    print_color $GREEN "Cleanup finished successfully!"
}

# Run main function
main "$@"