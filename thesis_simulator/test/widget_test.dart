import 'package:flutter_test/flutter_test.dart';
import 'package:thesis_simulator/app.dart';

void main() {
  testWidgets('home screen shows the main controls', (tester) async {
    await tester.pumpWidget(const SimulatorApp(autoConnect: false));
    expect(find.text('Cacao Pod Model Simulator'), findsOneWidget);
    expect(find.text('Analyze photo'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
  });
}
