import 'package:allerview/features/onboarding/nickname_screen.dart';
import 'package:allerview/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('moves from splash to onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    expect(find.text('Aller-View'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NicknameScreen), findsOneWidget);
  });
}
