# Contributing to Fugo

Thank you for your interest in contributing to Fugo! This document provides guidelines for contributing to the project.

## Development Setup

1. **Prerequisites**
   - Flutter SDK (3.8.1 or higher)
   - Hugo static site generator
   - Ubuntu desktop environment (for testing)

2. **Clone and Setup**
   ```bash
   git clone https://github.com/timappledotcom/fugo.git
   cd fugo
   flutter pub get
   ```

3. **Development Commands**
   ```bash
   # Run the app
   ./scripts/dev.sh run
   
   # Run tests
   ./scripts/dev.sh test
   
   # Analyze code
   ./scripts/dev.sh analyze
   
   # Build release
   ./scripts/dev.sh build
   ```

## Code Style

- Follow Dart/Flutter conventions
- Use `dart format` to format code
- Ensure `flutter analyze` passes without issues
- Write tests for new features

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Reporting Issues

When reporting issues, please include:
- Operating system and version
- Flutter version
- Hugo version (if applicable)
- Steps to reproduce the issue
- Expected vs actual behavior

## Feature Requests

Feature requests are welcome! Please:
- Check if the feature already exists or is planned
- Describe the use case and expected behavior
- Consider if it fits the project's scope

## Code of Conduct

Be respectful and inclusive. We want Fugo to be a welcoming project for all contributors.