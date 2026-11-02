part of '../../../main.dart';

/// Context for the current assistant, not a second section selector.
class _AiExecutionStatus extends StatelessWidget {
  const _AiExecutionStatus({required this.busy, required this.onSettings});
  final bool busy;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final provider = _normalizeAiProvider(aiProvider);
    final local = provider == 'local';
    final providerName = switch (provider) {
      'gemini' => l.settingsAiProviderGemini,
      'openai' => l.settingsAiProviderOpenAi,
      'mistral' => l.settingsAiProviderMistral,
      _ => l.settingsAiProviderCustom,
    };
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        minTileHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(local ? Icons.memory_rounded : Icons.cloud_outlined),
        title: Text(
          local ? l.ux('aiLocal') : '${l.ux('aiRemote')}: $providerName',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        subtitle: Text(aiModel, style: Theme.of(context).textTheme.bodySmall),
        trailing: IconButton(
          tooltip: l.settingsSectionAI,
          onPressed: busy ? null : onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ),
    );
  }
}
