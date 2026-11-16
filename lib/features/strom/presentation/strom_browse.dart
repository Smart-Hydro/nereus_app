import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';

class OpsBrowse<T> extends StatelessWidget {
  const OpsBrowse({
    super.key,
    required this.title,
    required this.value,
    required this.itemBuilder,
    required this.onRetry,
    this.subtitle = 'Strøm — Operaciones',
    this.action,
    this.header,
    this.emptyMessage = 'No hay registros en esta sucursal.',
    this.bare = false,
  });

  final String title;
  final String subtitle;
  final AsyncValue<List<T>> value;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onRetry;
  final Widget? action;
  final Widget? header;
  final String emptyMessage;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 8),
        ],
        Expanded(
          child: value.when(
                loading: () => const ShimmerList(),
                error: (error, _) => AsyncBody(
                  isLoading: false,
                  hasError: true,
                  isEmpty: true,
                  onRetry: onRetry,
                  errorMessage: userFacingErrorMessage(error),
                  isNetworkError: isNetworkFailure(error),
                  child: const SizedBox.shrink(),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return AsyncBody(
                      isLoading: false,
                      hasError: false,
                      isEmpty: true,
                      onRetry: onRetry,
                      emptyMessage: emptyMessage,
                      child: const SizedBox.shrink(),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => itemBuilder(context, items[index]),
                  );
                },
              ),
            ),
      ],
    );
    if (bare) return body;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StromChrome(
        title: title,
        subtitle: subtitle,
        action: action,
        child: body,
      ),
    );
  }
}

class OpsTile extends StatelessWidget {
  const OpsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
    this.tone = NereusTokens.hydroOlive,
  });

  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      semanticLabel: title,
      padding: EdgeInsets.zero,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: StatusChip(label: status, tone: tone),
      ),
    );
  }
}

class OpsDetail extends StatelessWidget {
  const OpsDetail({
    super.key,
    required this.title,
    required this.children,
    this.subtitle = 'Strøm — Operaciones',
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StromChrome(
        title: title,
        subtitle: subtitle,
        action: action,
        child: ListView(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class OpsAsync extends StatelessWidget {
  const OpsAsync({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.child,
  });

  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ShimmerList();
    if (error != null) {
      return AsyncBody(
        isLoading: false,
        hasError: true,
        isEmpty: true,
        onRetry: onRetry,
        errorMessage: userFacingErrorMessage(error!),
        isNetworkError: isNetworkFailure(error!),
        child: const SizedBox.shrink(),
      );
    }
    return child;
  }
}

class OpsNote extends StatelessWidget {
  const OpsNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class OpsButton extends StatelessWidget {
  const OpsButton(this.label, this.onPressed, {super.key, this.destructive = false});

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: destructive
          ? FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            )
          : null,
      child: Text(label),
    );
  }
}
