import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ─── App Back Button ─────────────────────────────────────────────────────────

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;

  const SectionLabel(this.text, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(text, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Jenis Chip ───────────────────────────────────────────────────────────────

class JenisChip extends StatelessWidget {
  final JenisKriteria jenis;
  const JenisChip(this.jenis, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (jenis) {
      JenisKriteria.performa => (
        'Performa',
        const Color(0xFFE0F2F1),
        const Color(0xFF00695C),
      ),
      JenisKriteria.hasil => (
        'Hasil',
        const Color(0xFFE8EAF6),
        const Color(0xFF283593),
      ),
      JenisKriteria.derived => (
        'Perhitungan Remedi',
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─── Arah Chip ────────────────────────────────────────────────────────────────

class ArahChip extends StatelessWidget {
  final ArahKriteria arah;
  const ArahChip(this.arah, {super.key});

  @override
  Widget build(BuildContext context) {
    final isBenefit = arah == ArahKriteria.benefit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBenefit ? AppColors.benefitChip : AppColors.costChip,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isBenefit ? 'Benefit ↑' : 'Cost ↓',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isBenefit ? AppColors.benefitChipText : AppColors.costChipText,
        ),
      ),
    );
  }
}

// ─── Input Type Chip ──────────────────────────────────────────────────────────

class InputTypeChip extends StatelessWidget {
  final InputType? inputType;
  const InputTypeChip(this.inputType, {super.key});

  @override
  Widget build(BuildContext context) {
    if (inputType == null) return const SizedBox.shrink();
    final label = switch (inputType!) {
      InputType.counter => 'Poin Tambahan (+)',
      InputType.attendance => 'Presensi/Kehadiran (0–100)',
      InputType.number => 'Nilai Angka (0–100)',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }
}

// ─── Icon Action Button ───────────────────────────────────────────────────────

class ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const ActionIconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}

// ─── Kriteria Row (di form) ────────────────────────────────────────────────────

class KriteriaRow extends StatelessWidget {
  final Kriteria kriteria;
  final VoidCallback onDelete;
  final VoidCallback? onToggleArah; // null = tidak bisa di-toggle (derived)
  final VoidCallback? onEdit;
  final bool showEdit;

  const KriteriaRow({
    super.key,
    required this.kriteria,
    required this.onDelete,
    this.onToggleArah,
    this.onEdit,
    this.showEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kriteria.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    JenisChip(kriteria.jenis),
                    if (kriteria.inputType != null)
                      InputTypeChip(kriteria.inputType),
                    if (onToggleArah != null)
                      GestureDetector(
                        onTap: onToggleArah,
                        child: Tooltip(
                          message: 'Ketuk untuk beralih Benefit / Cost',
                          child: ArahChip(kriteria.arah),
                        ),
                      )
                    else
                      ArahChip(kriteria.arah),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (showEdit && onEdit != null) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Hapus
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onDelete,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nilai Input Row ──────────────────────────────────────────────────────────

class NilaiInputRow extends StatelessWidget {
  final Kriteria kriteria;
  final TextEditingController controller;

  const NilaiInputRow({
    super.key,
    required this.kriteria,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              kriteria.nama,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            JenisChip(kriteria.jenis),
            const SizedBox(width: 4),
            ArahChip(kriteria.arah),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(hintText: 'Masukkan angka'),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Wajib diisi';
            if (double.tryParse(v) == null) return 'Harus angka';
            return null;
          },
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ─── Bottom Save Button ───────────────────────────────────────────────────────

class BottomSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const BottomSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.border,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

Widget _buildCenteredConfirmContent(
  String title,
  String bodyText, {
  IconData? icon,
  required Color iconColor,
  required Color iconBg,
}) {
  final newlineIndex = bodyText.indexOf('\n');
  final questionIndex = bodyText.indexOf('?');

  String boldPart = '';
  String regularPart = '';
  bool regularFirst = false;

  if (newlineIndex != -1) {
    boldPart = bodyText.substring(0, newlineIndex).trim();
    regularPart = bodyText.substring(newlineIndex + 1).trim();
  } else if (questionIndex != -1) {
    final periodIndex = bodyText.lastIndexOf('.', questionIndex);
    if (periodIndex != -1 && periodIndex < questionIndex) {
      regularPart = bodyText.substring(0, periodIndex + 1).trim();
      boldPart = bodyText.substring(periodIndex + 1).trim();
      regularFirst = true;
    } else {
      boldPart = bodyText.substring(0, questionIndex + 1).trim();
      regularPart = bodyText.substring(questionIndex + 1).trim();
    }
  } else {
    boldPart = bodyText.trim();
  }

  final Widget boldWidget = Text(
    boldPart,
    textAlign: TextAlign.center,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 14.5,
      fontWeight: FontWeight.w700,
      height: 1.45,
      color: AppColors.textPrimary,
    ),
  );

  final Widget regularWidget = regularPart.isNotEmpty
      ? Text(
          regularPart,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        )
      : const SizedBox.shrink();

  Widget contentWidget;
  if (regularPart.isEmpty) {
    contentWidget = boldWidget;
  } else if (regularFirst) {
    contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        regularWidget,
        const SizedBox(height: 8),
        boldWidget,
      ],
    );
  } else {
    contentWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        boldWidget,
        const SizedBox(height: 8),
        regularWidget,
      ],
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (icon != null) ...[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 16),
      ],
      Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 10),
      contentWidget,
    ],
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Hapus',
  Color confirmColor = AppColors.danger,
  IconData? icon,
}) async {
  final lowerTitle = title.toLowerCase();
  final lowerConfirm = confirmLabel.toLowerCase();
  final isLogout = lowerTitle.contains('keluar') || lowerTitle.contains('logout');
  final isDanger = confirmColor == AppColors.danger ||
      lowerTitle.contains('hapus') ||
      lowerConfirm.contains('hapus') ||
      lowerTitle.contains('delete');

  final IconData effectiveIcon = icon ??
      (isLogout
          ? Icons.logout_rounded
          : (isDanger
              ? Icons.delete_outline_rounded
              : (lowerTitle.contains('reset')
                  ? Icons.restart_alt_rounded
                  : Icons.help_outline_rounded)));

  final Color iconColor = isLogout
      ? const Color(0xFFEF4444)
      : (isDanger ? AppColors.danger : AppColors.primary);
  final Color iconBg = isLogout
      ? const Color(0xFFFEE2E2)
      : (isDanger
          ? const Color(0xFFFEE2E2)
          : AppColors.primary.withValues(alpha: 0.12));

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCenteredConfirmContent(
              title,
              content,
              icon: effectiveIcon,
              iconColor: iconColor,
              iconBg: iconBg,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        child: Text(
                          'Batal',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      shadowColor: confirmColor.withValues(alpha: 0.35),
                    ),
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

// ─── App Feedback & Notification Panel ────────────────────────────────────────

class AppFeedback {
  static void showSuccess(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    _showSnackBar(
      context,
      message: message,
      bg: AppColors.accent,
      icon: Icons.check_circle_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      bg: AppColors.warningDark,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      bg: AppColors.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      bg: AppColors.primary,
      icon: Icons.info_outline_rounded,
    );
  }

  /// Dialog Konfirmasi Terpadu
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    String? content,
    String? message,
    String? confirmLabel,
    String? confirmText,
    String? cancelLabel,
    String? cancelText,
    bool isDanger = false,
    IconData icon = Icons.help_outline_rounded,
  }) async {
    final bodyText = content ?? message ?? '';
    final confirmBtn = confirmText ?? confirmLabel ?? 'Lanjutkan';
    final cancelBtn = cancelText ?? cancelLabel ?? 'Batal';

    final effectiveColor = isDanger ? AppColors.danger : AppColors.primary;
    final effectiveBg = isDanger
        ? const Color(0xFFFEE2E2)
        : AppColors.primary.withValues(alpha: 0.12);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCenteredConfirmContent(
                title,
                bodyText,
                icon: icon,
                iconColor: effectiveColor,
                iconBg: effectiveBg,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(ctx).pop(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          alignment: Alignment.center,
                          child: Text(
                            cancelBtn,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: effectiveColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: effectiveColor.withValues(alpha: 0.35),
                      ),
                      child: Text(
                        confirmBtn,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// Dialog Peringatan Terpadu
  static Future<void> showWarningDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCenteredConfirmContent(
                title,
                content,
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warningDark,
                iconBg: const Color(0xFFFEF3C7),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Mengerti',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog Sukses Unduh File & Share Langsung (Point 16)
  static Future<void> showDownloadSuccessSheet(
    BuildContext context, {
    required String filePath,
    required String title,
    String? message,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message ?? 'File Excel berhasil dibuat & disimpan',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Info Kotak File
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, color: Color(0xFF217346), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filePath,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tombol Buka File & Bagikan File
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await OpenFilex.open(filePath);
                        if (result.type != ResultType.done && context.mounted) {
                          AppFeedback.showWarning(context, 'Tidak ada aplikasi pendukung untuk membuka file ini');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppFeedback.showError(context, 'Gagal membuka file: $e');
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Buka File', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        // ignore: deprecated_member_use
                        await Share.shareXFiles(
                          [XFile(filePath)],
                          text: title,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          AppFeedback.showError(context, 'Gagal membagikan file: $e');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF217346),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Bagikan File',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color bg,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: bg,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
