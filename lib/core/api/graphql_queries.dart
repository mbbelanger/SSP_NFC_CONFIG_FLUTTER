class GraphQLQueries {
  // Get current user with full details
  static const String meQuery = '''
    query Me {
      me {
        id
        name
        email
        username
        status
        locations {
          id
          name
          address
          city
          state
          status
          timezone
        }
        organization {
          id
          name
        }
        session {
          waiterId
          locationId
          deviceId
          issuedAt
          expiresAt
          authMethod
        }
      }
    }
  ''';

  // Legacy alias for compatibility
  static const String getCurrentUser = meQuery;

  // Get all locations user has access to
  static const String getUserLocations = '''
    query GetUserLocations {
      getUserLocations {
        id
        name
        organization {
          id
          name
          uuid
        }
      }
    }
  ''';

  // Get tables for a location with NFC status
  static const String getLocationTables = '''
    query GetLocationTables(\$locationId: ID!) {
      getLocationTables(locationId: \$locationId) {
        id
        name
        local_id
        number_of_seats
        status
        nfcTag {
          id
          uid
          status
          label
          writtenUrl
          lastScannedAt
          registeredAt
        }
      }
    }
  ''';

  // Get all NFC tags for a location
  static const String getNFCTagsByLocation = '''
    query GetNFCTagsByLocation(\$locationId: ID!) {
      getNFCTagsByLocation(locationId: \$locationId) {
        id
        uid
        status
        label
        writtenUrl
        lastScannedAt
        registeredAt
        notes
        table {
          id
          name
          local_id
        }
        registeredBy {
          id
          name
        }
      }
    }
  ''';

  // Get single NFC tag details
  static const String getNFCTag = '''
    query GetNFCTag(\$id: ID!) {
      getNFCTag(id: \$id) {
        id
        uid
        status
        label
        writtenUrl
        lastScannedAt
        registeredAt
        notes
        table {
          id
          name
          local_id
        }
      }
    }
  ''';

  // Get NFC tag assigned to a specific table
  static const String getNFCTagByTable = '''
    query GetNFCTagByTable(\$tableId: ID!) {
      getNFCTagByTable(tableId: \$tableId) {
        id
        uid
        status
        label
        writtenUrl
        lastScannedAt
      }
    }
  ''';

  // ============================================
  // Two-Factor Authentication
  // ============================================

  static const String twoFactorStatus = '''
    query TwoFactorStatus {
      twoFactorStatus {
        enabled
        active_channel
        masked_phone
        confirmed_at
        recovery_codes_remaining
      }
    }
  ''';

  static const String twoFactorAvailability = '''
    query TwoFactorAvailability {
      twoFactorAvailability {
        totp_available
        email_available
        sms_available
        phone_number
        requires_phone_for_sms
      }
    }
  ''';

  // ============================================
  // Trusted Devices
  // ============================================

  static const String trustedDevices = '''
    query TrustedDevices {
      trustedDevices {
        devices {
          id
          device_name
          last_used_at
          expires_at
          is_active
          created_ip
        }
        count
      }
    }
  ''';

  // ============================================
  // NFC Audit Logs (backlog item for admin screen)
  // ============================================

  static const String nfcOperationLogs = '''
    query NfcOperationLogs(\$location_id: ID, \$limit: Int, \$offset: Int) {
      nfcOperationLogs(location_id: \$location_id, limit: \$limit, offset: \$offset) {
        logs {
          id
          operation
          tag_uid
          table_id
          performed_by {
            id
            name
          }
          reauth_method
          was_offline
          device_name
          created_at
        }
        total_count
      }
    }
  ''';

  // ============================================
  // Legal Documents (public endpoints)
  // ============================================

  static const String legalDocument = '''
    query LegalDocument(\$type: LegalDocumentType!, \$locale: String) {
      legalDocument(type: \$type, locale: \$locale) {
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
  ''';

  static const String legalDocuments = '''
    query LegalDocuments(\$locale: String) {
      legalDocuments(locale: \$locale) {
        id
        slug
        title
        summary
        documentType
        version
        effectiveAt
      }
    }
  ''';
}
