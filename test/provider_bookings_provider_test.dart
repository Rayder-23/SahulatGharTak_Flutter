// Coverage for ProviderBookingsProvider.respond()'s "lost the first-accept-wins
// race" handling (Feature 2, docs/flutter-changes.md): a distinct `lostRace`
// flag should be set only for that specific backend error message, and it
// should trigger an automatic list refresh so auto-cancelled sibling
// bookings drop off immediately.
import 'package:flutter_test/flutter_test.dart';

import 'package:sahulat_ghar_tak/data/repositories/provider_bookings_repository.dart';
import 'package:sahulat_ghar_tak/models/provider/service_booking.dart';
import 'package:sahulat_ghar_tak/providers/provider_bookings_provider.dart';

ServiceBooking _booking(int uid, {String status = 'Accepted'}) {
  return ServiceBooking(
    uid: uid,
    requestUid: uid,
    requestTitle: 'Title',
    clientUid: 1,
    clientName: 'Client',
    providerUid: 5,
    providerName: 'Provider',
    serviceDetail: 'Detail',
    estimatedAmount: 100,
    visitCharges: 0,
    additionalCharges: 0,
    deductions: 0,
    finalAmount: 100,
    customerPaid: 0,
    paymentMode: 'Cash',
    customerRemaining: 100,
    commissionType: 'Percentage',
    commissionValue: 10,
    commissionAmount: 10,
    providerEarning: 90,
    status: status,
    createdOn: DateTime(2026, 9, 3),
  );
}

class _FakeRepository extends ProviderBookingsRepository {
  _FakeRepository({this.respondError, this.fetchResult = const []});

  final Object? respondError;
  final List<ServiceBooking> fetchResult;
  int fetchByProviderCalls = 0;

  @override
  Future<List<ServiceBooking>> fetchByProvider(int providerUid) async {
    fetchByProviderCalls++;
    return fetchResult;
  }

  @override
  Future<int> loadRejectedSeenCount(int providerUid) async => 0;

  @override
  Future<ServiceBooking> respond({required ServiceBooking booking, required bool accept, String? reason}) async {
    if (respondError != null) throw respondError!;
    return _booking(booking.uid, status: 'Accepted');
  }
}

void main() {
  test('respond() sets lostRace and refreshes the list on the first-accept-wins failure message', () async {
    final repo = _FakeRepository(
      respondError: Exception('This job has already been assigned to another provider.'),
      fetchResult: [_booking(2)],
    );
    final provider = ProviderBookingsProvider(repository: repo);
    await provider.loadBookings(5);
    repo.fetchByProviderCalls = 0; // reset after the initial load above

    final success = await provider.respond(_booking(1), true);

    expect(success, isFalse);
    expect(provider.lostRace, isTrue);
    expect(repo.fetchByProviderCalls, 1);
    expect(provider.bookings.map((b) => b.uid), [2]);
  });

  test('respond() does not set lostRace for a generic error and does not refresh the list', () async {
    final repo = _FakeRepository(respondError: Exception('Network error'));
    final provider = ProviderBookingsProvider(repository: repo);
    await provider.loadBookings(5);
    repo.fetchByProviderCalls = 0;

    final success = await provider.respond(_booking(1), true);

    expect(success, isFalse);
    expect(provider.lostRace, isFalse);
    expect(repo.fetchByProviderCalls, 0);
  });

  test('respond() clears lostRace on a subsequent successful call', () async {
    final repo = _FakeRepository(respondError: Exception('This job has already been assigned to another provider.'));
    final provider = ProviderBookingsProvider(repository: repo);
    await provider.loadBookings(5);
    await provider.respond(_booking(1), true);
    expect(provider.lostRace, isTrue);

    final successRepo = _FakeRepository();
    final successProvider = ProviderBookingsProvider(repository: successRepo);
    await successProvider.loadBookings(5);
    final success = await successProvider.respond(_booking(1), true);

    expect(success, isTrue);
    expect(successProvider.lostRace, isFalse);
  });
}
