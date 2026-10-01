import '../../models/customer_service_request.dart';
import '../../services/customer_service_request_api_service.dart';
import '../../services/deleted_requests_store.dart';
import '../../services/request_passcode_store.dart';
import '../../services/request_progress_history_store.dart';

/// Owns the customer service-request data source: merges the API's list
/// with the on-device "deleted" (hidden) set, persists each request's
/// passcode as a side effect of fetching, and detects a `progressStatus`
/// regression (provider cancelled an accepted booking — see api.txt v3.22)
/// by comparing against the last-observed value per request UID.
/// `CustomerServiceRequestProvider` should hold only UI state
/// (loading/error/selection flags) and call through to this class rather
/// than talking to the API/stores directly.
class CustomerServiceRequestRepository {
  CustomerServiceRequestRepository({
    CustomerServiceRequestApiService? apiService,
    RequestPasscodeStore? passcodeStore,
    DeletedRequestsStore? deletedStore,
    RequestProgressHistoryStore? progressHistoryStore,
  })  : _apiService = apiService ?? CustomerServiceRequestApiService(),
        _passcodeStore = passcodeStore ?? RequestPasscodeStore(),
        _deletedStore = deletedStore ?? DeletedRequestsStore(),
        _progressHistoryStore =
            progressHistoryStore ?? RequestProgressHistoryStore();

  final CustomerServiceRequestApiService _apiService;
  final RequestPasscodeStore _passcodeStore;
  final DeletedRequestsStore _deletedStore;
  final RequestProgressHistoryStore _progressHistoryStore;

  /// A request "bounced back" when it previously reached `Assigned`/`In
  /// Progress` and is now `Requested` again for the same UID — the
  /// provider-cancel-after-accept re-dispatch case, not a brand-new request.
  bool _didBounceBack(String? previous, String? current) {
    const advancedStages = {'Assigned', 'In Progress'};
    return current == 'Requested' && advancedStages.contains(previous);
  }

  Future<List<CustomerServiceRequest>> fetchByClient(int clientUid) async {
    final fetched = await _apiService.fetchByClient(clientUid);
    final hidden = await _deletedStore.load(clientUid);
    final visible = fetched.where((r) => !hidden.contains(r.uid)).toList();

    final history = await _progressHistoryStore.load(clientUid);
    final updatedHistory = Map<int, String?>.from(history);
    final flagged = <CustomerServiceRequest>[];
    for (final request in visible) {
      _persistPasscode(request);
      final previous = history[request.uid];
      final bounced = _didBounceBack(previous, request.progressStatus);
      updatedHistory[request.uid] = request.progressStatus;
      flagged.add(bounced ? request.copyWithBouncedBack(true) : request);
    }
    await _progressHistoryStore.save(clientUid, updatedHistory);
    return flagged;
  }

  void _persistPasscode(CustomerServiceRequest request) {
    if (request.passcode != null) {
      _passcodeStore.save(request.uid, request.passcode!);
    }
  }

  /// Falls back to the on-device copy saved the last time this request's
  /// passcode was received from the API — keeps "Show Passcode" working
  /// even if the request is later refetched without a live connection.
  Future<String?> getStoredPasscode(int requestUid) =>
      _passcodeStore.load(requestUid);

  Future<CustomerServiceRequest> create({
    required int clientUid,
    required int categoryUid,
    required int clientAddressUid,
    required String serviceTitle,
    required String serviceDescription,
    required String preferredServiceDate,
    required String preferredServiceTime,
    required bool isUrgent,
    required String contactPerson,
    required String contactNo,
    int? serviceTitleUid,
    String? remarks,
  }) {
    return _apiService.create(
      clientUid: clientUid,
      categoryUid: categoryUid,
      clientAddressUid: clientAddressUid,
      serviceTitle: serviceTitle,
      serviceDescription: serviceDescription,
      preferredServiceDate: preferredServiceDate,
      preferredServiceTime: preferredServiceTime,
      isUrgent: isUrgent,
      contactPerson: contactPerson,
      contactNo: contactNo,
      serviceTitleUid: serviceTitleUid,
      remarks: remarks,
    );
  }

  Future<CustomerServiceRequest> fetchById(int requestUid) async {
    final request = await _apiService.fetchById(requestUid);
    _persistPasscode(request);

    final history = await _progressHistoryStore.load(request.clientUid);
    final previous = history[request.uid];
    final bounced = _didBounceBack(previous, request.progressStatus);
    history[request.uid] = request.progressStatus;
    await _progressHistoryStore.save(request.clientUid, history);

    return bounced ? request.copyWithBouncedBack(true) : request;
  }

  Future<CustomerServiceRequest> cancel(CustomerServiceRequest request,
      {required String reason}) {
    return _apiService.updateStatus(
      requestUid: request.uid,
      categoryUid: request.categoryUid,
      clientAddressUid: request.clientAddressUid,
      serviceTitle: request.serviceTitle,
      serviceDescription: request.serviceDescription,
      preferredServiceDate: request.preferredServiceDate,
      preferredServiceTime: request.preferredServiceTime,
      isUrgent: request.isUrgent,
      contactPerson: request.contactPerson,
      contactNo: request.contactNo,
      status: 'Cancelled',
      remarks: request.remarks,
      cancelReason: reason,
    );
  }

  /// Hides [requestUid] from [clientUid]'s list on-device. Never touches the
  /// backend — the request stays in the database.
  Future<void> hide(int clientUid, int requestUid) =>
      _deletedStore.hide(clientUid, requestUid);
}
