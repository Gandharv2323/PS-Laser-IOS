import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

/// Firestore Backup & Restore
/// - Export: reads all Firestore collections → JSON file
/// - Import: reads a ForgeOps JSON backup → batch-writes back to Firestore
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _exporting = false;
  bool _importing = false;
  String? _lastMessage;
  bool _lastWasError = false;

  static const _collections = [
    'employees',
    'attendance',
    'work_orders',
    'inventory',
    'inventory_transactions',
    'machines',
    'cylinders',
    'payroll',
    'alerts',
    'leaves',
    'clients',
    'orders',
  ];

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> _exportDatabase() async {
    setState(() {
      _exporting = true;
      _lastMessage = null;
    });

    try {
      final backup = <String, dynamic>{};
      for (final col in _collections) {
        final snap = await FirestoreService.db.collection(col).get();
        backup[col] = {
          for (final doc in snap.docs) doc.id: doc.data(),
        };
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      final bytes = utf8.encode(jsonStr);

      final timestamp = DateTime.now()
          .toString()
          .replaceAll(RegExp(r'[:\s.]'), '-')
          .substring(0, 19);
      final filename = 'forgeops_backup_$timestamp.json';

      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: filename,
        type: FileType.any,
      );

      if (outputPath == null) {
        final dir = await _getDownloadsDirectory();
        outputPath = '${dir.path}/$filename';
      }

      await File(outputPath).writeAsBytes(bytes);
      _showResult(
        '✅ Backup saved successfully!\n\nFile: $filename\nCollections: ${_collections.length}\nDocs exported: ${backup.values.fold<int>(0, (s, v) => s + (v as Map).length)}',
        isError: false,
      );
    } catch (e) {
      _showResult('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> _importDatabase() async {
    final confirmed = await _showConfirmDialog(
      title: 'Restore from Backup?',
      message:
          'This will OVERWRITE all matching Firestore data with the backup file.\n\nExisting records with the same ID will be replaced. Are you sure?',
      confirmLabel: 'Yes, Restore',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _importing = true;
      _lastMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select ForgeOps Backup File (.json)',
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _importing = false);
        return;
      }

      final sourcePath = result.files.first.path;
      if (sourcePath == null) {
        _showResult('Could not access the selected file.', isError: true);
        return;
      }

      final jsonStr = await File(sourcePath).readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      int totalDocs = 0;
      for (final col in data.keys) {
        final colData = data[col] as Map<String, dynamic>;
        // Firestore batch supports max 500 writes; chunked writes
        final entries = colData.entries.toList();
        for (int i = 0; i < entries.length; i += 400) {
          final batch = FirestoreService.db.batch();
          final chunk = entries.sublist(
            i,
            (i + 400) < entries.length ? i + 400 : entries.length,
          );
          for (final entry in chunk) {
            final ref = FirestoreService.db.collection(col).doc(entry.key);
            batch.set(ref, entry.value as Map<String, dynamic>);
            totalDocs++;
          }
          await batch.commit();
        }
      }

      _showResult(
        '✅ Restore complete!\n\n$totalDocs documents written across ${data.keys.length} collections.\n\nRestart the app for all changes to reflect.',
        isError: false,
      );
    } catch (e) {
      _showResult('Import failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showResult(String message, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _lastMessage = message;
      _lastWasError = isError;
    });
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final dl = Directory('/storage/emulated/0/Download');
      if (await dl.exists()) return dl;
    }
    return getApplicationDocumentsDirectory();
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  destructive ? AppTheme.accentRed : AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Restore',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Firestore Backup',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          'Export all ${_collections.length} collections to JSON',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Warning ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.accentOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.accentOrange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Restoring overwrites all matching Firestore docs. Keep backups in a secure location (Google Drive, etc.).',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Export ──────────────────────────────────────────────────
            _sectionLabel('EXPORT BACKUP', isDark),
            const SizedBox(height: 12),
            _actionCard(
              isDark: isDark,
              icon: Icons.cloud_upload_outlined,
              iconColor: const Color(0xFF059669),
              title: 'Export to JSON',
              subtitle:
                  'Reads all ${_collections.length} Firestore collections and saves a JSON backup file you can store anywhere.',
              buttonLabel: 'Export Now',
              buttonColor: const Color(0xFF059669),
              loading: _exporting,
              onTap: _exporting ? null : _exportDatabase,
            ),
            const SizedBox(height: 24),

            // ── Import ──────────────────────────────────────────────────
            _sectionLabel('RESTORE FROM BACKUP', isDark),
            const SizedBox(height: 12),
            _actionCard(
              isDark: isDark,
              icon: Icons.cloud_download_outlined,
              iconColor: AppTheme.accentRed,
              title: 'Restore from JSON',
              subtitle:
                  'Pick a ForgeOps .json backup file. All documents will be written back to Firestore with the original IDs.',
              buttonLabel: 'Choose Backup File',
              buttonColor: AppTheme.accentRed,
              loading: _importing,
              onTap: _importing ? null : _importDatabase,
            ),
            const SizedBox(height: 24),

            // ── Status ──────────────────────────────────────────────────
            if (_lastMessage != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lastWasError
                      ? AppTheme.accentRed.withValues(alpha: 0.1)
                      : const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lastWasError
                        ? AppTheme.accentRed.withValues(alpha: 0.3)
                        : const Color(0xFF059669).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _lastWasError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _lastWasError
                          ? AppTheme.accentRed
                          : const Color(0xFF059669),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _lastMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _lastWasError
                              ? AppTheme.accentRed
                              : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Tips ────────────────────────────────────────────────────
            _sectionLabel('BEST PRACTICES', isDark),
            const SizedBox(height: 12),
            ...[
              ('Export weekly', 'Set a reminder to export every Monday morning.'),
              (
                'Store in cloud',
                'Save backups to Google Drive or OneDrive for safety.'
              ),
              (
                'Test restores',
                'Periodically verify that backups can be restored correctly.'
              ),
              (
                'Before updates',
                'Always export before major app or Firestore rule changes.'
              ),
            ].map((tip) => _tipRow(tip.$1, tip.$2, isDark)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: const Color(0xFF6B7280),
        ),
      );

  Widget _actionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required bool loading,
    required VoidCallback? onTap,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827))),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(icon, size: 16),
                label: Text(
                  loading ? 'Please wait...' : buttonLabel,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tipRow(String title, String body, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.tips_and_updates_outlined,
                size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827)),
                    ),
                    TextSpan(
                      text: body,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
