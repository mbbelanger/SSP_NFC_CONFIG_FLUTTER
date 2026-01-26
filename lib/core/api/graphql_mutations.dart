class GraphQLMutations {
  // Login mutation
  static const String loginSSPUser = '''
    mutation LoginSSPUser(\$email: String!, \$password: String!) {
      loginSSPUser(email: \$email, password: \$password) {
        token
        user {
          id
          name
          email
        }
        requiresTwoFactor
        requiresOrganizationSelection
        challenge_token
        selection_token
        organizations {
          id
          name
        }
      }
    }
  ''';

  // Register a new NFC tag to a table
  static const String registerNFCTag = '''
    mutation RegisterNFCTag(\$input: RegisterNFCTagInput!) {
      registerNFCTag(input: \$input) {
        id
        uid
        status
        label
        writtenUrl
        registeredAt
        table {
          id
          name
          local_id
        }
      }
    }
  ''';

  // Update NFC tag status
  static const String updateNFCTagStatus = '''
    mutation UpdateNFCTagStatus(\$input: UpdateNFCTagStatusInput!) {
      updateNFCTagStatus(input: \$input) {
        id
        status
      }
    }
  ''';

  // Reassign NFC tag to different table
  static const String reassignNFCTag = '''
    mutation ReassignNFCTag(\$input: ReassignNFCTagInput!) {
      reassignNFCTag(input: \$input) {
        id
        writtenUrl
        table {
          id
          name
          local_id
        }
      }
    }
  ''';

  // Delete NFC tag
  static const String deleteNFCTag = '''
    mutation DeleteNFCTag(\$id: ID!) {
      deleteNFCTag(id: \$id)
    }
  ''';

  // Verify two-factor authentication
  static const String verifyTwoFactorAuthentication = '''
    mutation VerifyTwoFactorAuthentication(\$challengeToken: String!, \$code: String!) {
      verifyTwoFactorAuthentication(challengeToken: \$challengeToken, code: \$code) {
        token
        user {
          id
          name
          email
        }
      }
    }
  ''';

  // Select organization (for multi-org users)
  static const String selectOrganization = '''
    mutation SelectOrganization(\$selectionToken: String!, \$organizationId: ID!) {
      selectOrganization(selectionToken: \$selectionToken, organizationId: \$organizationId) {
        token
        user {
          id
          name
          email
        }
      }
    }
  ''';
}
