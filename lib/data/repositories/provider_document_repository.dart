import 'dart:io';

import '../../models/provider/provider_documents.dart';
import '../../services/provider_document_api_service.dart';
import '../../utils/constants.dart';

/// Owns the provider-document data source: fetching/uploading via
/// `ProviderDocumentApiService` and resolving a stored relative path to a
/// full URL. `ProviderDocumentProvider` should keep only UI state (freshly
/// picked `File`s, loading/progress flags) and call through to this class.
class ProviderDocumentRepository {
  ProviderDocumentRepository({ProviderDocumentApiService? apiService}) : _apiService = apiService ?? ProviderDocumentApiService();

  final ProviderDocumentApiService _apiService;

  Future<ProviderDocumentsModel?> fetchDocuments(int providerUid) => _apiService.fetchDocuments(providerUid);

  /// Each file is optional - omitting one leaves that slot's already-stored
  /// image untouched server-side (see api.txt). The provider's first-ever
  /// submission still requires all three; the backend enforces that.
  Future<ProviderDocumentsModel> upload({
    required int providerUid,
    File? profilePhoto,
    File? cnicFront,
    File? cnicBack,
    void Function(double progress)? onProgress,
  }) {
    return _apiService.uploadDocuments(
      providerUid: providerUid,
      profilePhoto: profilePhoto,
      cnicFront: cnicFront,
      cnicBack: cnicBack,
      onProgress: onProgress,
    );
  }

  /// [version] busts Flutter's image cache (and any HTTP cache) after a
  /// re-upload: the three document files always live at the same fixed
  /// path (profile.jpg/cnic_front.jpg/cnic_back.jpg), so a plain URL is
  /// byte-identical before and after an edit and `Image.network`/
  /// `NetworkImage` - which cache by URL - would keep showing the old image
  /// until the app restarts. Passing the document row's `updatedOn` (or
  /// `createdOn` for a first-ever upload) as a query param gives each edit
  /// a distinct URL so the new image is actually fetched.
  String? resolveUrl(String? relativePath, {DateTime? version}) {
    if (relativePath == null) return null;
    final base = '$kApiFileBaseUrl/$relativePath';
    if (version == null) return base;
    return '$base?v=${version.millisecondsSinceEpoch}';
  }
}
