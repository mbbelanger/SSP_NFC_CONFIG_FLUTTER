/// Represents a legal document served by the platform.
class LegalDocument {
  final String id;
  final String slug;
  final String title;
  final String? summary;
  final String documentType;
  final String version;
  final String locale;
  final String content;
  final DateTime effectiveAt;
  final DateTime? publishedAt;

  const LegalDocument({
    required this.id,
    required this.slug,
    required this.title,
    this.summary,
    required this.documentType,
    required this.version,
    required this.locale,
    required this.content,
    required this.effectiveAt,
    this.publishedAt,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      documentType: json['documentType'] as String,
      version: json['version'] as String,
      locale: json['locale'] as String,
      content: json['content'] as String,
      effectiveAt: DateTime.parse(json['effectiveAt'] as String),
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'summary': summary,
      'documentType': documentType,
      'version': version,
      'locale': locale,
      'content': content,
      'effectiveAt': effectiveAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}

/// Enum for legal document types matching the GraphQL schema.
enum LegalDocumentType {
  privacyPolicy('PRIVACY_POLICY', 'Privacy Policy'),
  termsOfService('TERMS_OF_SERVICE', 'Terms of Service'),
  acceptableUsePolicy('ACCEPTABLE_USE_POLICY', 'Acceptable Use Policy'),
  cookiePolicy('COOKIE_POLICY', 'Cookie Policy'),
  eula('EULA', 'End User License Agreement');

  final String value;
  final String displayName;

  const LegalDocumentType(this.value, this.displayName);

  static LegalDocumentType fromString(String value) {
    return LegalDocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LegalDocumentType.privacyPolicy,
    );
  }
}
