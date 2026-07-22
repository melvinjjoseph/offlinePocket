import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  String _version = '';

  static const _slideCount = 6;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  bool get _isLast => _page == _slideCount - 1;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    await prefs.setString('onboarding_last_version', packageInfo.version);
    if (mounted) {
      ref.read(onboardingSeenProvider.notifier).state = true;
    }
  }

  void _next() {
    if (!_isLast) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;

    return Scaffold(
      body: CustomPaint(
        painter: _DotGridPainter(neon.panelBorder.withValues(alpha: 0.35)),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _PrivateVaultSlide(version: _version),
                    const _ScanningSlide(),
                    const _PrivacySlide(),
                    const _ActivityLogSlide(),
                    const _BackupsSlide(),
                    const _GetStartedSlide(),
                  ],
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final neon = context.neon;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Image.asset('assets/icon/logo.png',
                width: 32,
                height: 32,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.shield_outlined, color: neon.accent, size: 26)),
            const SizedBox(width: 10),
            Text('OfflinePocket',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: neon.accent,
                      fontWeight: FontWeight.w700,
                    )),
            const Spacer(),
            AnimatedOpacity(
              opacity: _isLast ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _isLast ? null : _finish,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: Text('SKIP',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          Row(
            children: List.generate(_slideCount, (i) {
              final active = _page == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? neon.accentBright : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: active ? neon.glowShadow(strength: 0.5) : null,
                ),
              );
            }),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: neon.glowShadow(strength: 0.8),
            ),
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: neon.accentBright,
                foregroundColor: AppColors.onAccentContainer,
                padding: EdgeInsets.symmetric(
                    horizontal: _isLast ? 28 : 24, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isLast ? 'Get Started' : 'Next',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.onAccentContainer,
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared slide chrome
// ---------------------------------------------------------------------------

/// Common vertical rhythm for every slide: visual, optional mono badge,
/// title, body, optional feature chips — all centered and scrollable so the
/// longer copy still fits on short devices.
class _SlideScaffold extends StatelessWidget {
  const _SlideScaffold({
    required this.visual,
    required this.title,
    required this.body,
    this.badge,
    this.chips = const [],
    this.accentTitle = false,
  });

  final Widget visual;
  final String title;
  final String body;
  final String? badge;
  final List<Widget> chips;
  final bool accentTitle;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              visual,
              const SizedBox(height: 28),
              if (badge != null) ...[
                _MonoBadge(badge!),
                const SizedBox(height: 18),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: tt.headlineLarge?.copyWith(
                  color: accentTitle ? neon.accent : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                body,
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 26),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: chips,
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined monospace pill — the design's "system readout" motif.
class _MonoBadge extends StatelessWidget {
  const _MonoBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: neon.accent.withValues(alpha: 0.06),
        border: Border.all(color: neon.accent.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: neon.accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Feature chip. [highlight] gives it the accent border used on the mockup's
/// "Biometric Seal" chip.
class _FeatureChip extends StatelessWidget {
  const _FeatureChip(this.icon, this.label, {this.highlight = false});

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border.all(
          color: highlight ? neon.accent.withValues(alpha: 0.6) : neon.panelBorder,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: neon.accent),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurface)),
        ],
      ),
    );
  }
}

/// Rounded panel that hosts each slide's hero visual.
class _VisualPanel extends StatelessWidget {
  const _VisualPanel({
    required this.child,
    this.size = 240,
    this.dashed = false,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double size;
  final bool dashed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;

    final content = Container(
      width: size,
      height: size,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHigh.withValues(alpha: 0.7),
            scheme.surfaceContainerLow.withValues(alpha: 0.7),
          ],
        ),
        border: dashed ? null : Border.all(color: neon.panelBorder),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: neon.glow.withValues(alpha: 0.10),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );

    if (!dashed) return content;
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        color: neon.accent.withValues(alpha: 0.45),
        radius: 18,
        inset: 12,
      ),
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 1 — Your Private Vault
// ---------------------------------------------------------------------------

class _PrivateVaultSlide extends StatelessWidget {
  const _PrivateVaultSlide({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;

    return _SlideScaffold(
      visual: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric "containment rings" from the mockup.
          Container(
            width: 268,
            height: 268,
            decoration: BoxDecoration(
              border: Border.all(color: neon.panelBorder.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          _VisualPanel(
            size: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    size: 116,
                    color: neon.accentBright,
                    shadows: neon.glowShadow(strength: 1.4)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Icon(Icons.favorite,
                      size: 40, color: neon.accentBright),
                ),
              ],
            ),
          ),
        ],
      ),
      badge: version.isEmpty ? 'SECURE NODE' : 'V$version SECURE NODE',
      title: 'Your Private Vault',
      body:
          'Zero-knowledge, hardware-backed encryption that never leaves your '
          'device. Securely manage your digital identity.',
      chips: const [
        _FeatureChip(Icons.lock_outline, 'AES-256'),
        _FeatureChip(Icons.key_outlined, 'Biometric Seal', highlight: true),
        _FeatureChip(Icons.bolt_outlined, 'Local Only'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 2 — Intelligent Scanning
// ---------------------------------------------------------------------------

class _ScanningSlide extends StatefulWidget {
  const _ScanningSlide();

  @override
  State<_ScanningSlide> createState() => _ScanningSlideState();
}

class _ScanningSlideState extends State<_ScanningSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;

    return _SlideScaffold(
      visual: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: neon.accent),
          borderRadius: BorderRadius.circular(14),
          boxShadow: neon.glowShadow(strength: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Stack(
              children: [
                // Card body
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: neon.cardGradient,
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 46,
                            height: 34,
                            decoration: BoxDecoration(
                              color: neon.accent.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Icon(Icons.contactless_outlined,
                              size: 26, color: neon.accent),
                        ],
                      ),
                      const Spacer(),
                      _skeletonBar(scheme, width: 190, height: 14),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _skeletonBar(scheme, width: 74, height: 12),
                          const SizedBox(width: 12),
                          _skeletonBar(scheme, width: 44, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sweeping scan line
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scan,
                    builder: (context, child) {
                      final t = _scan.value;
                      return Align(
                        // -1 = top edge, 1 = bottom edge.
                        alignment: Alignment(0, t * 2 - 1),
                        child: Opacity(
                          // Fade in/out at the travel extremes.
                          opacity: math.sin(t * math.pi).clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          neon.accentBright.withValues(alpha: 0),
                          neon.accentBright,
                          neon.accentBright.withValues(alpha: 0),
                        ]),
                        boxShadow: neon.glowShadow(strength: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      title: 'Intelligent Scanning',
      body:
          'Instantly parse payment cards and IDs with secure, on-device AI. '
          'No data is ever sent to the cloud.',
    );
  }

  Widget _skeletonBar(ColorScheme scheme,
          {required double width, required double height}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
}

// ---------------------------------------------------------------------------
// Slide 3 — True Privacy
// ---------------------------------------------------------------------------

class _PrivacySlide extends StatelessWidget {
  const _PrivacySlide();

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;

    return _SlideScaffold(
      visual: SizedBox(
        height: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Tilted dashed frame behind the panel.
            Transform.rotate(
              angle: 0.22,
              child: CustomPaint(
                painter: _DashedRRectPainter(
                  color: neon.accent.withValues(alpha: 0.35),
                  radius: 12,
                  inset: 0,
                ),
                size: const Size(220, 220),
              ),
            ),
            _VisualPanel(
              size: 220,
              child: Icon(Icons.cloud_off,
                  size: 104,
                  color: neon.accentBright,
                  shadows: neon.glowShadow(strength: 1.2)),
            ),
            // Detached "severed connection" tiles.
            Positioned(
              top: 42,
              right: 24,
              child: Transform.rotate(
                angle: 0.18,
                child: _tile(scheme, Icons.link_off),
              ),
            ),
            Positioned(
              bottom: 52,
              left: 26,
              child: Transform.rotate(
                angle: -0.14,
                child: _tile(scheme, Icons.signal_cellular_off),
              ),
            ),
          ],
        ),
      ),
      badge: 'NETWORK_STATUS: OFFLINE',
      title: 'True Privacy',
      body:
          'No accounts. No trackers. Zero network calls. Your data is your '
          'own, completely sandboxed.',
      chips: const [
        _FeatureChip(Icons.lock_outline, 'VAULT STORAGE'),
        _FeatureChip(Icons.circle, 'ZERO TELEMETRY'),
      ],
    );
  }

  Widget _tile(ColorScheme scheme, IconData icon) => Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: scheme.onSurfaceVariant),
      );
}

// ---------------------------------------------------------------------------
// Slide 4 — Local Activity Log
// ---------------------------------------------------------------------------

class _ActivityLogSlide extends StatelessWidget {
  const _ActivityLogSlide();

  /// Sample rows from the mockup. These are illustrative only — the real log
  /// is rendered by the Activity tab from events recorded on this device.
  static const _entries = <_LogEntry>[
    _LogEntry(
      time: '12:44:02.112',
      meta: 'STATUS: OK',
      icon: Icons.check_circle_outline,
      label: 'Encrypted Export Successful',
      detail: 'SHA-256: e3b0c442...',
    ),
    _LogEntry(
      time: '12:45:15.884',
      meta: 'AUTH: BIOMETRIC',
      icon: Icons.fingerprint,
      label: 'Biometric Unlock',
    ),
    _LogEntry(
      time: '12:46:10.001',
      meta: 'PRIVACY: SYSTEM',
      icon: Icons.content_paste_off_outlined,
      label: 'Clipboard Cleared',
    ),
    _LogEntry(
      time: '12:48:33.450',
      meta: 'SYNC: LOCAL_ONLY',
      icon: Icons.sync_alt,
      label: 'Local Backup Initialized...',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _SlideScaffold(
      visual: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHigh.withValues(alpha: 0.7),
              scheme.surfaceContainerLow.withValues(alpha: 0.7),
            ],
          ),
          border: Border.all(color: neon.panelBorder),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: neon.glow.withValues(alpha: 0.10),
              blurRadius: 34,
              spreadRadius: 2,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Terminal chrome
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: neon.panelBorder.withValues(alpha: 0.6))),
              ),
              child: Row(
                children: [
                  _dot(scheme.error.withValues(alpha: 0.55)),
                  _dot(neon.accent.withValues(alpha: 0.45)),
                  _dot(neon.accentBright.withValues(alpha: 0.8)),
                  const Spacer(),
                  Text('LOC_AUDIT_V1.0',
                      style: tt.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Stack(
              children: [
                // Watermark glyph, bottom-right of the log body.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 8),
                      child: Icon(Icons.terminal,
                          size: 60,
                          color: scheme.onSurface.withValues(alpha: 0.07)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 42),
                  child: Column(
                    children: [
                      for (final e in _entries) _LogRow(entry: e),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      title: 'Local Activity Log',
      body:
          'Keep track of every movement. A local, zero-leak audit trail of '
          'shares, backups, and access attempts. We record references only — '
          'never your sensitive values.',
    );
  }

  Widget _dot(Color color) => Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(right: 7),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _LogEntry {
  const _LogEntry({
    required this.time,
    required this.meta,
    required this.icon,
    required this.label,
    this.detail,
  });

  final String time;
  final String meta;
  final IconData icon;
  final String label;
  final String? detail;
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final _LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // The meta line is deliberately a size below the body so the longest
    // variant ("SYNC: LOCAL_ONLY") still fits beside the timestamp.
    final metaStyle = tt.labelSmall
        ?.copyWith(fontSize: 10, color: scheme.onSurfaceVariant);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: neon.accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text('TIMESTAMP: ${entry.time}',
                    overflow: TextOverflow.ellipsis, style: metaStyle),
              ),
              const SizedBox(width: 8),
              Text(entry.meta, style: metaStyle),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(entry.icon, size: 15, color: neon.accentBright),
              const SizedBox(width: 7),
              Flexible(
                child: Text(entry.label,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelMedium?.copyWith(color: neon.accentBright)),
              ),
            ],
          ),
          if (entry.detail != null) ...[
            const SizedBox(height: 4),
            // No italic here: only the 400/500 uprights of JetBrains Mono are
            // bundled, so an italic request would just render upright anyway.
            Text(entry.detail!,
                style: tt.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                )),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 5 — Encrypted Backups
// ---------------------------------------------------------------------------

class _BackupsSlide extends StatelessWidget {
  const _BackupsSlide();

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _SlideScaffold(
      visual: _VisualPanel(
        size: 260,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: neon.accent.withValues(alpha: 0.12),
                border: Border.all(color: neon.accent.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.enhanced_encryption_outlined,
                  size: 42,
                  color: neon.accentBright,
                  shadows: neon.glowShadow(strength: 0.9)),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: 0.72,
                        minHeight: 4,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation(neon.accentBright),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('AES-256',
                      style: tt.labelSmall?.copyWith(color: neon.accent)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('PORTABLE_VAULT.OPBACKUP',
                      overflow: TextOverflow.ellipsis,
                      style: tt.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ],
        ),
      ),
      title: 'Encrypted Backups',
      accentTitle: true,
      body:
          'Export a secure .opbackup file protected by AES-256-GCM. Share it '
          'anywhere or save it to your preferred cloud storage — your data '
          'stays encrypted with your master password.',
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 6 — Secure Your Pocket
// ---------------------------------------------------------------------------

class _GetStartedSlide extends StatelessWidget {
  const _GetStartedSlide();

  @override
  Widget build(BuildContext context) {
    final neon = context.neon;

    return _SlideScaffold(
      visual: _VisualPanel(
        size: 230,
        dashed: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined,
                size: 84,
                color: neon.accentBright,
                shadows: neon.glowShadow(strength: 1.2)),
            const SizedBox(height: 18),
            const _MonoBadge('ENCRYPTED'),
          ],
        ),
      ),
      title: 'Secure Your Pocket',
      accentTitle: true,
      body:
          'Ready to digitize your sensitive documents with military-grade '
          'protection. Your data never leaves this device.',
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Faint dotted grid that sits behind every slide — the mockup's background.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter(this.color);

  final Color color;

  static const _spacing = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

/// Dashed rounded-rectangle outline, inset from the paint bounds.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.inset,
  });

  final Color color;
  final double radius;
  final double inset;

  static const _dash = 7.0;
  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2,
        size.height - inset * 2);
    if (rect.isEmpty) return;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + _dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius || old.inset != inset;
}
