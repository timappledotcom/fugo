# Fugo

A Hugo site management tool for Ubuntu desktop, built with Flutter.

## Features

- **Site Management**: Select and manage Hugo sites with automatic detection
- **Content Organization**: Browse posts, pages, and drafts in separate views
- **Built-in Editor**: Edit Markdown files with live preview
- **Publishing**: Build and publish sites directly from the app
- **Ubuntu Integration**: Native Ubuntu theming with Yaru design system

## Requirements

- Flutter SDK (3.8.1 or higher)
- Hugo static site generator
- Ubuntu desktop environment

## Installation

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run -d linux`

## Usage

1. Launch Fugo
2. Select your Hugo site directory (must contain config.toml, config.yaml, or hugo.toml)
3. Browse and edit your content
4. Use the publish button to build your site with Hugo
5. Open in browser to preview at localhost:1313

## Development

This app uses the Yaru theme for native Ubuntu integration and includes:
- File system operations for Hugo content management
- Markdown editing with preview
- Hugo command integration
- Persistent site selection
