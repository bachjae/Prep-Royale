// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

const String _kViewType = 'prep-royale-desmos-scientific-calculator';
bool _factoryRegistered = false;

// Holds element references keyed by viewId so we can pass them directly to JS.
final Map<int, html.Element> _viewElements = {};

void registerCalculatorViewFactory() {
  if (_factoryRegistered) return;
  _factoryRegistered = true;
  ui_web.platformViewRegistry.registerViewFactory(_kViewType, (int viewId) {
    final el = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%';
    _viewElements[viewId] = el;
    return el;
  });
}

class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key});

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _kViewType,
      onPlatformViewCreated: _onViewCreated,
    );
  }

  void _onViewCreated(int viewId) {
    // Short delay to ensure the element is inserted and sized in the DOM.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final element = _viewElements[viewId];
      if (element == null) return;
      try {
        final desmos = js.context['Desmos'];
        if (desmos != null) {
          desmos.callMethod('ScientificCalculator', [element]);
        } else {
          debugPrint('Desmos: window.Desmos not available');
        }
      } catch (e) {
        debugPrint('Desmos init error: $e');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
