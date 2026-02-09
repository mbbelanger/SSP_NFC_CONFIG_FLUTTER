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
  // Note: User data is already returned from loginSSPUser (step 1), reuse it after 2FA succeeds
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

  // ============================================
  // Social Login
  // ============================================

  static const String socialLogin = '''
    mutation SocialLogin(\$input: SocialLoginInput!, \$device_token: String, \$device_name: String) {
      socialLogin(input: \$input, device_token: \$device_token, device_name: \$device_name) {
        token
        expires_in
        requiresTwoFactor
        challenge_token
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

  // ============================================
  // Two-Factor Authentication Setup & Management
  // ============================================

  static const String enableTwoFactorAuthentication = '''
    mutation EnableTwoFactor(\$channel: TwoFactorChannel!, \$phone: String) {
      enableTwoFactorAuthentication(channel: \$channel, phone: \$phone) {
        qr_code
        channel
        message
        code_expires_at
      }
    }
  ''';

  static const String confirmTwoFactorAuthentication = '''
    mutation ConfirmTwoFactor(\$code: String!) {
      confirmTwoFactorAuthentication(code: \$code) {
        success
        channel
        recovery_codes
      }
    }
  ''';

  static const String disableTwoFactorAuthentication = '''
    mutation DisableTwoFactor(\$currentPassword: String, \$code: String) {
      disableTwoFactorAuthentication(currentPassword: \$currentPassword, code: \$code) {
        status
      }
    }
  ''';

  static const String regenerateTwoFactorRecoveryCodes = '''
    mutation RegenerateRecoveryCodes(\$password: String!) {
      regenerateTwoFactorRecoveryCodes(password: \$password) {
        recovery_codes
        count
      }
    }
  ''';

  // ============================================
  // Trusted Devices Management
  // ============================================

  static const String revokeTrustedDevice = '''
    mutation RevokeDevice(\$deviceId: ID!) {
      revokeTrustedDevice(deviceId: \$deviceId) {
        success
        message
      }
    }
  ''';

  static const String revokeAllTrustedDevices = '''
    mutation RevokeAllDevices {
      revokeAllTrustedDevices {
        success
        revoked_count
      }
    }
  ''';

  // ============================================
  // NFC Write Authorization (Re-Authentication)
  // ============================================

  static const String requestNfcWriteAuthorization = '''
    mutation RequestNfcWriteAuth(\$input: ReAuthInput!) {
      requestNfcWriteAuthorization(input: \$input) {
        nfc_write_token
        expires_at
        single_use
      }
    }
  ''';

  static const String requestNfcBulkWriteAuthorization = '''
    mutation RequestNfcBulkAuth(\$input: ReAuthInput!) {
      requestNfcBulkWriteAuthorization(input: \$input) {
        nfc_write_token
        expires_at
        max_operations
        single_use
      }
    }
  ''';

  // ============================================
  // App PIN Management
  // ============================================

  static const String setupAppPin = '''
    mutation SetupAppPin(\$pin: String!, \$device_id: String!) {
      setupAppPin(pin: \$pin, device_id: \$device_id) {
        success
        message
      }
    }
  ''';

  static const String changeAppPin = '''
    mutation ChangeAppPin(\$current_pin: String!, \$new_pin: String!, \$device_id: String!) {
      changeAppPin(current_pin: \$current_pin, new_pin: \$new_pin, device_id: \$device_id) {
        success
        message
      }
    }
  ''';

  static const String resetAppPin = '''
    mutation ResetAppPin(\$password: String!, \$new_pin: String!, \$two_factor_code: String, \$device_id: String!) {
      resetAppPin(password: \$password, new_pin: \$new_pin, two_factor_code: \$two_factor_code, device_id: \$device_id) {
        success
        message
      }
    }
  ''';
}
