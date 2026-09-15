import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/cognata_card.dart';
import '../widgets/page_body.dart';
import '../widgets/page_header.dart';

const _heroPath = 'assets/forge3d/origins-hero.webp';
const _flyoverPath = 'assets/forge3d/origins-flyover.webp';
const _turnCount = 24;

String _framePath(int i) =>
    'assets/forge3d/turntable_${i.toString().padLeft(2, '0')}.webp';

class OriginsPage extends StatefulWidget {
  const OriginsPage({super.key});

  @override
  State<OriginsPage> createState() => _OriginsPageState();
}

class _OriginsPageState extends State<OriginsPage> {
  int _frame = 0;
  double _dragStartX = 0;
  int _dragStartFrame = 0;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheFrames());
  }

  Future<void> _precacheFrames() async {
    for (var i = 0; i < _turnCount; i++) {
      final path = _framePath(i);
      try {
        await rootBundle.load(path);
        if (!mounted) return;
        await precacheImage(AssetImage(path), context);
      } catch (_) {
        return;
      }
    }
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartFrame = _frame;
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (width <= 0) return;
    final delta = (details.globalPosition.dx - _dragStartX) / width * _turnCount;
    final next = ((_dragStartFrame + delta.round()) % _turnCount + _turnCount) %
        _turnCount;
    if (next != _frame) setState(() => _frame = next);
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'The Homeland',
            tagline: 'Five thousand years ago, this was one language\'s horizon.',
            subtitle:
                'The Kurgan hypothesis puts the Proto-Indo-European homeland on '
                'the Pontic–Caspian steppe, north of the Black Sea. These renders '
                'are path-traced from real elevation data with forge3d.',
          ),
          const SizedBox(height: 32),
          _HeroImage(),
          const SizedBox(height: 40),
          const _SectionTitle(
            'Orbit the steppe',
            'A full turntable, precomputed frame by frame. Drag the image or '
            'use the slider.',
          ),
          const SizedBox(height: 16),
          _Turntable(
            frame: _frame,
            onDragStart: _onDragStart,
            onDragUpdate: (d, width) => _onDragUpdate(d, width),
            onScrub: (v) => setState(() => _frame = v.round()),
          ),
          const SizedBox(height: 40),
          const _SectionTitle(
            'Flyover',
            'One camera, one loop — the same scene graph that makes the stills.',
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                _flyoverPath,
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => const _RenderPending(
                  label: 'Animated flyover',
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const _SectionTitle(
            'Sound laws meet soil',
            'Words travel the same routes as the people who carried them. Trace '
            'a word back through the tree, then look at where it started.',
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final w in const ['mother', 'fire', 'star', 'water', 'night'])
                FilledButton(
                  onPressed: () {
                    AppScope.of(context).go(AppTab.tree);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: CognataColors.paper,
                    foregroundColor: CognataColors.ink,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: CognataFonts.body,
                    ),
                  ),
                  child: Text(w),
                ),
            ],
          ),
          const SizedBox(height: 40),
          CognataCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How these renders were made',
                  style: TextStyle(
                    fontFamily: CognataFonts.display,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CognataColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Elevation comes from the Copernicus DEM GLO-30 '
                            '(ESA, free and open). The scene is built offline '
                            'in Python with ',
                      ),
                      TextSpan(
                        text: 'forge3d',
                        style: const TextStyle(
                          color: CognataColors.accent,
                          decoration: TextDecoration.underline,
                          decorationColor: CognataColors.accent,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                                Uri.parse(
                                    'https://github.com/milos-agathon/forge3d'),
                              ),
                      ),
                      const TextSpan(
                        text:
                            ' — a Rust/WebGPU path tracer — then baked into the '
                            'image assets this app ships with. No GPU is needed '
                            'on your device: the renders are precomputed once, '
                            'in the repo\'s scripts/render_assets.sh.',
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: CognataColors.faded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          _heroPath,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) =>
              const _RenderPending(label: 'Steppe homeland hero render'),
        ),
      ),
    );
  }
}

class _Turntable extends StatelessWidget {
  const _Turntable({
    required this.frame,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onScrub,
  });

  final int frame;
  final void Function(DragStartDetails) onDragStart;
  final void Function(DragUpdateDetails, double width) onDragUpdate;
  final ValueChanged<double> onScrub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              onHorizontalDragStart: onDragStart,
              onHorizontalDragUpdate: (d) => onDragUpdate(d, width),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    _framePath(frame),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, _, _) =>
                        const _RenderPending(label: 'Turntable frames'),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: CognataColors.accent,
                  inactiveTrackColor: CognataColors.paper,
                  thumbColor: CognataColors.accent,
                  overlayColor: CognataColors.accent.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: frame.toDouble(),
                  max: (_turnCount - 1).toDouble(),
                  divisions: _turnCount - 1,
                  onChanged: onScrub,
                ),
              ),
            ),
            Text(
              '${frame.toString().padLeft(2, '0')}/'
              '${(_turnCount - 1).toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 12,
                color: CognataColors.faded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.caption);

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: CognataFonts.display,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CognataColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.65,
              color: CognataColors.faded,
            ),
          ),
        ),
      ],
    );
  }
}

class _RenderPending extends StatelessWidget {
  const _RenderPending({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CognataColors.paper,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.terrain_outlined,
              size: 40, color: CognataColors.faded),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: CognataFonts.display,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CognataColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Render pending — run scripts/render_assets.sh to generate it.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: CognataColors.faded),
          ),
        ],
      ),
    );
  }
}
