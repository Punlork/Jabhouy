import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy/credit/credit.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_net/jabhouy_net.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mocktail/mocktail.dart';

class _Connectivity extends Mock implements ConnectivityService {}

class _Scope implements ShopScope {
  @override
  MemberRole get role => MemberRole.owner;
  @override
  String get shopId => 's1';
  @override
  bool get syncs => false;
  @override
  String get userId => 'u1';
}

void main() {
  late AppDatabase db;
  late CreditRepository repo;
  final taken = DateTime.utc(2026, 10, 14, 4);

  Credit credit(
    String id,
    String customer, {
    int? amount,
    String? note,
    CreditStatus status = CreditStatus.unpaid,
  }) => Credit(
    id: id,
    customerId: customer,
    currency: Currency.khr,
    khrPerUsd: 4000,
    takenAt: taken,
    amount: amount,
    note: note,
    status: status,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final connectivity = _Connectivity();
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    repo = CreditRepository(
      CreditDao(db),
      _Scope(),
      SyncEngine(database: db, transport: AdapterSyncTransport([])),
      connectivity,
    );
    await repo.saveCustomer(const CreditCustomer(id: 'bol', name: 'ពូ បុល'));
    await repo.saveCustomer(const CreditCustomer(id: 'mak', name: 'មាក់'));
    await repo.saveCredit(
      credit('c1', 'bol', amount: 23000, note: 'Hanuman 6'),
    );
    await repo.saveCredit(credit('c2', 'mak'));
    await repo.saveCredit(
      credit('c3', 'bol', amount: 9000, status: CreditStatus.paid),
    );
  });

  testWidgets('the tab shows the card, chips and a row per Credit', (
    tester,
  ) async {
    final cubit = CreditListCubit(repo)..start();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(value: cubit, child: const CreditView()),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('នៅជំពាក់សរុប'), findsOneWidget);
    expect(find.text('23,000 ៛'), findsNWidgets(2), reason: 'card and row');
    expect(find.text(r'≈ $5.75'), findsNWidgets(2));
    expect(
      find.text('មិនទាន់សង 2 នាក់ · 1 នាក់មិនទាន់មានចំនួន'),
      findsOneWidget,
    );
    expect(find.text('ពូ បុល'), findsOneWidget);
    expect(find.text('មាក់'), findsOneWidget);
    expect(find.text('មិនទាន់មានចំនួន'), findsOneWidget);
    expect(find.text('Hanuman 6'), findsOneWidget);
    expect(find.text('14 តុលា 2026 11:00 ព្រឹក'), findsNWidgets(2));
    expect(find.text('សងរួច'), findsOneWidget, reason: 'the chip only');

    await tester.tap(find.text('ទាំងអស់'));
    await tester.pump();
    expect(find.text('ពូ បុល'), findsNWidgets(2));
    expect(find.text('សងរួច'), findsNWidgets(2), reason: 'chip and the pill');

    await tester.pumpWidget(const SizedBox());
    // Closed in real time: a cancel under the fake clock never finishes.
    await tester.runAsync(() async {
      await cubit.close();
      await db.close();
    });
  });
}
