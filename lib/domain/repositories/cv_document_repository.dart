import '../entities/cv_document.dart';

/// Persistence and versioning for CV documents, following the project's
/// Supabase-first + SharedPreferences fallback pattern.
abstract class CvDocumentRepository {
  /// Creates (or replaces) a document's metadata. Returns the saved document.
  Future<CvDocument> createDocument(CvDocument document);

  /// All documents owned by the user, newest first (empty when none).
  Future<List<CvDocument>> loadDocuments();

  /// A single document by id, or null.
  Future<CvDocument?> loadDocument(String id);

  /// Removes a document and all of its versions.
  Future<void> deleteDocument(String id);

  /// Appends (or replaces) a version and returns it with a deterministic
  /// version number. The next version is `max(existing) + 1`.
  Future<CvVersion> createVersion(CvVersion version);

  /// All versions of a document, oldest first.
  Future<List<CvVersion>> loadVersions(String documentId);

  /// The most recent version of a document, or null.
  Future<CvVersion?> loadLatestVersion(String documentId);

  /// A single version by id, or null.
  Future<CvVersion?> loadVersion(String versionId);

  /// Upserts a version without changing its version number.
  Future<void> saveVersion(CvVersion version);
}
