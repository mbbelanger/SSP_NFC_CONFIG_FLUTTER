# Legal Documents API Reference

API reference for the legal documents system. All endpoints are **public** (no authentication required) and serve the same content across REST and GraphQL.

---

## Overview

| Aspect | Value |
|--------|-------|
| **Authentication** | None required (public endpoints) |
| **REST Base URL** | `https://api.ssppos.com/api/legal` |
| **GraphQL Endpoint** | `https://api.ssppos.com/graphql` |
| **Content Format** | Markdown (raw), JSON, or pre-rendered HTML |
| **Caching** | 24 hours (`Cache-Control: public, max-age=86400`) |
| **Localization** | `?locale=en` (default: `en`) |

---

## Document Types

| GraphQL Enum | REST Slug | Description |
|--------------|-----------|-------------|
| `PRIVACY_POLICY` | `privacy-policy` | Privacy & Security Policy |
| `TERMS_OF_SERVICE` | `terms-of-service` | Terms of Service |
| `ACCEPTABLE_USE_POLICY` | `acceptable-use-policy` | Acceptable Use Policy |
| `COOKIE_POLICY` | `cookie-policy` | Cookie Policy |
| `EULA` | `eula` | End User License Agreement |

---

## REST API

### `GET /api/legal`

List all current legal documents. Use this to build a legal index page or settings screen.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `locale` | string | `en` | Language code |

**Response:**

```json
{
  "data": [
    {
      "slug": "privacy-policy",
      "title": "Privacy & Security Policy",
      "summary": "How we collect, use, and protect your data.",
      "document_type": "privacy-policy",
      "version": "1.0.0",
      "locale": "en",
      "effective_at": "2025-01-01T00:00:00+00:00",
      "url": "https://api.ssppos.com/api/legal/privacy-policy"
    }
  ]
}
```

**Response Headers:**

| Header | Value |
|--------|-------|
| `Cache-Control` | `public, max-age=86400` |

---

### `GET /api/legal/{slug}`

Get a single legal document by slug. Supports multiple output formats.

**Path Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `slug` | string | Document slug (e.g., `privacy-policy`) |

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `format` | string | `json` | Response format: `json`, `text`, or `html` |
| `locale` | string | `en` | Language code |

#### Format: `json` (default)

```
GET /api/legal/privacy-policy
GET /api/legal/privacy-policy?format=json
```

```json
{
  "document": {
    "slug": "privacy-policy",
    "title": "Privacy & Security Policy",
    "summary": "How we collect, use, and protect your data.",
    "document_type": "privacy-policy",
    "version": "1.0.0",
    "locale": "en",
    "content": "# Privacy & Security Policy\n\n...",
    "effective_at": "2025-01-01T00:00:00+00:00",
    "published_at": "2025-01-01T00:00:00+00:00"
  }
}
```

#### Format: `text`

Returns raw markdown. Useful for POS terminals or any client that renders markdown natively.

```
GET /api/legal/privacy-policy?format=text
```

```
Content-Type: text/plain; charset=UTF-8
```

```markdown
# Privacy & Security Policy

SSP Systems Ltd. ("we", "our", or "us") operates the SSP POS ecosystem...
```

#### Format: `html`

Returns a full standalone HTML page with SSP dark theme. Can be embedded in a WebView or iframe.

```
GET /api/legal/privacy-policy?format=html
```

```
Content-Type: text/html; charset=UTF-8
```

Returns a complete `<!DOCTYPE html>` page with rendered markdown, dark theme styling, version metadata, and copyright footer.

**Response Headers (all formats):**

| Header | Value |
|--------|-------|
| `Cache-Control` | `public, max-age=86400` |
| `X-Document-Version` | Document version (e.g., `1.0.0`) |
| `X-Copyright` | `2026 SSP Systems Ltd` |

**Error Response (404):**

```json
{
  "error": "Legal document not found."
}
```

---

## GraphQL API

All queries are public — no `Authorization` header required.

### `legalDocument` — Get Single Document

Retrieve the current version of a specific document type.

```graphql
query {
  legalDocument(type: PRIVACY_POLICY, locale: "en") {
    id
    slug
    title
    summary
    documentType
    version
    locale
    content
    effectiveAt
    publishedAt
  }
}
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `type` | `LegalDocumentType!` | Yes | — | Document type enum |
| `locale` | `String` | No | `"en"` | Language code |

**Returns:** `LegalDocument` (nullable — returns `null` if no document exists for the given type/locale).

---

### `legalDocuments` — List All Current Documents

Retrieve all current legal documents. Use for building index pages or settings screens.

```graphql
query {
  legalDocuments(locale: "en") {
    slug
    title
    summary
    documentType
    version
    effectiveAt
  }
}
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `locale` | `String` | No | `"en"` | Language code |

**Returns:** `[LegalDocument!]!` (non-nullable array — returns empty `[]` if no documents exist).

---

### `legalDocumentHistory` — Version History

Retrieve all published versions of a document type, newest first.

```graphql
query {
  legalDocumentHistory(type: PRIVACY_POLICY, locale: "en") {
    version
    effectiveAt
    publishedAt
  }
}
```

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `type` | `LegalDocumentType!` | Yes | — | Document type enum |
| `locale` | `String` | No | `"en"` | Language code |

**Returns:** `[LegalDocument!]!` (ordered by `effectiveAt` descending).

---

### `LegalDocument` Type

```graphql
type LegalDocument {
  id: ID!
  slug: String!              # URL-friendly identifier (e.g., "privacy-policy")
  title: String!             # Human-readable title
  summary: String            # Short excerpt for list views
  documentType: String!      # Classification key (e.g., "privacy-policy")
  version: String!           # Semantic version (e.g., "1.0.0")
  locale: String!            # Language code (e.g., "en")
  content: String!           # Full document in markdown format
  effectiveAt: DateTime!     # When this version becomes legally effective
  publishedAt: DateTime      # When this version was published
}
```

---

## Recommended Usage by Client

| Client | Approach | Notes |
|--------|----------|-------|
| **SSP Manager** (Next.js) | GraphQL `legalDocuments` for list, `legalDocument(type)` for full view | Render markdown client-side with `react-markdown` or similar |
| **ssppos.com** (Next.js) | REST `?format=html` for direct embedding, or GraphQL for custom rendering | HTML format gives a ready-made styled page; embed in iframe or fetch and inject |
| **Flutter mobile** | GraphQL `legalDocuments` for list with `summary`, `legalDocument(type)` for full content | Use `flutter_markdown` package to render content; `summary` field for settings screen one-liners |
| **POS terminal** | REST `?format=text` | Plain markdown for receipt-friendly or terminal display |

---

## Caching

- All responses include `Cache-Control: public, max-age=86400` (24 hours)
- Backend service layer caches database queries for 24 hours
- When a new document version is published, the server-side cache is automatically invalidated
- Clients should respect the `Cache-Control` header and cache locally where possible
- The `X-Document-Version` response header can be used to detect version changes

---

## Quick Examples

### cURL

```bash
# List all documents
curl https://api.ssppos.com/api/legal

# Get privacy policy as JSON
curl https://api.ssppos.com/api/legal/privacy-policy

# Get terms of service as rendered HTML
curl https://api.ssppos.com/api/legal/terms-of-service?format=html

# Get EULA as raw markdown
curl https://api.ssppos.com/api/legal/eula?format=text
```

### JavaScript (fetch)

```javascript
// Fetch all documents for a settings page
const res = await fetch('https://api.ssppos.com/api/legal');
const { data } = await res.json();
// data = [{ slug, title, summary, document_type, version, ... }]

// Fetch a single document
const res = await fetch('https://api.ssppos.com/api/legal/privacy-policy');
const { document } = await res.json();
// document.content contains the markdown
```

### GraphQL

```graphql
# Settings screen — show all legal docs with one-liner summaries
query LegalIndex {
  legalDocuments {
    slug
    title
    summary
    version
    effectiveAt
  }
}

# Full document view
query LegalDocument {
  legalDocument(type: PRIVACY_POLICY) {
    title
    content
    version
    effectiveAt
  }
}
```

### Dart (Flutter)

```dart
// Using graphql_flutter or http package
final query = '''
  query {
    legalDocuments {
      slug
      title
      summary
      documentType
      version
    }
  }
''';

// For full document (render with flutter_markdown)
final docQuery = '''
  query {
    legalDocument(type: PRIVACY_POLICY) {
      title
      content
      version
      effectiveAt
    }
  }
''';
```
