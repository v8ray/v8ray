# V8Ray Test Runner Script
# This script runs all tests for both Rust and Flutter code

param(
    [switch]$Rust = $false,
    [switch]$Flutter = $false,
    [switch]$Coverage = $false,
    [switch]$Integration = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param($Color, $Message)
    Write-Host "$Color$Message$Reset"
}

function Write-Section {
    param($Title)
    Write-Host ""
    Write-ColorOutput $Blue "=== $Title ==="
}

function Check-Command {
    param($Command)
    if (!(Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-ColorOutput $Red "Error: $Command is not installed or not in PATH"
        exit 1
    }
}

# Check if we should run all tests
$RunAll = !$Rust -and !$Flutter

Write-ColorOutput $Green "V8Ray Test Runner"
Write-Host "Coverage mode: $Coverage"
Write-Host "Integration tests: $Integration"
Write-Host "Verbose mode: $Verbose"
Write-Host ""

# Rust tests
if ($Rust -or $RunAll) {
    Write-Section "Rust Tests"
    
    # Check if cargo is available
    Check-Command "cargo"
    
    Set-Location "core"
    
    try {
        # Unit tests
        Write-ColorOutput $Yellow "Running Rust unit tests..."
        if ($Verbose) {
            cargo test --lib --verbose
        } else {
            cargo test --lib
        }
        Write-ColorOutput $Green "✓ Rust unit tests passed"
        
        # Integration tests
        if ($Integration) {
            Write-ColorOutput $Yellow "Running Rust integration tests..."
            if ($Verbose) {
                cargo test --test integration_test --verbose
            } else {
                cargo test --test integration_test
            }
            Write-ColorOutput $Green "✓ Rust integration tests passed"
        }
        
        # Documentation tests
        Write-ColorOutput $Yellow "Running Rust documentation tests..."
        if ($Verbose) {
            cargo test --doc --verbose
        } else {
            cargo test --doc
        }
        Write-ColorOutput $Green "✓ Rust documentation tests passed"
        
        # Benchmark tests (if available)
        Write-ColorOutput $Yellow "Running Rust benchmark tests..."
        if ($Verbose) {
            cargo test --benches --verbose
        } else {
            cargo test --benches
        }
        Write-ColorOutput $Green "✓ Rust benchmark tests passed"
        
        # Coverage (if requested)
        if ($Coverage) {
            Write-ColorOutput $Yellow "Generating Rust test coverage..."
            
            # Check if cargo-tarpaulin is installed
            if (!(Get-Command cargo-tarpaulin -ErrorAction SilentlyContinue)) {
                Write-ColorOutput $Yellow "Installing cargo-tarpaulin for coverage..."
                cargo install cargo-tarpaulin
            }
            
            cargo tarpaulin --out Html --output-dir ../target/coverage/rust
            Write-ColorOutput $Green "✓ Rust coverage report generated in target/coverage/rust/"
        }
        
    } catch {
        Write-ColorOutput $Red "✗ Rust tests failed: $_"
        Set-Location ".."
        exit 1
    }
    
    Set-Location ".."
}

# Flutter tests
if ($Flutter -or $RunAll) {
    Write-Section "Flutter Tests"
    
    # Check if flutter is available
    Check-Command "flutter"
    
    Set-Location "app"
    
    try {
        # Get dependencies first
        Write-ColorOutput $Yellow "Getting Flutter dependencies..."
        flutter pub get
        
        # Unit and widget tests
        Write-ColorOutput $Yellow "Running Flutter unit and widget tests..."
        if ($Verbose) {
            flutter test --verbose
        } else {
            flutter test
        }
        Write-ColorOutput $Green "✓ Flutter unit and widget tests passed"
        
        # Integration tests (if requested)
        if ($Integration) {
            Write-ColorOutput $Yellow "Running Flutter integration tests..."
            
            # Check if integration test devices are available
            $devices = flutter devices --machine | ConvertFrom-Json
            $testDevice = $devices | Where-Object { $_.category -eq "desktop" -or $_.category -eq "mobile" } | Select-Object -First 1
            
            if ($testDevice) {
                Write-ColorOutput $Yellow "Running integration tests on device: $($testDevice.name)"
                if ($Verbose) {
                    flutter test integration_test/app_test.dart -d $testDevice.id --verbose
                } else {
                    flutter test integration_test/app_test.dart -d $testDevice.id
                }
                Write-ColorOutput $Green "✓ Flutter integration tests passed"
            } else {
                Write-ColorOutput $Yellow "⚠ No suitable device found for integration tests, skipping..."
            }
        }
        
        # Coverage (if requested)
        if ($Coverage) {
            Write-ColorOutput $Yellow "Generating Flutter test coverage..."
            flutter test --coverage
            
            # Generate HTML coverage report
            if (Get-Command genhtml -ErrorAction SilentlyContinue) {
                genhtml coverage/lcov.info -o ../target/coverage/flutter
                Write-ColorOutput $Green "✓ Flutter coverage report generated in target/coverage/flutter/"
            } else {
                Write-ColorOutput $Yellow "⚠ genhtml not found, raw coverage data available in coverage/lcov.info"
            }
        }
        
        # Analyze code
        Write-ColorOutput $Yellow "Running Flutter analyzer..."
        flutter analyze
        Write-ColorOutput $Green "✓ Flutter analysis passed"
        
    } catch {
        Write-ColorOutput $Red "✗ Flutter tests failed: $_"
        Set-Location ".."
        exit 1
    }
    
    Set-Location ".."
}

# Generate combined coverage report (if requested)
if ($Coverage -and ($RunAll -or ($Rust -and $Flutter))) {
    Write-Section "Combined Coverage Report"
    
    Write-ColorOutput $Yellow "Generating combined coverage report..."
    
    # Create combined coverage directory
    New-Item -ItemType Directory -Path "target/coverage/combined" -Force | Out-Null
    
    # Copy individual reports
    if (Test-Path "target/coverage/rust") {
        Copy-Item -Recurse "target/coverage/rust/*" "target/coverage/combined/rust/"
    }
    
    if (Test-Path "target/coverage/flutter") {
        Copy-Item -Recurse "target/coverage/flutter/*" "target/coverage/combined/flutter/"
    }
    
    # Create index page
    $indexHtml = @"
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
    <p>Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
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
"@
    
    $indexHtml | Out-File -FilePath "target/coverage/combined/index.html" -Encoding UTF8
    
    Write-ColorOutput $Green "✓ Combined coverage report generated in target/coverage/combined/"
}

Write-Section "Test Summary"

if ($RunAll -or $Rust) {
    Write-ColorOutput $Green "✓ Rust tests completed successfully"
}

if ($RunAll -or $Flutter) {
    Write-ColorOutput $Green "✓ Flutter tests completed successfully"
}

if ($Coverage) {
    Write-ColorOutput $Green "✓ Coverage reports generated"
}

Write-ColorOutput $Green "🎉 All tests passed!"

# Open coverage report if generated
if ($Coverage -and (Test-Path "target/coverage/combined/index.html")) {
    Write-ColorOutput $Yellow "Opening coverage report in browser..."
    Start-Process "target/coverage/combined/index.html"
}
