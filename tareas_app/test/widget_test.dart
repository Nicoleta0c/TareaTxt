import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareas_app/main.dart';

void main() {
  testWidgets('Test basico de la app de tareas', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TareasApp()));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('No hay tareas.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mi primera tarea');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Agregar'));
    await tester.pump();

    expect(find.text('Mi primera tarea'), findsOneWidget);
  });
}
