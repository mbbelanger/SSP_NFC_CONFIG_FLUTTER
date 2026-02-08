import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/legal_document.dart';
import 'legal_documents_provider.dart';

class LegalDocumentDetailScreen extends ConsumerStatefulWidget {
  final LegalDocumentType documentType;

  const LegalDocumentDetailScreen({
    super.key,
    required this.documentType,
  });

  @override
  ConsumerState<LegalDocumentDetailScreen> createState() =>
      _LegalDocumentDetailScreenState();
}

class _LegalDocumentDetailScreenState
    extends ConsumerState<LegalDocumentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(legalDocumentProvider.notifier)
          .fetchDocument(widget.documentType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(legalDocumentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.document?.title ?? widget.documentType.displayName,
        ),
      ),
      body: _buildBody(context, state, theme),
    );
  }

  Widget _buildBody(
      BuildContext context, LegalDocumentState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(legalDocumentProvider.notifier)
                      .fetchDocument(widget.documentType);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final document = state.document;
    if (document == null) {
      return const Center(
        child: Text('Document not found'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Markdown(
            data: document.content,
            selectable: true,
            padding: const EdgeInsets.all(16),
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              h1: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              h2: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              h3: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              p: theme.textTheme.bodyMedium,
              listBullet: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        _buildFooter(context, document, theme),
      ],
    );
  }

  Widget _buildFooter(
      BuildContext context, LegalDocument document, ThemeData theme) {
    final dateFormat = DateFormat.yMMMd();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Version ${document.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Effective ${dateFormat.format(document.effectiveAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
