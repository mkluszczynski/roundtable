import 'package:flutter/material.dart';

/// A sideways-scrolling row whose edges fade out where there's more to
/// scroll to — the hint that a strip of tabs or pills goes on past the
/// screen's edge.
class HorizontalScroller extends StatefulWidget {
  const HorizontalScroller({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  State<HorizontalScroller> createState() => _HorizontalScrollerState();
}

class _HorizontalScrollerState extends State<HorizontalScroller> {
  final _controller = ScrollController();
  var _fadeStart = false;
  var _fadeEnd = false;

  static const _fadeWidth = 24.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateFades() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final start = position.pixels > 0;
    final end = position.pixels < position.maxScrollExtent;
    if (start != _fadeStart || end != _fadeEnd) {
      setState(() {
        _fadeStart = start;
        _fadeEnd = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      // The content can change width (a new tab) without scrolling.
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
        return false;
      },
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          final stop = bounds.width == 0 ? 0.0 : _fadeWidth / bounds.width;
          return LinearGradient(
            colors: [
              _fadeStart ? Colors.transparent : Colors.black,
              Colors.black,
              Colors.black,
              _fadeEnd ? Colors.transparent : Colors.black,
            ],
            stops: [0, stop, 1 - stop, 1],
          ).createShader(bounds);
        },
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}
