import 'package:flutter/material.dart';

import '../../utils/app_brand.dart';
import '../../utils/sendra_theme.dart';

/// Guide de prise en main.
/// Affiché une seule fois, après la première connexion (puis accessible via
/// le bouton « ? » de la barre du haut). On peut le passer à tout moment.
class GuideView extends StatefulWidget {
  const GuideView({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends State<GuideView> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  bool get _isLast => _index == AppBrand.guide.length - 1;

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _page.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Passer'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: AppBrand.guide.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final step = AppBrand.guide[i];
                  return LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 132,
                                height: 132,
                                decoration: const BoxDecoration(
                                  color: SendraTheme.greenSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(step.icon,
                                    size: 60, color: SendraTheme.green),
                              ),
                              const SizedBox(height: 36),
                              Text(
                                step.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: SendraTheme.ink,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                child: Text(
                                  step.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: SendraTheme.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < AppBrand.guide.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? SendraTheme.green
                                : SendraTheme.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_isLast ? 'Commencer' : 'Suivant'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
