#!/bin/bash
# V8Ray Test Runner Script
# This script runs all tests for both Rust and Flutter code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RUST_ONLY=false
FLUTTER_ONLY=false
COVERAGE=false
INTEGRATION=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --rust)
            RUST_ONLY=true
            shift
            ;;
        --flutter)
            FLUTTER_ONLY=true
            shift
            ;;
        --coverage)
            COVERAGE=true
            shift
            ;;
        --integration)
            INTEGRATION=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--rust] [--flutter] [--coverage] [--integration] [--verbose]"
            echo "  --rust        Run only Rust tests"
            echo "  --flutter     Run only Flutter tests"
            echo "  --coverage    Generate coverage reports"
            echo "  --integration Run integration tests"
            echo "  --verbose     Enable verbose output"
            echo "  --help        Show this help message"
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

# Check if we should run all tests
RUN_ALL=true
if [ "$RUST_ONLY" = true ] || [ "$FLUTTER_ONLY" = true ]; then
    RUN_ALL=false
fi

print_color $GREEN "V8Ray Test Runner"
echo "Coverage mode: $COVERAGE"
echo "Integration tests: $INTEGRATION"
echo "Verbose mode: $VERBOSE"
echo ""

# Rust tests
if [ "$RUST_ONLY" = true ] || [ "$RUN_ALL" = true ]; then
    print_section "Rust Tests"
    
    # Check if cargo is available
    check_command "cargo"
    
    cd core
    
    # Unit tests
    print_color $YELLOW "Running Rust unit tests..."
    if [ "$VERBOSE" = true ]; then
        cargo test --lib --verbose
    else
        cargo test --lib
    fi
    print_color $GREEN "✓ Rust unit tests passed"
    
    # Integration tests
    if [ "$INTEGRATION" = true ]; then
        print_color $YELLOW "Running Rust integration tests..."
        if [ "$VERBOSE" = true ]; then
            cargo test --test integration_test --verbose
        else
            cargo test --test integration_test
        fi
        print_color $GREEN "✓ Rust integration tests passed"
    fi
    
    # Documentation tests
    print_color $YELLOW "Running Rust documentation tests..."
    if [ "$VERBOSE" = true ]; then
        cargo test --doc --verbose
    else
        cargo test --doc
    fi
    print_color $GREEN "✓ Rust documentation tests passed"
    
    # Benchmark tests (if available)
    print_color $YELLOW "Running Rust benchmark tests..."
    if [ "$VERBOSE" = true ]; then
        cargo test --benches --verbose
    else
        cargo test --benches
    fi
    print_color $GREEN "✓ Rust benchmark tests passed"
    
    # Coverage (if requested)
    if [ "$COVERAGE" = true ]; then
        print_color $YELLOW "Generating Rust test coverage..."
        
        # Check if cargo-tarpaulin is installed
        if ! command -v cargo-tarpaulin &> /dev/null; then
            print_color $YELLOW "Installing cargo-tarpaulin for coverage..."
            cargo install cargo-tarpaulin
        fi
        
        mkdir -p ../target/coverage/rust
        cargo tarpaulin --out Html --output-dir ../target/coverage/rust
        print_color $GREEN "✓ Rust coverage report generated in target/coverage/rust/"
    fi
    
    cd ..
fi

# Flutter tests
if [ "$FLUTTER_ONLY" = true ] || [ "$RUN_ALL" = true ]; then
    print_section "Flutter Tests"
    
    # Check if flutter is available
    check_command "flutter"
    
    cd app
    
    # Get dependencies first
    print_color $YELLOW "Getting Flutter dependencies..."
    flutter pub get
    
    # Unit and widget tests
    print_color $YELLOW "Running Flutter unit and widget tests..."
    if [ "$VERBOSE" = true ]; then
        flutter test --verbose
    else
        flutter test
    fi
    print_color $GREEN "✓ Flutter unit and widget tests passed"
    
    # Integration tests (if requested)
    if [ "$INTEGRATION" = true ]; then
        print_color $YELLOW "Running Flutter integration tests..."
        
        # Check if integration test devices are available
        devices=$(flutter devices --machine 2>/dev/null || echo "[]")
        
        if [ "$devices" != "[]" ] && [ "$devices" != "" ]; then
            # Try to find a suitable device
            device_id=$(echo "$devices" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
            
            if [ ! -z "$device_id" ]; then
                print_color $YELLOW "Running integration tests on device: $device_id"
                if [ "$VERBOSE" = true ]; then
                    flutter test integration_test/app_test.dart -d "$device_id" --verbose
                else
                    flutter test integration_test/app_test.dart -d "$device_id"
                fi
                print_color $GREEN "✓ Flutter integration tests passed"
            else
                print_color $YELLOW "⚠ No suitable device found for integration tests, skipping..."
            fi
        else
            print_color $YELLOW "⚠ No devices available for integration tests, skipping..."
        fi
    fi
    
    # Coverage (if requested)
    if [ "$COVERAGE" = true ]; then
        print_color $YELLOW "Generating Flutter test coverage..."
        flutter test --coverage
        
        # Generate HTML coverage report
        if command -v genhtml &> /dev/null; then
            mkdir -p ../target/coverage/flutter
            genhtml coverage/lcov.info -o ../target/coverage/flutter
            print_color $GREEN "✓ Flutter coverage report generated in target/coverage/flutter/"
        else
            print_color $YELLOW "⚠ genhtml not found, raw coverage data available in coverage/lcov.info"
        fi
    fi
    
    # Analyze code
    print_color $YELLOW "Running Flutter analyzer..."
    flutter analyze
    print_color $GREEN "✓ Flutter analysis passed"
    
    cd ..
fi

# Generate combined coverage report (if requested)
if [ "$COVERAGE" = true ] && ([ "$RUN_ALL" = true ] || ([ "$RUST_ONLY" = true ] && [ "$FLUTTER_ONLY" = true ])); then
    print_section "Combined Coverage Report"
    
    print_color $YELLOW "Generating combined coverage report..."
    
    # Create combined coverage directory
    mkdir -p target/coverage/combined
    
    # Copy individual reports
    if [ -d "target/coverage/rust" ]; then
        cp -r target/coverage/rust target/coverage/combined/
    fi
    
    if [ -d "target/coverage/flutter" ]; then
        cp -r target/coverage/flutter target/coverage/combined/
    fi
    
    # Create index page
    cat > target/coverage/combined/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>V8Ray Test Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .section { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        .section h2 { margin-top: 0; color: #333; }
        .link { display: inline-block; margin: 10px; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 3px; }
        .link:hover { background: #0056b3; }
    </style>
</head>
<body>
    <h1>V8Ray Test Coverage Report</h1>
    <p>Generated on: $(date)</p>
    
    <div class="section">
        <h2>Rust Core Coverage</h2>
        <p>Coverage report for the Rust core library.</p>
        <a href="rust/tarpaulin-report.html" class="link">View Rust Coverage</a>
    </div>
    
    <div class="section">
        <h2>Flutter App Coverage</h2>
        <p>Coverage report for the Flutter application.</p>
        <a href="flutter/index.html" class="link">View Flutter Coverage</a>
    </div>
</body>
</html>
EOF
    
    print_color $GREEN "✓ Combined coverage report generated in target/coverage/combined/"
fi

print_section "Test Summary"

if [ "$RUN_ALL" = true ] || [ "$RUST_ONLY" = true ]; then
    print_color $GREEN "✓ Rust tests completed successfully"
fi

if [ "$RUN_ALL" = true ] || [ "$FLUTTER_ONLY" = true ]; then
    print_color $GREEN "✓ Flutter tests completed successfully"
fi

if [ "$COVERAGE" = true ]; then
    print_color $GREEN "✓ Coverage reports generated"
fi

print_color $GREEN "🎉 All tests passed!"

# Open coverage report if generated (on macOS/Linux with GUI)
if [ "$COVERAGE" = true ] && [ -f "target/coverage/combined/index.html" ]; then
    if command -v xdg-open &> /dev/null; then
        print_color $YELLOW "Opening coverage report in browser..."
        xdg-open target/coverage/combined/index.html
    elif command -v open &> /dev/null; then
        print_color $YELLOW "Opening coverage report in browser..."
        open target/coverage/combined/index.html
    fi
fi
