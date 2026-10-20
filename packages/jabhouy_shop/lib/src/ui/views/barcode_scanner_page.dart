import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/src/models/item.dart';
import 'package:jabhouy_shop/src/ui/widgets/scan_result_sheet.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Opens the scanner and returns the first code read; null when closed.
Future<String?> scanBarcode(BuildContext context) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScannerPage(),
      ),
    );

/// Home's scan: each code's result shows over the camera. Returns the
/// [Item] to open, a code to add a new Item with, or null when closed.
Future<Object?> findByBarcode(
  BuildContext context,
  Future<List<Item>> Function(String code) lookup,
) => Navigator.of(context).push<Object>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => BarcodeScannerPage(
      onCode: (pageContext, code) async {
        final items = await lookup(code);
        if (!pageContext.mounted) return null;
        return showScanResult(pageContext, code: code, items: items);
      },
    ),
  ),
);

/// Full-screen scanner (canvas ១ឃ). Without [onCode] it closes with the
/// first code. With it, the camera stops while [onCode] handles a code: a
/// non-null answer closes the scanner with it, null scans again.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({this.onCode, super.key});

  final Future<Object?> Function(BuildContext context, String code)? onCode;

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final _controller = MobileScannerController();

  /// Set while a code is handled, so the camera's next frames are ignored.
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .firstWhere((c) => c != null && c.isNotEmpty, orElse: () => null);
    if (_busy || code == null) return;
    _busy = true;
    final onCode = widget.onCode;
    if (onCode == null) {
      Navigator.pop(context, code);
      return;
    }
    await _controller.stop();
    if (!mounted) return;
    final result = await onCode(context, code);
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, result);
      return;
    }
    _busy = false;
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Dark in both themes, as on the canvas: it frames a camera picture.
    const fg = Colors.white;
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Text(
                  l10n.scanCameraError,
                  textAlign: TextAlign.center,
                  style: AppTextTheme.body.copyWith(color: fg),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonLabel,
                        icon: const Icon(Icons.close_rounded, color: fg),
                      ),
                      Expanded(
                        child: Text(
                          l10n.scanTitle,
                          textAlign: TextAlign.center,
                          style: AppTextTheme.body.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Upper part of the screen, so a result sheet leaves the
                // frame in view.
                const SizedBox(height: 300, child: Center(child: _Frame())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White corners around the scan area, with a green line across it.
class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(250, 140), painter: _FramePainter());
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  static const _arm = 30.0;
  static const _radius = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final corners = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    // The top-left corner, mirrored into the other three.
    final corner = Path()
      ..moveTo(0, _arm)
      ..lineTo(0, _radius)
      ..arcToPoint(
        const Offset(_radius, 0),
        radius: const Radius.circular(_radius),
      )
      ..lineTo(_arm, 0);
    for (final (dx, dy) in [
      (1.0, 1.0),
      (-1.0, 1.0),
      (1.0, -1.0),
      (-1.0, -1.0),
    ]) {
      canvas
        ..save()
        ..translate(dx > 0 ? 2 : size.width - 2, dy > 0 ? 2 : size.height - 2)
        ..scale(dx, dy)
        ..drawPath(corner, corners)
        ..restore();
    }
    canvas.drawLine(
      Offset(12, size.height / 2),
      Offset(size.width - 12, size.height / 2),
      Paint()
        ..color = const Color(0xFF6FD08C)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}
