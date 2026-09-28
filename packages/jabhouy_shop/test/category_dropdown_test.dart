import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryBloc extends Mock implements CategoryBloc {}

void main() {
  testWidgets('a filter whose category is gone shows nothing instead of throwing',
      (tester) async {
    const drinks = CategoryItemModel(id: 1, name: 'Drinks');
    final bloc = MockCategoryBloc();
    // The filtered category (id 2) was deleted; only drinks remain.
    when(() => bloc.state).thenReturn(const CategoryLoaded(items: [drinks]));
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<CategoryBloc>.value(
            value: bloc,
            child: const CategoryDropdown(
              initialValue: CategoryItemModel(id: 2, name: 'Snacks'),
            ),
          ),
        ),
      ),
    );

    // firstWhere without orElse threw a StateError during this build.
    expect(tester.takeException(), isNull);
    expect(find.byType(CategoryDropdown), findsOneWidget);
  });
}
