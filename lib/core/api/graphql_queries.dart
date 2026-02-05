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
}
