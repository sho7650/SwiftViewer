#!/bin/bash

# SwiftViewer Prerequisites Verification Script
# This script ensures build & test pass before any development work

set -e  # Exit on any error

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🔍 SwiftViewer Prerequisites Verification"
echo "==========================================="

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" == "PASS" ]; then
        echo "✅ $message"
    elif [ "$status" == "FAIL" ]; then
        echo "❌ $message"
        exit 1
    else
        echo "🔄 $message"
    fi
}

# 1. Verify Build
print_status "RUN" "Building SwiftViewer..."
if xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Debug -sdk macosx build > build.log 2>&1; then
    print_status "PASS" "Build succeeded"
    rm build.log
else
    print_status "FAIL" "Build failed - check build.log for details"
    echo "Build errors:"
    tail -20 build.log
    exit 1
fi

# 2. Verify Tests
print_status "RUN" "Running SwiftViewer tests..."
if xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -configuration Debug -sdk macosx -only-testing SwiftViewerTests test > test.log 2>&1; then
    print_status "PASS" "Tests succeeded" 
    rm test.log
else
    print_status "FAIL" "Tests failed - check test.log for details"
    echo "Test errors:"
    tail -30 test.log
    exit 1
fi

# 3. Verify Framework Consistency
print_status "RUN" "Checking framework consistency..."
if grep -r "import Testing" SwiftViewerTests/ && grep -r "import XCTest" SwiftViewerTests/; then
    print_status "FAIL" "Mixed testing frameworks detected (XCTest + Swift Testing)"
    echo "Files with mixed frameworks:"
    grep -l "import Testing" SwiftViewerTests/**/*.swift | head -5
    grep -l "import XCTest" SwiftViewerTests/**/*.swift | head -5
    exit 1
else
    print_status "PASS" "Framework consistency verified"
fi

echo ""
echo "🎉 All prerequisites passed!"
echo "✅ Build: SUCCESS"
echo "✅ Tests: SUCCESS" 
echo "✅ Framework Consistency: SUCCESS"
echo ""
echo "You can now safely proceed with development work."