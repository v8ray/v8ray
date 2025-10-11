# V8Ray Code Quality Check Script
# This script runs all code quality checks for both Rust and Flutter code

param(
    [switch]$Fix = $false,
    [switch]$Rust = $false,
    [switch]$Flutter = $false
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

# Check if we should run all checks
$RunAll = !$Rust -and !$Flutter

Write-ColorOutput $Green "V8Ray Code Quality Check"
Write-Host "Fix mode: $Fix"
Write-Host ""

# Rust checks
if ($Rust -or $RunAll) {
    Write-Section "Rust Code Quality Checks"
    
    # Check if cargo is available
    Check-Command "cargo"
    
    Set-Location "core"
    
    try {
        # Format check
        Write-ColorOutput $Yellow "Checking Rust code formatting..."
        if ($Fix) {
            cargo fmt --all
            Write-ColorOutput $Green "✓ Rust code formatted"
        } else {
            cargo fmt --all -- --check
            Write-ColorOutput $Green "✓ Rust code formatting is correct"
        }
        
        # Clippy check
        Write-ColorOutput $Yellow "Running Clippy..."
        cargo clippy --all-targets --all-features -- -D warnings
        Write-ColorOutput $Green "✓ Clippy checks passed"
        
        # Build check
        Write-ColorOutput $Yellow "Checking if code compiles..."
        cargo check --all-targets --all-features
        Write-ColorOutput $Green "✓ Code compiles successfully"
        
        # Test check
        Write-ColorOutput $Yellow "Running Rust tests..."
        cargo test --all-features
        Write-ColorOutput $Green "✓ All Rust tests passed"
        
    } catch {
        Write-ColorOutput $Red "✗ Rust checks failed: $_"
        Set-Location ".."
        exit 1
    }
    
    Set-Location ".."
}

# Flutter checks
if ($Flutter -or $RunAll) {
    Write-Section "Flutter Code Quality Checks"
    
    # Check if flutter is available
    Check-Command "flutter"
    
    Set-Location "app"
    
    try {
        # Get dependencies
        Write-ColorOutput $Yellow "Getting Flutter dependencies..."
        flutter pub get
        Write-ColorOutput $Green "✓ Dependencies updated"
        
        # Format check
        Write-ColorOutput $Yellow "Checking Dart code formatting..."
        if ($Fix) {
            dart format .
            Write-ColorOutput $Green "✓ Dart code formatted"
        } else {
            dart format --output=none --set-exit-if-changed .
            Write-ColorOutput $Green "✓ Dart code formatting is correct"
        }
        
        # Analysis check
        Write-ColorOutput $Yellow "Running Dart analyzer..."
        flutter analyze
        Write-ColorOutput $Green "✓ Dart analysis passed"
        
        # Test check
        Write-ColorOutput $Yellow "Running Flutter tests..."
        flutter test
        Write-ColorOutput $Green "✓ All Flutter tests passed"
        
    } catch {
        Write-ColorOutput $Red "✗ Flutter checks failed: $_"
        Set-Location ".."
        exit 1
    }
    
    Set-Location ".."
}

Write-Section "All Checks Completed Successfully"
Write-ColorOutput $Green "🎉 All code quality checks passed!"

if ($Fix) {
    Write-ColorOutput $Yellow "Note: Code has been automatically formatted where possible."
}
