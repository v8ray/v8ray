#!/bin/bash
# V8Ray Code Quality Check Script
# This script runs all code quality checks for both Rust and Flutter code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
FIX=false
RUST_ONLY=false
FLUTTER_ONLY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX=true
            shift
            ;;
        --rust)
            RUST_ONLY=true
            shift
            ;;
        --flutter)
            FLUTTER_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--fix] [--rust] [--flutter]"
            echo "  --fix      Fix formatting issues automatically"
            echo "  --rust     Run only Rust checks"
            echo "  --flutter  Run only Flutter checks"
            echo "  --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

function print_color() {
    printf "${1}${2}${NC}\n"
}

function print_section() {
    echo ""
    print_color $BLUE "=== $1 ==="
}

function check_command() {
    if ! command -v $1 &> /dev/null; then
        print_color $RED "Error: $1 is not installed or not in PATH"
        exit 1
    fi
}

# Check if we should run all checks
RUN_ALL=true
if [ "$RUST_ONLY" = true ] || [ "$FLUTTER_ONLY" = true ]; then
    RUN_ALL=false
fi

print_color $GREEN "V8Ray Code Quality Check"
echo "Fix mode: $FIX"
echo ""

# Rust checks
if [ "$RUST_ONLY" = true ] || [ "$RUN_ALL" = true ]; then
    print_section "Rust Code Quality Checks"
    
    # Check if cargo is available
    check_command "cargo"
    
    cd core
    
    # Format check
    print_color $YELLOW "Checking Rust code formatting..."
    if [ "$FIX" = true ]; then
        cargo fmt --all
        print_color $GREEN "✓ Rust code formatted"
    else
        cargo fmt --all -- --check
        print_color $GREEN "✓ Rust code formatting is correct"
    fi
    
    # Clippy check
    print_color $YELLOW "Running Clippy..."
    cargo clippy --all-targets --all-features -- -D warnings
    print_color $GREEN "✓ Clippy checks passed"
    
    # Build check
    print_color $YELLOW "Checking if code compiles..."
    cargo check --all-targets --all-features
    print_color $GREEN "✓ Code compiles successfully"
    
    # Test check
    print_color $YELLOW "Running Rust tests..."
    cargo test --all-features
    print_color $GREEN "✓ All Rust tests passed"
    
    cd ..
fi

# Flutter checks
if [ "$FLUTTER_ONLY" = true ] || [ "$RUN_ALL" = true ]; then
    print_section "Flutter Code Quality Checks"
    
    # Check if flutter is available
    check_command "flutter"
    
    cd app
    
    # Get dependencies
    print_color $YELLOW "Getting Flutter dependencies..."
    flutter pub get
    print_color $GREEN "✓ Dependencies updated"
    
    # Format check
    print_color $YELLOW "Checking Dart code formatting..."
    if [ "$FIX" = true ]; then
        dart format .
        print_color $GREEN "✓ Dart code formatted"
    else
        dart format --output=none --set-exit-if-changed .
        print_color $GREEN "✓ Dart code formatting is correct"
    fi
    
    # Analysis check
    print_color $YELLOW "Running Dart analyzer..."
    flutter analyze
    print_color $GREEN "✓ Dart analysis passed"
    
    # Test check
    print_color $YELLOW "Running Flutter tests..."
    flutter test
    print_color $GREEN "✓ All Flutter tests passed"
    
    cd ..
fi

print_section "All Checks Completed Successfully"
print_color $GREEN "🎉 All code quality checks passed!"

if [ "$FIX" = true ]; then
    print_color $YELLOW "Note: Code has been automatically formatted where possible."
fi
