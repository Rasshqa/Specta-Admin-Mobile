import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/specta_theme.dart';
import 'transaction_manager_screen.dart';
import 'manual_input_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await ApiService().getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openTransactionManager() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const TransactionManagerScreen(),
      ),
    );
    if (mounted) _loadStats();
  }

  String _formatFullCurrency(dynamic value) {
    final num amount = value is num ? value : 0;
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  int _intStat(String key) {
    final v = _stats?[key];
    if (v is num) return v.toInt();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final pendingCount = _intStat('pending_transactions');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SpectaTheme.slateBg,
        elevation: 0,
        title: Text(
          'COMMAND CENTER',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SpectaTheme.neonPurple,
            shadows: SpectaTheme.neonGlowPurple,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: SpectaTheme.textMuted),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: SpectaTheme.textMuted),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: SpectaTheme.neonPurple),
            )
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  color: SpectaTheme.neonPurple,
                  child: _buildContent(user, pendingCount),
                ),
    );
  }

  Widget _buildErrorState() {
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
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: SpectaTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? user, int pendingCount) {
    final List recentTx = _stats?['recent_transactions'] ?? [];
    final List ticketQuotas = _stats?['ticket_quotas'] ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeCard(user),
          const SizedBox(height: 24),
          Text(
            'OPERATIONAL STATS',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SpectaTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          _buildRevenueCard(),
          if (ticketQuotas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildQuotaSection(ticketQuotas),
          ],
          const SizedBox(height: 24),
          Text(
            'ADMIN ACTIONS',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SpectaTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  label: 'Pending',
                  icon: LucideIcons.clipboardList,
                  color: SpectaTheme.neonCyan,
                  badge: pendingCount > 0 ? pendingCount : null,
                  onTap: _openTransactionManager,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  label: 'Manual',
                  icon: LucideIcons.plusCircle,
                  color: SpectaTheme.neonPurple,
                  onTap: () {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => const ManualInputScreen(),
                      ),
                    ).then((created) {
                      if (created == true) _loadStats();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'RECENT TRANSACTIONS',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SpectaTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          if (recentTx.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No transactions yet',
                  style: TextStyle(color: SpectaTheme.textMuted),
                ),
              ),
            )
          else
            ...recentTx.map<Widget>((tx) {
              final status = tx['status'] ?? 'UNKNOWN';
              final isPending = status == 'PENDING_PROOF';
              return _buildTransactionCard(
                tx['invoice_number'] ?? '-',
                tx['buyer_name'] ?? '-',
                status,
                _statusColor(status),
                tx['time'] ?? '',
                onTap: isPending ? _openTransactionManager : null,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SpectaTheme.neonPurple.withValues(alpha: 0.2),
            SpectaTheme.neonCyan.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SpectaTheme.neonPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            user?['name']?.toString().toUpperCase() ?? 'ADMINISTRATOR',
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _StatDef('Transaksi', _intStat('total_transactions'), LucideIcons.receipt, SpectaTheme.neonPurple),
      _StatDef('Pending', _intStat('pending_transactions'), LucideIcons.clock, Colors.orange),
      _StatDef('Sukses', _intStat('success_transactions'), LucideIcons.checkCircle2, SpectaTheme.neonCyan),
      _StatDef('Tiket Terjual', _intStat('tickets_sold'), LucideIcons.ticket, SpectaTheme.neonCyan),
      _StatDef('QR Generated', _intStat('qr_generated'), LucideIcons.qrCode, Colors.indigoAccent),
      _StatDef('QR Scanned', _intStat('qr_scanned'), LucideIcons.scanLine, Colors.greenAccent),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildStatCard(card.label, '${card.value}', card.icon, card.color);
      },
    );
  }

  Widget _buildRevenueCard() {
    final revenue = _stats?['total_revenue'] ?? _stats?['revenue'] ?? 0;
    final scannedToday = _intStat('scanned_today');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SpectaTheme.neonPurple.withValues(alpha: 0.15),
            SpectaTheme.neonCyan.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SpectaTheme.neonPurple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL PENDAPATAN',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              color: SpectaTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatFullCurrency(revenue),
            style: GoogleFonts.orbitron(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [SpectaTheme.neonPurple, SpectaTheme.neonCyan],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 40)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.scanLine, size: 14, color: Colors.greenAccent.shade400),
              const SizedBox(width: 6),
              Text(
                'Scan hari ini: ',
                style: TextStyle(fontSize: 12, color: SpectaTheme.textMuted),
              ),
              Text(
                '$scannedToday tiket',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaSection(List quotas) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SpectaTheme.slateGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KUOTA TIKET',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              color: SpectaTheme.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          ...quotas.map<Widget>((q) {
            final name = q['name'] ?? 'Ticket';
            final sold = q['sold'] ?? 0;
            final quota = q['quota'] ?? 0;
            final pct = (q['fill_percentage'] ?? 0).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      Text(
                        '$sold/$quota',
                        style: const TextStyle(color: SpectaTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(SpectaTheme.neonPurple, SpectaTheme.neonCyan, pct / 100)!,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SUCCESS':
        return SpectaTheme.neonCyan;
      case 'PENDING_PROOF':
        return Colors.orange;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return SpectaTheme.textMuted;
    }
  }

  Widget _buildActionTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: SpectaTheme.slateGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpectaTheme.slateGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: SpectaTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    String invoice,
    String name,
    String status,
    Color statusColor,
    String time, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SpectaTheme.slateGlass.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap != null
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice,
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 13, color: SpectaTheme.textMuted),
                    ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: SpectaTheme.textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 4),
                    Icon(LucideIcons.chevronRight, size: 14, color: Colors.orange.shade300),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatDef {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatDef(this.label, this.value, this.icon, this.color);
}
