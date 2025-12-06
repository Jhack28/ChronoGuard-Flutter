import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chronoguard_flutter/main.dart' as app;
import 'package:chronoguard_flutter/main.dart';

void main() {
  // Necesario para pruebas de integración
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('La app arranca y muestra MyApp', (tester) async {
    // Arranca la aplicación real
    app.main();
    await tester.pumpAndSettle();

    // Verifica que el widget raíz está en el árbol
    expect(find.byType(MyApp), findsOneWidget);
  });
}
