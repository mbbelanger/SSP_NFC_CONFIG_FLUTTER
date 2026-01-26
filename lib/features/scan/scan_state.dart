import '../../models/nfc_tag.dart';
import '../../models/table.dart';

enum ScanStatus {
  initial,
  ready,
  tagDetected,
  registering,
  writing,
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
  });

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
    );
  }

  ScanState reset() {
    return ScanState(
      status: ScanStatus.ready,
      sessionHistory: sessionHistory,
      tables: tables,
      writeUrlEnabled: writeUrlEnabled,
    );
  }
}
