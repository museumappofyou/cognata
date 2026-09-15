import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../core/models.dart';
import '../theme/app_theme.dart';
import '../widgets/page_body.dart';
import '../widgets/page_header.dart';
import '../widgets/pill_button.dart';

const _leafW = 168.0;
const _leafGap = 12.0;
const _rowH = 96.0;
const _groupGap = 48.0;
const _groupY = 150.0;
const _rootY = 30.0;
const _leavesY = 220.0;

class _Group {
  const _Group(this.name, this.color, this.langs);

  final String name;
  final Color color;
  final List<String> langs;
}

const _groups = [
  _Group('Germanic', Color(0xFF8C2F22),
      ['English', 'German', 'Dutch', 'Swedish']),
  _Group('Italic', Color(0xFF2F5D8C),
      ['Latin', 'Spanish', 'French', 'Italian']),
  _Group('Greek', Color(0xFF6B4B8C), ['Greek']),
  _Group('Indo-Iranian', Color(0xFF8C6B2F), ['Sanskrit']),
  _Group('Slavic', Color(0xFF4A7C59), ['Russian']),
  _Group('Celtic', Color(0xFFB08D3E), ['Irish']),
];

_Group? _groupOf(String lang) {
  for (final g in _groups) {
    if (g.langs.contains(lang)) return g;
  }
  return null;
}

class TreePage extends StatefulWidget {
  const TreePage({super.key});

  @override
  State<TreePage> createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  final TextEditingController _query = TextEditingController();
  String _word = 'heart';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<String> _matches(List<FamilyTree> trees) {
    final needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return trees.map((t) => t.word).toList();
    return trees
        .where((t) =>
            t.word.contains(needle) ||
            t.branches.any((b) =>
                b.form.toLowerCase().contains(needle) ||
                b.lang.toLowerCase().contains(needle)))
        .map((t) => t.word)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final trees = AppScope.of(context).data.trees;
    final matches = _matches(trees);
    final selected = matches.contains(_word)
        ? _word
        : (matches.isNotEmpty ? matches.first : null);
    final tree = selected == null
        ? null
        : trees.firstWhere((t) => t.word == selected);

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'The Kinship Tree',
            subtitle:
                'Pick a word and watch its cousins bloom across the Indo-European family.',
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Try: heart, night, milk, tooth, ghost…',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final w in matches)
                      PillButton(
                        label: w,
                        selected: selected == w,
                        onPressed: () => setState(() => _word = w),
                      ),
                    if (matches.isEmpty)
                      Text(
                        'No tree for that yet — ${trees.length} words are mapped so far.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: CognataColors.faded,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (tree != null) _TreeCanvas(tree: tree),
        ],
      ),
    );
  }
}

class _TreeCanvas extends StatefulWidget {
  const _TreeCanvas({required this.tree});

  final FamilyTree tree;

  @override
  State<_TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<_TreeCanvas> {
  final TransformationController _controller = TransformationController();
  Size? _lastViewport;
  double? _lastTotalW;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fit(Size viewport, double totalW) {
    if (_lastViewport == viewport && _lastTotalW == totalW) return;
    _lastViewport = viewport;
    _lastTotalW = totalW;
    final scale = math.min(1.0, viewport.width / totalW);
    _controller.value = Matrix4.identity()
      ..translateByDouble((viewport.width - totalW * scale) / 2, 0, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    final root = tree.branches
        .where((b) => b.lang == 'Proto-Indo-European')
        .firstOrNull;
    final leaves = tree.branches
        .where((b) =>
            b.lang != 'Proto-Indo-European' && _groupOf(b.lang) != null)
        .toList();
    final used = [
      for (final g in _groups)
        if (leaves.any((l) => g.langs.contains(l.lang))) g,
    ];

    double groupWidth(int n) => n * _leafW + (n - 1) * _leafGap;

    final totalW = used.isEmpty
        ? 400.0
        : used.fold<double>(
                0,
                (sum, g) =>
                    sum +
                    groupWidth(leaves.where((l) => g.langs.contains(l.lang)).length),
              ) +
            _groupGap * (used.length - 1);

    var maxLeaves = 1;
    for (final g in used) {
      final n = leaves.where((l) => g.langs.contains(l.lang)).length;
      if (n > maxLeaves) maxLeaves = n;
    }
    final contentH = _leavesY + maxLeaves * _rowH + 24;
    final rootX = totalW / 2;

    var x = 0.0;
    final layout = <({_Group group, double cx, List<({TreeBranch item, double x, double y})> items})>[];
    for (final g in used) {
      final items = leaves.where((l) => g.langs.contains(l.lang)).toList();
      final gx = x;
      final cx = gx + groupWidth(items.length) / 2;
      layout.add((
        group: g,
        cx: cx,
        items: [
          for (var i = 0; i < items.length; i++)
            (
              item: items[i],
              x: gx + i * (_leafW + _leafGap),
              y: _leavesY + i * _rowH,
            ),
        ],
      ));
      x += groupWidth(items.length) + _groupGap;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final fitScale = math.min(1.0, viewportW / totalW);
        final viewportH = math.min(contentH * fitScale + 12, 680.0);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fit(Size(viewportW, viewportH), totalW);
        });

        return Column(
          children: [
            SizedBox(
              height: viewportH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  transformationController: _controller,
                  constrained: false,
                  minScale: 0.2,
                  maxScale: 3,
                  child: SizedBox(
                    width: totalW,
                    height: contentH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: Size(totalW, contentH),
                          painter: _TreePainter(layout: layout, rootX: rootX),
                        ),
                        Positioned(
                          left: rootX - 130,
                          top: _rootY,
                          width: 260,
                          height: 58,
                          child: Container(
                            decoration: BoxDecoration(
                              color: CognataColors.ink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  root?.form ?? 'Proto-Indo-European',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: CognataFonts.display,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: CognataColors.cream,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${tree.word} · ${tree.gloss}',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: CognataFonts.body,
                                    fontSize: 10.5,
                                    fontStyle: FontStyle.italic,
                                    color: CognataColors.leafBorder,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (final g in layout) ...[
                          Positioned(
                            left: g.cx - 62,
                            top: _groupY,
                            width: 124,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: CognataColors.paper,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(color: g.group.color, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                g.group.name,
                                style: TextStyle(
                                  fontFamily: CognataFonts.body,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: g.group.color,
                                ),
                              ),
                            ),
                          ),
                          for (final leaf in g.items)
                            Positioned(
                              left: leaf.x,
                              top: leaf.y,
                              width: _leafW,
                              height: _rowH - 12,
                              child: _LeafCard(
                                branch: leaf.item,
                                color: g.group.color,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Drag to pan · pinch or scroll to zoom',
              style: TextStyle(fontSize: 11.5, color: CognataColors.faded),
            ),
          ],
        );
      },
    );
  }
}

class _LeafCard extends StatelessWidget {
  const _LeafCard({required this.branch, required this.color});

  final TreeBranch branch;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CognataColors.card,
        border: Border.all(color: CognataColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branch.lang.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.6,
              color: CognataColors.faded,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            branch.form,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: CognataFonts.display,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            branch.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.3,
              color: CognataColors.faded,
            ),
          ),
        ],
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter({
    required this.layout,
    required this.rootX,
  });

  final List<
      ({
        _Group group,
        double cx,
        List<({TreeBranch item, double x, double y})> items
      })> layout;
  final double rootX;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CognataColors.leafBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final g in layout) {
      final rootPath = Path()
        ..moveTo(rootX, _rootY + 58)
        ..cubicTo(
          rootX,
          _groupY - 30,
          g.cx,
          _groupY - 60,
          g.cx,
          _groupY,
        );
      canvas.drawPath(rootPath, paint);

      for (final leaf in g.items) {
        final leafPath = Path()
          ..moveTo(g.cx, _groupY + 34)
          ..cubicTo(
            g.cx,
            leaf.y - 40,
            leaf.x + _leafW / 2,
            leaf.y - 60,
            leaf.x + _leafW / 2,
            leaf.y,
          );
        canvas.drawPath(leafPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.rootX != rootX;
}
