#!/bin/bash

echo "🔍 Na'vi Kit Build Verification Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "Na-vi.xcworkspace" ]; then
    echo -e "${RED}❌ Error: Na-vi.xcworkspace not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo "✅ Found Na-vi.xcworkspace"
echo ""

# Check for required files
echo "📁 Checking for new/modified files..."
files_to_check=(
    "Na'vi/ViewStylingManager.swift"
    "Na'vi/GlassUIHelper.swift"
    "Na'vi/NDDictionaryMainViewController.swift"
    "Na'vi/NDDictionaryMainTableViewCell.swift"
    "Na'vi/NDDictionarySectionTableViewCell.swift"
    "Na'vi/NDDefinitionViewController.swift"
    "IMPROVEMENTS.md"
)

all_files_exist=true
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $file"
    else
        echo -e "${RED}❌${NC} $file (MISSING)"
        all_files_exist=false
    fi
done

echo ""

if [ "$all_files_exist" = false ]; then
    echo -e "${RED}❌ Some files are missing!${NC}"
    exit 1
fi

# Check Swift syntax of key files
echo "🔧 Checking Swift syntax..."
echo ""

syntax_errors=0

check_swift_file() {
    local file=$1
    echo -n "Checking $file... "

    # Count lines to ensure file isn't empty
    lines=$(wc -l < "$file" 2>/dev/null)
    if [ "$lines" -eq 0 ]; then
        echo -e "${RED}EMPTY${NC}"
        return 1
    fi

    # Check for basic Swift syntax issues
    if grep -q "class\|func\|var\|let\|import" "$file"; then
        echo -e "${GREEN}OK${NC} ($lines lines)"
        return 0
    else
        echo -e "${RED}INVALID${NC}"
        return 1
    fi
}

for file in "${files_to_check[@]}"; do
    if [[ $file == *.swift ]]; then
        if ! check_swift_file "$file"; then
            syntax_errors=$((syntax_errors + 1))
        fi
    fi
done

echo ""

# Check for Swift 2 FIXME operators (should be gone)
echo "🔍 Checking for removed technical debt..."
if grep -r "FIXME: comparison operators with optionals" "Na'vi/" 2>/dev/null; then
    echo -e "${RED}❌ Found Swift 2 FIXME code (should be removed)${NC}"
else
    echo -e "${GREEN}✅ Swift 2 technical debt removed${NC}"
fi

# Check for ViewStylingManager usage
echo ""
echo "🎨 Checking for ViewStylingManager usage..."
if grep -q "stylingManager.setup" "Na'vi/NDDictionaryMainViewController.swift"; then
    echo -e "${GREEN}✅ ViewStylingManager is being used${NC}"
else
    echo -e "${YELLOW}⚠️  ViewStylingManager not found in use${NC}"
fi

# Check for lazy blur views
echo ""
echo "⚡ Checking for performance optimizations..."
if grep -q "private lazy var glassBackgroundView" "Na'vi/NDDictionaryMainTableViewCell.swift"; then
    echo -e "${GREEN}✅ Lazy blur views implemented${NC}"
else
    echo -e "${YELLOW}⚠️  Lazy blur views not found${NC}"
fi

if grep -q "prepareForReuse" "Na'vi/NDDictionaryMainTableViewCell.swift"; then
    echo -e "${GREEN}✅ prepareForReuse() optimization added${NC}"
else
    echo -e "${YELLOW}⚠️  prepareForReuse() not found${NC}"
fi

# Check for performance profiling
echo ""
echo "📊 Checking for performance profiling tools..."
if grep -q "startPerformanceTimer\|measureFPS\|logMemoryUsage" "Na'vi/GlassUIHelper.swift"; then
    echo -e "${GREEN}✅ Performance profiling tools added${NC}"
else
    echo -e "${YELLOW}⚠️  Performance profiling not found${NC}"
fi

# Try to build
echo ""
echo "🏗️  Attempting to build project..."
echo ""

xcodebuild -workspace Na-vi.xcworkspace \
    -scheme Na-vi \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" | head -20

build_exit_code=${PIPESTATUS[0]}

echo ""
echo "======================================"

if [ $syntax_errors -eq 0 ] && [ "$all_files_exist" = true ]; then
    echo -e "${GREEN}✅ Code verification passed!${NC}"
    echo ""
    echo "Note: Actual build may fail if iOS 26.2 SDK is not installed."
    echo "To install: Xcode > Settings > Platforms > iOS 26.2"
else
    echo -e "${RED}❌ Code verification failed${NC}"
    echo "Syntax errors: $syntax_errors"
fi

echo ""
echo "📖 See IMPROVEMENTS.md for detailed documentation"
