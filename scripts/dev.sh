#!/bin/bash

# Development helper script for Fugo

case "$1" in
  "run")
    echo "Running Fugo on Linux..."
    flutter run -d linux
    ;;
  "test")
    echo "Running tests..."
    flutter test
    ;;
  "analyze")
    echo "Analyzing code..."
    flutter analyze
    ;;
  "build")
    echo "Building for Linux..."
    flutter build linux
    ;;
  "clean")
    echo "Cleaning build artifacts..."
    flutter clean
    flutter pub get
    ;;
  *)
    echo "Usage: $0 {run|test|analyze|build|clean}"
    echo ""
    echo "Commands:"
    echo "  run     - Run the app on Linux"
    echo "  test    - Run all tests"
    echo "  analyze - Analyze code for issues"
    echo "  build   - Build release version"
    echo "  clean   - Clean and reinstall dependencies"
    exit 1
    ;;
esac