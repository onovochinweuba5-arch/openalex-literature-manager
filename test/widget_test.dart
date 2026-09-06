import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:openalex_literature_manager/app.dart';

void main() {
  testWidgets('renders the literature discovery workspace', (tester) async {
    await tester.pumpWidget(const LiteratureManagerApp());

    expect(find.text('Discover what matters.'), findsOneWidget);
    expect(
      find.textContaining('Search the OpenAlex scholarly index'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('shows saved papers navigation', (tester) async {
    await tester.pumpWidget(const LiteratureManagerApp());
    await tester.tap(find.text('Saved', skipOffstage: false));
    await tester.pump();

    expect(find.text('Saved papers'), findsOneWidget);
  });
}
