import 'package:flutter/material.dart';

class LearningStepControls extends StatelessWidget {
  final bool canGoBack;
  final bool canGoForward;
  final bool canSkip;
  final bool isLastStep;
  final bool canGoToLast;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onRestart;
  final VoidCallback? onHint;
  final VoidCallback? onGoToLast;

  const LearningStepControls({
    Key? key,
    this.canGoBack = false,
    this.canGoForward = false,
    this.canSkip = false,
    this.isLastStep = false,
    this.canGoToLast = false,
    this.onPrevious,
    this.onNext,
    this.onSkip,
    this.onRestart,
    this.onHint,
    this.onGoToLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isNarrow = screenWidth < 600;
        final isVeryNarrow = screenWidth < 400;

        return Container(
          padding: EdgeInsets.all(isNarrow ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _buildResponsiveLayout(context, isNarrow, isVeryNarrow),
        );
      },
    );
  }

  Widget _buildResponsiveLayout(
      BuildContext context, bool isNarrow, bool isVeryNarrow) {
    if (isVeryNarrow) {
      return _buildCompactLayout(context);
    } else if (isNarrow) {
      return _buildNarrowLayout(context);
    } else {
      return _buildWideLayout(context);
    }
  }

  Widget _buildCompactLayout(BuildContext context) {
    // Very narrow screens: Stack buttons vertically with minimal text
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary buttons row
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: canGoBack ? onPrevious : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 44),
                ),
                child: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canGoForward ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 44),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isLastStep ? Icons.check : Icons.arrow_forward),
                    const SizedBox(width: 4),
                    Text(isLastStep ? '完成' : '下一步'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Secondary buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRestart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
                child: const Icon(Icons.refresh, size: 18),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                onPressed: onHint,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
                child: const Icon(Icons.lightbulb_outline, size: 18),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                onPressed: canSkip ? onSkip : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: canSkip ? Colors.purple : Colors.grey,
                  side:
                      BorderSide(color: canSkip ? Colors.purple : Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
                child: const Icon(Icons.skip_next, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    // Narrow screens: Standard mobile layout with text labels
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary buttons row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoBack ? onPrevious : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('上一步'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 44),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canGoForward ? onNext : null,
                icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
                label: Text(isLastStep ? '完成' : '下一步'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 44),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Secondary buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh),
                label: const Text('重新开始'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onHint,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('提示'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canSkip ? onSkip : null,
                icon: const Icon(Icons.skip_next),
                label: const Text('跳过'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: canSkip ? Colors.purple : Colors.grey,
                  side:
                      BorderSide(color: canSkip ? Colors.purple : Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 40),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    // Wide screens: Single row layout with more spacing
    return Row(
      children: [
        // Previous button
        Expanded(
          flex: 1,
          child: ElevatedButton.icon(
            onPressed: canGoBack ? onPrevious : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('上一步'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Secondary buttons
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.refresh),
            label: const Text('重新开始'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: onHint,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('提示'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: canSkip ? onSkip : null,
            icon: const Icon(Icons.skip_next),
            label: const Text('跳过'),
            style: OutlinedButton.styleFrom(
              foregroundColor: canSkip ? Colors.purple : Colors.grey,
              side: BorderSide(color: canSkip ? Colors.purple : Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Go to last step button
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: canGoToLast ? onGoToLast : null,
            icon: const Icon(Icons.last_page),
            label: const Text('最后一步'),
            style: OutlinedButton.styleFrom(
              foregroundColor: canGoToLast ? Colors.indigo : Colors.grey,
              side:
                  BorderSide(color: canGoToLast ? Colors.indigo : Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Next/Complete button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: canGoForward ? onNext : null,
            icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
            label: Text(isLastStep ? '完成课程' : '下一步'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    );
  }
}
