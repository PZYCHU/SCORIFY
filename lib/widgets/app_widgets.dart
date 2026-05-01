import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        'Otomatis',
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
      InputType.counter => 'Akumulasi Poin',
      InputType.number => 'Angka',
      InputType.toggle => 'Toggle',
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
    final isDerived = kriteria.jenis == JenisKriteria.derived;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kriteria.nama,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    JenisChip(kriteria.jenis),
                    if (kriteria.inputType != null)
                      InputTypeChip(kriteria.inputType),
                    ArahChip(kriteria.arah),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Hapus
          ActionIconBtn(
            icon: Icons.delete_outline,
            color: AppColors.danger,
            onTap: onDelete,
          ),
          // Toggle arah — sembunyikan jika derived (selalu cost)
          if (!isDerived && onToggleArah != null) ...[
            const SizedBox(width: 6),
            ActionIconBtn(
              icon: kriteria.arah == ArahKriteria.benefit
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: AppColors.accent,
              onTap: onToggleArah!,
            ),
          ],
          if (showEdit && onEdit != null) ...[
            const SizedBox(width: 6),
            ActionIconBtn(
              icon: Icons.edit_outlined,
              color: AppColors.textSecondary,
              onTap: onEdit!,
            ),
          ],
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
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(label),
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

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Hapus',
  Color confirmColor = AppColors.danger,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
