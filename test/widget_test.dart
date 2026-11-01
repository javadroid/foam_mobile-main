import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foam_mobile/feature/schedule_pickup/controller/schedule_pickup_provider.dart';
import 'package:foam_mobile/feature/schedule_pickup/views/01_how_to_choose_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Foam mobile application smoke test', (WidgetTester tester) async {
    final provider = SchedulePickupProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<SchedulePickupProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: HowToChooseScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pickup from'), findsOneWidget);
    expect(find.byType(HowToChooseScreen), findsOneWidget);
  });
}

