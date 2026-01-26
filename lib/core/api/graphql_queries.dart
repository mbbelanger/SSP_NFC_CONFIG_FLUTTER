class GraphQLQueries {
  // Authentication check
  static const String getCurrentUser = '''
    query GetCurrentUser {
      me {
        id
        name
        email
      }
    }
  ''';

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
