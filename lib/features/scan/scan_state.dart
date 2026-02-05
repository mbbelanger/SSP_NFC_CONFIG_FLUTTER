import '../../core/nfc/nfc_service.dart';
import '../../core/nfc/nfc_tag_detector.dart';
import '../../models/nfc_tag.dart';
import '../../models/table.dart';

enum ScanStatus {
  initial,
  ready,
  tagDetected,
  registering,
  claiming,  // For DNA tag claim operation
  writing,
  erasing,
  success,
  error,
}

class SessionHistoryEntry {
  final String nfcUid;
  final String tableName;
  final String tableId;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;

  const SessionHistoryEntry({
    required this.nfcUid,
    required this.tableName,
    required this.tableId,
    required this.timestamp,
    required this.success,
    this.errorMessage,
  });
}

class ScanState {
  final ScanStatus status;
  final String? detectedUid;
  final String? selectedTableId;
  final String? errorMessage;
  final List<SessionHistoryEntry> sessionHistory;
  final List<SSPTable> tables;
  final bool writeUrlEnabled;
  final bool isLoading;
  final NFCTag? registeredTag;
  final String? lastRegisteredTableName;

  // Enhanced NFC functionality
  final NFCTagInfo? tagInfo;
  final String? tagContent;
  final String? pendingUrl;
  final String? lockPassword;
  final bool isTestMode;

  // DNA tag detection
  final TagDetectionResult? detectedTagType;
  final DNATagParameters? dnaParams;
  final bool isDnaTag;

  const ScanState({
    this.status = ScanStatus.initial,
    this.detectedUid,
    this.selectedTableId,
    this.errorMessage,
    this.sessionHistory = const [],
    this.tables = const [],
    this.writeUrlEnabled = true,
    this.isLoading = false,
    this.registeredTag,
    this.lastRegisteredTableName,
    this.tagInfo,
    this.tagContent,
    this.pendingUrl,
    this.lockPassword,
    this.isTestMode = false,
    this.detectedTagType,
    this.dnaParams,
    this.isDnaTag = false,
  });

  /// Whether the "Write URL" option should be shown (only for static tags).
  bool get canWriteUrl => !isDnaTag;

  ScanState copyWith({
    ScanStatus? status,
    String? detectedUid,
    String? selectedTableId,
    String? errorMessage,
    List<SessionHistoryEntry>? sessionHistory,
    List<SSPTable>? tables,
    bool? writeUrlEnabled,
    bool? isLoading,
    NFCTag? registeredTag,
    String? lastRegisteredTableName,
    NFCTagInfo? tagInfo,
    String? tagContent,
    String? pendingUrl,
    String? lockPassword,
    bool? isTestMode,
    TagDetectionResult? detectedTagType,
    DNATagParameters? dnaParams,
    bool? isDnaTag,
  }) {
    return ScanState(
      status: status ?? this.status,
      detectedUid: detectedUid ?? this.detectedUid,
      selectedTableId: selectedTableId ?? this.selectedTableId,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      tables: tables ?? this.tables,
      writeUrlEnabled: writeUrlEnabled ?? this.writeUrlEnabled,
      isLoading: isLoading ?? this.isLoading,
      registeredTag: registeredTag ?? this.registeredTag,
      lastRegisteredTableName: lastRegisteredTableName ?? this.lastRegisteredTableName,
      tagInfo: tagInfo ?? this.tagInfo,
      tagContent: tagContent ?? this.tagContent,
      pendingUrl: pendingUrl ?? this.pendingUrl,
      lockPassword: lockPassword ?? this.lockPassword,
      isTestMode: isTestMode ?? this.isTestMode,
      detectedTagType: detectedTagType ?? this.detectedTagType,
      dnaParams: dnaParams ?? this.dnaParams,
      isDnaTag: isDnaTag ?? this.isDnaTag,
    );
  }

  ScanState reset() {
    return ScanState(
      status: ScanStatus.ready,
      sessionHistory: sessionHistory,
      tables: tables,
      writeUrlEnabled: writeUrlEnabled,
      lockPassword: lockPassword,
      isTestMode: false,
      // Reset DNA-specific state
      detectedTagType: null,
      dnaParams: null,
      isDnaTag: false,
    );
  }
}
