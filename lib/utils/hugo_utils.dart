import 'dart:io';
import 'package:path/path.dart' as p;

class HugoUtils {
  /// Checks if a directory is a valid Hugo site
  static bool isHugoSite(String directoryPath) {
    final configFile = File(p.join(directoryPath, 'config.toml'));
    final configYamlFile = File(p.join(directoryPath, 'config.yaml'));
    final hugoFile = File(p.join(directoryPath, 'hugo.toml'));
    
    return configFile.existsSync() || 
           configYamlFile.existsSync() || 
           hugoFile.existsSync();
  }

  /// Extracts front matter from markdown content
  static Map<String, dynamic> extractFrontMatter(String content) {
    final frontMatterRegex = RegExp(r'^---\s*\n(.*?)\n---', dotAll: true);
    final match = frontMatterRegex.firstMatch(content);
    
    if (match != null) {
      final frontMatterText = match.group(1)!;
      final frontMatter = <String, dynamic>{};
      
      for (final line in frontMatterText.split('\n')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          final key = line.substring(0, colonIndex).trim();
          final value = line.substring(colonIndex + 1).trim().replaceAll('"', '');
          frontMatter[key] = value;
        }
      }
      
      return frontMatter;
    }
    
    return {};
  }

  /// Removes YAML front matter from markdown content
  static String removeYamlFrontMatter(String content) {
    final frontMatterRegex = RegExp(r'^---\s*\n.*?\n---\s*\n', dotAll: true);
    return content.replaceFirst(frontMatterRegex, '');
  }

  /// Creates a new post template
  static String createPostTemplate({
    required String title,
    required bool isDraft,
  }) {
    return '''---
title: "$title"
date: ${DateTime.now().toIso8601String()}
draft: $isDraft
---

# $title

Your content here...
''';
  }
}