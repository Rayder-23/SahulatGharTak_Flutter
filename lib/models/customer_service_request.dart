class CustomerServiceRequest {
  final int uid;
  final int clientUid;
  final String clientName;
  final int categoryUid;
  final String categoryName;
  final int clientAddressUid;
  final String addressTitle;
  final String serviceTitle;
  final String serviceDescription;
  final String preferredServiceDate;
  final String preferredServiceTime;
  final bool isUrgent;
  final String contactPerson;
  final String contactNo;
  final double estimatedBudget;
  final String status;

  /// Computed, read-only progress-bar stage from the API — one of
  /// [kRequestStatusSteps]'s values, or `null` when the request/its booking
  /// is Cancelled. Never derive UI progress from [status] directly; the
  /// backend keeps `status` coarse (Initiated/Assigned/Completed/Cancelled)
  /// while this field reflects the real granular booking state. See
  /// docs/status-workflow.md.
  final String? progressStatus;

  final String? remarks;
  final String? cancelReason;
  final DateTime createdOn;
  final int? providerUid;
  final String? providerName;
  final String? providerMobileNo;
  final String? providerProfilePhotoPath;
  final String? providerCnic;
  final String? passcode;

  /// True when this fetch observed `progressStatus` regress from
  /// `Assigned`/`In Progress` back to `Requested` for this same request UID,
  /// compared to the last fetch — i.e. the provider cancelled an accepted
  /// booking and the request is being re-dispatched (see api.txt v3.22).
  /// Never comes from the API; set client-side by
  /// [CustomerServiceRequestRepository] via [RequestProgressHistoryStore].
  final bool bouncedBack;

  const CustomerServiceRequest({
    required this.uid,
    required this.clientUid,
    required this.clientName,
    required this.categoryUid,
    required this.categoryName,
    required this.clientAddressUid,
    required this.addressTitle,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.preferredServiceDate,
    required this.preferredServiceTime,
    required this.isUrgent,
    required this.contactPerson,
    required this.contactNo,
    required this.estimatedBudget,
    required this.status,
    this.progressStatus,
    this.remarks,
    this.cancelReason,
    required this.createdOn,
    this.providerUid,
    this.providerName,
    this.providerMobileNo,
    this.providerProfilePhotoPath,
    this.providerCnic,
    this.passcode,
    this.bouncedBack = false,
  });

  /// Returns a copy with [bouncedBack] overridden — used by
  /// [CustomerServiceRequestRepository] to flag a detected regression
  /// without re-parsing the API response.
  CustomerServiceRequest copyWithBouncedBack(bool value) => CustomerServiceRequest(
        uid: uid,
        clientUid: clientUid,
        clientName: clientName,
        categoryUid: categoryUid,
        categoryName: categoryName,
        clientAddressUid: clientAddressUid,
        addressTitle: addressTitle,
        serviceTitle: serviceTitle,
        serviceDescription: serviceDescription,
        preferredServiceDate: preferredServiceDate,
        preferredServiceTime: preferredServiceTime,
        isUrgent: isUrgent,
        contactPerson: contactPerson,
        contactNo: contactNo,
        estimatedBudget: estimatedBudget,
        status: status,
        progressStatus: progressStatus,
        remarks: remarks,
        cancelReason: cancelReason,
        createdOn: createdOn,
        providerUid: providerUid,
        providerName: providerName,
        providerMobileNo: providerMobileNo,
        providerProfilePhotoPath: providerProfilePhotoPath,
        providerCnic: providerCnic,
        passcode: passcode,
        bouncedBack: value,
      );

  factory CustomerServiceRequest.fromJson(Map<String, dynamic> json) {
    return CustomerServiceRequest(
      uid: json['uid'] as int,
      clientUid: json['clientUid'] as int,
      clientName: json['clientName'] as String? ?? '',
      categoryUid: json['categoryUid'] as int,
      categoryName: json['categoryName'] as String? ?? '',
      clientAddressUid: json['clientAddressUid'] as int,
      addressTitle: json['addressTitle'] as String? ?? '',
      serviceTitle: json['serviceTitle'] as String? ?? '',
      serviceDescription: json['serviceDescription'] as String? ?? '',
      preferredServiceDate: json['preferredServiceDate'] as String? ?? '',
      preferredServiceTime: json['preferredServiceTime'] as String? ?? '',
      isUrgent: json['isUrgent'] as bool? ?? false,
      contactPerson: json['contactPerson'] as String? ?? '',
      contactNo: json['contactNo'] as String? ?? '',
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Initiated',
      progressStatus: json['progressStatus'] as String?,
      remarks: json['remarks'] as String?,
      cancelReason: json['cancelReason'] as String?,
      createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn'] as String) : DateTime.now(),
      providerUid: json['providerUid'] as int?,
      providerName: json['providerName'] as String?,
      providerMobileNo: json['providerMobileNo'] as String?,
      providerProfilePhotoPath: json['providerProfilePhotoPath'] as String?,
      providerCnic: json['providerCnic'] as String?,
      passcode: json['passcode'] as String?,
    );
  }
}
