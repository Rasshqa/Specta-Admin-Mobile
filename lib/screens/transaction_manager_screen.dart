import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/admin_provider.dart';
import '../theme/specta_theme.dart';

class TransactionManagerScreen extends StatefulWidget {
  const TransactionManagerScreen({super.key});

  @override
  State<TransactionManagerScreen> createState() =>
      _TransactionManagerScreenState();
}

class _TransactionManagerScreenState extends State<TransactionManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPendingTransactions();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<AdminProvider>().fetchPendingTransactions();
  }

  void _showProofDialog(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => Dialog(
        backgroundColor: SpectaTheme.slateGlass,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: SpectaTheme.neonPurple.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'PAYMENT PROOF',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: SpectaTheme.neonCyan,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.x, color: SpectaTheme.textMuted),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.55,
              width: double.infinity,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: SpectaTheme.neonPurple,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.imageOff,
                          color: SpectaTheme.textMuted,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load image',
                          style: GoogleFonts.orbitron(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(AdminProvider admin, SpectaTransaction tx) async {
    final ok = await admin.approveTransaction(tx.invoice);
    if (!mounted) return;
    if (ok) {
      _showSnack('${tx.invoice} approved', SpectaTheme.neonCyan);
    } else if (admin.error != null) {
      _showSnack(admin.error!, Colors.redAccent);
    }
  }

  Future<void> _handleReject(AdminProvider admin, SpectaTransaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpectaTheme.slateGlass,
        title: Text(
          'REJECT TRANSACTION?',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          'Reject ${tx.invoice} for ${tx.buyerName}? Quota will be restored.',
          style: const TextStyle(color: SpectaTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'REJECT',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await admin.rejectTransaction(tx.invoice);
    if (!mounted) return;
    if (ok) {
      _showSnack('${tx.invoice} rejected', SpectaTheme.neonPurple);
    } else if (admin.error != null) {
      _showSnack(admin.error!, Colors.redAccent);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: SpectaTheme.slateBg,
      appBar: AppBar(
        backgroundColor: SpectaTheme.slateBg,
        elevation: 0,
        title: Text(
          'MANAGE TRANSACTIONS',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: SpectaTheme.neonCyan,
            shadows: SpectaTheme.neonGlowCyan,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: SpectaTheme.textMuted),
            onPressed: admin.isLoading ? null : _onRefresh,
          ),
        ],
      ),
      body: _buildBody(admin),
    );
  }

  Widget _buildBody(AdminProvider admin) {
    if (admin.isLoading && admin.pendingTransactions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: SpectaTheme.neonPurple),
      );
    }

    if (admin.error != null && admin.pendingTransactions.isEmpty) {
      return _buildErrorState(admin);
    }

    if (admin.pendingTransactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: SpectaTheme.neonPurple,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.inbox,
                    size: 48,
                    color: SpectaTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO PENDING TRANSACTIONS',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All caught up. Pull down to refresh.',
                    style: TextStyle(color: SpectaTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: SpectaTheme.neonPurple,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: admin.pendingTransactions.length,
        itemBuilder: (context, index) {
          final tx = admin.pendingTransactions[index];
          return _TransactionCard(
            transaction: tx,
            isApproving: admin.isApproving(tx.invoice),
            isRejecting: admin.isRejecting(tx.invoice),
            onProofTap: tx.paymentProofUrl != null
                ? () => _showProofDialog(tx.paymentProofUrl!)
                : null,
            onApprove: () => _handleApprove(admin, tx),
            onReject: () => _handleReject(admin, tx),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(AdminProvider admin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.wifiOff, color: SpectaTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'CONNECTION ERROR',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              admin.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: SpectaTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final SpectaTransaction transaction;
  final bool isApproving;
  final bool isRejecting;
  final VoidCallback? onProofTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _TransactionCard({
    required this.transaction,
    required this.isApproving,
    required this.isRejecting,
    this.onProofTap,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpectaTheme.slateGlass.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SpectaTheme.neonPurple.withValues(alpha: 0.25),
        ),
        boxShadow: SpectaTheme.neonGlowPurple,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.invoice,
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      transaction.buyerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      transaction.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SpectaTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.ticketQuantity} ticket(s) · ${_formatDate(transaction.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: SpectaTheme.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: transaction.status),
            ],
          ),
          if (transaction.paymentProofUrl != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onProofTap,
              child: Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SpectaTheme.neonCyan.withValues(alpha: 0.4),
                  ),
                  boxShadow: SpectaTheme.neonGlowCyan,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      transaction.paymentProofUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(
                          LucideIcons.imageOff,
                          color: SpectaTheme.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.zoomIn,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap thumbnail to verify proof',
              style: TextStyle(
                fontSize: 10,
                color: SpectaTheme.neonCyan.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'APPROVE',
                  color: SpectaTheme.neonCyan,
                  isLoading: isApproving,
                  onPressed: (isApproving || isRejecting) ? null : onApprove,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'REJECT',
                  color: Colors.redAccent,
                  isLoading: isRejecting,
                  onPressed: (isApproving || isRejecting) ? null : onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} ${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final TransactionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case TransactionStatus.success:
        color = SpectaTheme.neonCyan;
        break;
      case TransactionStatus.rejected:
        color = Colors.redAccent;
        break;
      case TransactionStatus.pendingProof:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.apiValue,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            color: color.withValues(alpha: 0.12),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
