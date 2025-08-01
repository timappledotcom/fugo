import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fugo/main.dart';

void main() {
  group('Fugo App Tests', () {
    testWidgets('App launches with welcome screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify the welcome screen is displayed
      expect(find.text('Welcome to Fugo'), findsOneWidget);
      expect(find.text('A Hugo site management tool for Ubuntu'), findsOneWidget);
      expect(find.text('Select Hugo Site'), findsOneWidget);
    });

    testWidgets('App has correct title and theme', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify app title in app bar
      expect(find.text('Fugo'), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    testWidgets('Welcome screen has proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Verify welcome screen elements
      expect(find.byIcon(Icons.folder_open), findsWidgets);
      expect(find.text('Select Hugo Site'), findsOneWidget);
    });
  });
}
