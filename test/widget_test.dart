import 'package:allerview/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('moves from splash to onboarding', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Aller-View'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('알레르기 정보 설정'), findsOneWidget);
  });
}
