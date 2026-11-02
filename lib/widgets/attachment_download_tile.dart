import 'package:flutter/material.dart';
import 'app_experience_scope.dart';

/// Per-attachment state survives parent rebuilds and is scoped by the caller's
/// message/attachment key. No file data or credentials are stored in this widget.
class AttachmentDownloadTile extends StatefulWidget {
  const AttachmentDownloadTile({
    super.key,
    required this.name,
    required this.icon,
    required this.loadingLabel,
    required this.errorLabel,
    required this.retryLabel,
    required this.onDownload,
    this.radius = 24,
  });

  final String name;
  final IconData icon;
  final String loadingLabel;
  final String errorLabel;
  final String retryLabel;
  final Future<void> Function() onDownload;
  final double radius;

  @override
  State<AttachmentDownloadTile> createState() => _AttachmentDownloadTileState();
}

class _AttachmentDownloadTileState extends State<AttachmentDownloadTile> {
  bool _loading = false;
  bool _failed = false;

  Future<void> _download() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await widget.onDownload();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final experience = AppExperienceScope.maybeOf(context);
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        (experience?.interactions ?? true) &&
        (experience?.active ?? true) &&
        TickerMode.valuesOf(context).enabled;
    return Material(
      color: _failed ? cs.errorContainer : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(widget.radius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            minTileHeight: 64,
            leading: Icon(widget.icon),
            title: Text(widget.name),
            textColor: _failed ? cs.onErrorContainer : cs.onSurface,
            iconColor: _failed ? cs.onErrorContainer : cs.onSurface,
            subtitle: _loading || _failed
                ? Semantics(
                    liveRegion: true,
                    child: Text(
                      _loading ? widget.loadingLabel : widget.errorLabel,
                    ),
                  )
                : null,
            trailing: _loading
                ? ExcludeSemantics(
                    child: !animate
                        ? const Icon(Icons.hourglass_top_rounded)
                        : const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                  )
                : const Icon(Icons.download_rounded),
            onTap: _loading ? null : _download,
          ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onErrorContainer,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: _download,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(widget.retryLabel),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
