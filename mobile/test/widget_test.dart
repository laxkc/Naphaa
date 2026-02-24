import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sme_digital/app.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('app shell loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmeDigitalApp()));
    await tester.pumpAndSettle();

    expect(find.text('SME Digital'), findsWidgets);
    expect(find.text('Login'), findsOneWidget);
  });
}
