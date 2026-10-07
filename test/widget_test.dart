import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic/main.dart';
import 'package:kinetic/screens/calendar_screen.dart';
import 'package:kinetic/screens/food_tracker_screen.dart';
import 'package:kinetic/screens/analytics_screen.dart';
import 'package:kinetic/screens/daily_timeline_screen.dart';
import 'package:kinetic/screens/dashboard_screen.dart';

void main() {
  testWidgets('Kinetic Fitness OS smoke test and tab switching', (WidgetTester tester) async {
    // Provide a standard phone viewport
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const KineticFitnessApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DashboardScreen), findsOneWidget);

    // Switch to Calendar tab (index 1)
    final calendarIcon = find.byIcon(Icons.calendar_month_outlined);
    expect(calendarIcon, findsOneWidget);
    await tester.tap(calendarIcon);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CalendarScreen), findsOneWidget);

    // Switch to Nutrition tab (index 2)
    final nutritionIcon = find.byIcon(Icons.restaurant_outlined);
    expect(nutritionIcon, findsOneWidget);
    await tester.tap(nutritionIcon);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FoodTrackerScreen), findsOneWidget);

    // Switch to Anatomy tab (index 3)
    final anatomyIcon = find.byIcon(Icons.accessibility_new_outlined);
    expect(anatomyIcon, findsOneWidget);
    await tester.tap(anatomyIcon);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AnalyticsScreen), findsOneWidget);

    // Switch to Protocol tab (index 4)
    final protocolIcon = find.byIcon(Icons.view_timeline_outlined);
    expect(protocolIcon, findsOneWidget);
    await tester.tap(protocolIcon);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DailyTimelineScreen), findsOneWidget);
  });
}
