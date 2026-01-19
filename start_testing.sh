#!/bin/bash

# FIt Check - Testing Quick Start Script
# This script helps you get started with testing

echo "🧪 FIt Check - Testing Quick Start"
echo "=================================="
echo ""

# Check if Xcode project exists
if [ ! -d "FIt Check.xcodeproj" ]; then
    echo "❌ Error: FIt Check.xcodeproj not found"
    echo "   Please run this script from the project root directory"
    exit 1
fi

echo "✅ Project found: FIt Check.xcodeproj"
echo ""

# Check if test directories exist
if [ -d "FIt CheckTests" ] && [ -d "FIt CheckUITests" ]; then
    echo "✅ Test directories found"
    echo "   - FIt CheckTests (Unit Tests)"
    echo "   - FIt CheckUITests (UI Tests)"
else
    echo "❌ Error: Test directories not found"
    exit 1
fi

echo ""
echo "📚 Available Documentation:"
echo "   1. README_TESTS.md - Complete reference"
echo "   2. QUICK_TEST_SETUP.md - 5-minute setup"
echo "   3. TEST_SETUP_GUIDE.md - Detailed guide"
echo "   4. TEST_CHECKLIST.md - Interactive checklist"
echo "   5. TEST_SUMMARY.md - Overview"
echo ""

# Ask user what they want to do
echo "What would you like to do?"
echo "  1) Open Xcode project"
echo "  2) Read quick setup guide"
echo "  3) Read detailed setup guide"
echo "  4) Open checklist"
echo "  5) List test files"
echo "  6) Verify project structure"
echo "  7) Run tests (requires setup first)"
echo "  8) Exit"
echo ""
read -p "Enter choice (1-8): " choice

case $choice in
    1)
        echo "🚀 Opening Xcode..."
        open "FIt Check.xcodeproj"
        ;;
    2)
        echo "📖 Opening quick setup guide..."
        open "QUICK_TEST_SETUP.md"
        ;;
    3)
        echo "📖 Opening detailed setup guide..."
        open "TEST_SETUP_GUIDE.md"
        ;;
    4)
        echo "📋 Opening checklist..."
        open "TEST_CHECKLIST.md"
        ;;
    5)
        echo "📄 Test files:"
        echo ""
        echo "Unit Tests (FIt CheckTests/):"
        ls -lh "FIt CheckTests/"*.swift 2>/dev/null
        echo ""
        echo "UI Tests (FIt CheckUITests/):"
        ls -lh "FIt CheckUITests/"*.swift 2>/dev/null
        ;;
    6)
        echo "🔍 Verifying project structure..."
        xcodebuild -list -project "FIt Check.xcodeproj"
        ;;
    7)
        echo "🧪 Running tests..."
        echo "⚠️  Make sure you've added test targets to Xcode first!"
        echo ""
        read -p "Continue? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            xcodebuild test -scheme "FIt Check" -destination 'platform=macOS'
        else
            echo "Cancelled."
        fi
        ;;
    8)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✨ Done!"
