class ErrorMessages {
  // NFC Errors
  static const nfcNotAvailable = 'NFC is not available on this device';
  static const nfcNotEnabled = 'Please enable NFC in your device settings';
  static const tagNotSupported = 'This tag type is not supported';
  static const tagNotWritable = 'This tag is write-protected';
  static const tagTooSmall = 'URL is too long for this tag';
  static const tagReadFailed = 'Failed to read tag. Try again.';
  static const tagWriteFailed = 'Failed to write to tag. Keep phone steady.';
  static const tagRemoved = 'Tag was removed. Keep phone on tag while writing.';

  // API Errors
  static const uidDuplicate = 'This NFC tag is already registered.';
  static const tableHasTag = 'This table already has an active NFC tag.';
  static const tableNotFound = 'Table not found.';
  static const permissionDenied = "You don't have permission to manage NFC tags.";
  static const networkError = 'Network error. Check your connection.';
  static const serverError = 'Server error. Please try again later.';
  static const sessionExpired = 'Session expired. Please log in again.';

  // Auth Errors
  static const invalidCredentials = 'Invalid email or password.';
  static const emailRequired = 'Email is required.';
  static const passwordRequired = 'Password is required.';
  static const invalidEmail = 'Please enter a valid email address.';

  // General
  static const unknownError = 'Something went wrong. Please try again.';
}
