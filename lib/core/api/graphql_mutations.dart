class GraphQLMutations {
  // Login mutation with device token support
  static const String loginSSPUser = '''
    mutation LoginSSPUser(\$email: String!, \$password: String!, \$device_token: String) {
      loginSSPUser(email: \$email, password: \$password, device_token: \$device_token) {
        token
        expires_in
        requiresTwoFactor
        challenge_token
        device_token
        requiresOrganizationSelection
        selection_token
        user {
          id
          name
          email
          two_factor_enabled
          locations {
            id
            name
            address
            city
            state
            timezone
          }
          organization {
            id
            name
          }
        }
        organizations {
          id
          name
        }
      }
    }
  ''';

  // Verify two-factor authentication with remember device support
  static const String verifyTwoFactorAuthentication = '''
    mutation VerifyTwoFactorAuthentication(
      \$challengeToken: String!,
      \$code: String,
      \$recoveryCode: String,
      \$rememberDevice: Boolean
    ) {
      verifyTwoFactorAuthentication(
        challengeToken: \$challengeToken,
        code: \$code,
        recoveryCode: \$recoveryCode,
        rememberDevice: \$rememberDevice
      ) {
        success
        status
        token
        device_token
        user {
          id
          name
          email
        }
      }
    }
  ''';

  // Resend 2FA code
  static const String resendTwoFactorCode = '''
    mutation ResendTwoFactorCode(\$challengeToken: String!, \$method: TwoFactorMethod) {
      resendTwoFactorCode(challengeToken: \$challengeToken, method: \$method) {
        success
        message
        expires_at
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
          locations {
            id
            name
            address
            city
            state
            timezone
          }
          organization {
            id
            name
          }
        }
      }
    }
  ''';

  // Refresh token
  static const String refreshToken = '''
    mutation RefreshToken(\$refreshToken: String!) {
      refreshToken(refresh_token: \$refreshToken) {
        token
        refresh_token
        expires_in
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

  // Claim DNA tag from inventory and assign to table
  // Used for pre-encoded NTAG 424 DNA tags from GoToTags
  static const String claimNFCTag = '''
    mutation ClaimNFCTag(\$input: ClaimNFCTagInput!) {
      claimNFCTag(input: \$input) {
        id
        uid
        tagType
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
}
