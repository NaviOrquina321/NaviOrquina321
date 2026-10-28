import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:doctor_appointment_app/main.dart';
import 'package:doctor_appointment_app/data/db/database_helper.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.instance.database;
  });

  testWidgets('DoctorAppointmentApp loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DoctorAppointmentApp());
    expect(find.byType(DoctorAppointmentApp), findsOneWidget);
    await tester.pump();
  });
}
