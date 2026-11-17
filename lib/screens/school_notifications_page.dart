part of '../main.dart';

class _MessageAttachment {
  final String id;
  final String name;
  final bool isDemo;
  final String? messageId;
  final String? url;

  const _MessageAttachment({
    required this.id,
    required this.name,
    this.isDemo = false,
    this.messageId,
    this.url,
  });

  String get fileExtension {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toUpperCase();
  }
}

class _SchoolNotificationItem {
  final String id;
  final String title;
  final String body;
  final String fullBody;
  final DateTime? date;
  final String? author;
  final String? url;
  final List<_MessageAttachment> attachments;

  _SchoolNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.fullBody = '',
    this.author,
    this.url,
    this.attachments = const [],
  });

  int get sortValue => date?.millisecondsSinceEpoch ?? 0;

  String get displayBody => fullBody.isEmpty ? body : fullBody;
  late final String previewBody = schoolHtmlToPlainText(
    sanitizeSchoolHtml(body),
  );

  String? get uniformAttachmentExtension {
    if (attachments.isEmpty) return null;
    final first = attachments.first.fileExtension;
    if (first.isEmpty) return null;
    for (final attachment in attachments) {
      if (attachment.fileExtension != first) return null;
    }
    return first;
  }
}

// --- INFO / SCHUL-BENACHRICHTIGUNGEN ---
class SchoolNotificationsPage extends StatefulWidget {
  const SchoolNotificationsPage({super.key, this.isActive = true});

  /// The main navigation keeps its pages alive. Delay the first network load
  /// until this tab is actually shown, then refresh when it is revisited.
  final bool isActive;

  @override
  State<SchoolNotificationsPage> createState() =>
      _SchoolNotificationsPageState();
}

class _SchoolNotificationsPageState extends State<SchoolNotificationsPage> {
  List<_SchoolNotificationItem> _newsItems = const [];
  List<_SchoolNotificationItem> _inboxItems = const [];
  bool _showInbox = false;
  String? _selectedNotificationId;
  bool _loading = true;
  String? _newsError;
  String? _inboxError;
  String? get _error => _showInbox ? _inboxError : _newsError;
  bool _refreshing = false;
  Future<void>? _reloadFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _infoLabel(AppL10n l, String key) {
    const labels = <String, Map<String, String>>{
      'de': {
        'search_hint': 'Mitteilungen & Nachrichten durchsuchen…',
        'search_empty': 'Keine passenden Einträge gefunden',
        'search_empty_hint': 'Versuche es mit einem anderen Suchbegriff.',
      },
      'en': {
        'search_hint': 'Search notifications & messages…',
        'search_empty': 'No matching entries found',
        'search_empty_hint': 'Try searching with another keyword.',
      },
      'fr': {
        'search_hint': 'Rechercher dans les notifications…',
        'search_empty': 'Aucun résultat trouvé',
        'search_empty_hint': 'Essayez avec un autre mot-clé.',
      },
      'es': {
        'search_hint': 'Buscar notificaciones…',
        'search_empty': 'No se encontraron notificaciones',
        'search_empty_hint': 'Intenta con otro término de búsqueda.',
      },
    };
    return (labels[l.locale] ?? labels['en']!)[key] ?? key;
  }

  List<_SchoolNotificationItem> _filterItems(
    List<_SchoolNotificationItem> items,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    final terms = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return items.where((item) {
      final text =
          '${item.title} ${item.previewBody} ${item.author ?? ''}'.toLowerCase();
      return terms.every((term) => text.contains(term));
    }).toList();
  }

  Widget _buildSearchBar(BuildContext context, AppL10n l) {
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final isExpressive = _usesExpressiveComponents(context);
    final double defaultRadius = isExpressive ? 28.0 : tokens.surfaceRadius;
    final radius = BorderRadius.circular(
      _resolvedSurfaceCornerRadius(defaultRadius),
    );

    return ThemedSurface(
      borderRadius: radius,
      color: isExpressive
          ? cs.surfaceContainerHigh.withValues(alpha: 0.55)
          : null,
      border: Border.all(
        color: tokens.id == AppThemeId.manga
            ? cs.outline
            : cs.outlineVariant.withValues(alpha: isExpressive ? 0.20 : 0.32),
        width: tokens.borderWidth,
      ),
      respectSurfaceCornerPreference: false,
      showShadow: false,
      child: TextField(
        key: const ValueKey('info-search-field'),
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          hintText: _infoLabel(l, 'search_hint'),
          hintStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant.withValues(alpha: 0.75),
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 21, color: cs.primary),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  String _messageForFailure(WebUntisFailure failure) {
    final l = appL10nFor(appLocaleNotifier.value);
    return switch (failure.kind) {
      WebUntisFailureKind.authentication => l.infoLoginRequired,
      WebUntisFailureKind.permission => l.infoNoPermission,
      _ => l.infoFetchError,
    };
  }

  DateTime? _lastUpdated;
  final Set<String> _unreadMessageIds = {};
  final Set<String> _seenMessageIds = {};

  String get _seenAccountId => activeUntisAccountId ?? 'legacy';

  Future<Set<String>> _loadSeenMessageIds() async {
    final key = OfflineCacheStore.instance.scopedKey(
      accountId: _seenAccountId,
      dataset: 'inboxSeen',
      entityKey: 'ids',
    );
    final document = await OfflineCacheStore.instance.read(key);
    final values = document?.value['ids'];
    if (values is! List) return const {};
    return values.map((entry) => '$entry').toSet();
  }

  Future<void> _persistSeenMessageIds(Set<String> ids) async {
    final key = OfflineCacheStore.instance.scopedKey(
      accountId: _seenAccountId,
      dataset: 'inboxSeen',
      entityKey: 'ids',
    );
    await OfflineCacheStore.instance.write(key, {
      'ids': ids.take(500).toList(),
    });
  }

  Future<void> _refreshInboxUnread(List<_SchoolNotificationItem> inbox) async {
    if (demoModeNotifier.value) {
      _unreadMessageIds.clear();
      unreadInboxMessagesNotifier.value = 0;
      if (mounted) setState(() {});
      return;
    }
    if (inbox.isEmpty) return;
    final accountId = _seenAccountId;
    final seen = await _loadSeenMessageIds();
    if (!mounted || accountId != _seenAccountId) return;
    final unread = inbox.where((item) => !seen.contains(item.id)).toList();
    _seenMessageIds
      ..clear()
      ..addAll(seen);
    _unreadMessageIds
      ..clear()
      ..addAll(unread.map((item) => item.id));
    unreadInboxMessagesNotifier.value = unread.length;
    if (mounted) setState(() {});
  }

  void _markMessageOpened(_SchoolNotificationItem item) {
    if (_unreadMessageIds.remove(item.id)) {
      _seenMessageIds.add(item.id);
      unreadInboxMessagesNotifier.value = _unreadMessageIds.length;
      if (mounted) setState(() {});
      unawaited(_persistSeenMessageIds(Set.unmodifiable(_seenMessageIds)));
      unawaited(AppHaptics.selection());
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      unawaited(_reload(showSpinner: true));
    }
  }

  @override
  void didUpdateWidget(covariant SchoolNotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      unawaited(_reload(showSpinner: true));
    }
  }

  Future<void> _reload({bool showSpinner = false}) {
    final activeReload = _reloadFuture;
    if (activeReload != null) return activeReload;

    if (mounted) setState(() => _refreshing = true);
    final reload = _performReload(showSpinner: showSpinner);
    late final Future<void> trackedReload;
    trackedReload = reload.whenComplete(() {
      if (identical(_reloadFuture, trackedReload)) _reloadFuture = null;
      if (mounted) setState(() => _refreshing = false);
    });
    _reloadFuture = trackedReload;
    return trackedReload;
  }

  Future<void> _performReload({bool showSpinner = false}) async {
    if (demoModeNotifier.value) {
      final locale = appLocaleNotifier.value;
      final fetchedNews = DemoModeService.demoNotifications(locale: locale).map(
        (raw) {
          return _SchoolNotificationItem(
            id: raw['id'].toString(),
            title: raw['title']?.toString() ?? '',
            body: raw['message']?.toString() ?? '',
            date: _parseNotificationDate(raw['date']),
            author: raw['author']?.toString(),
          );
        },
      ).toList();
      final fetchedInbox =
          DemoModeService.demoInboxNotifications(locale: locale).map((raw) {
            return _SchoolNotificationItem(
              id: raw['id'].toString(),
              title: raw['title']?.toString() ?? '',
              body:
                  raw['contentPreview']?.toString() ??
                  raw['message']?.toString() ??
                  '',
              fullBody: raw['content']?.toString() ?? '',
              date: _parseNotificationDate(raw['sentDateTime'] ?? raw['date']),
              author: raw['sender'] is Map
                  ? (raw['sender'] as Map)['displayName']?.toString()
                  : raw['author']?.toString(),
              attachments: (raw['attachments'] as List? ?? const [])
                  .whereType<Map>()
                  .map(
                    (m) => _MessageAttachment(
                      id: m['id'].toString(),
                      name: m['name'].toString(),
                      isDemo: true,
                    ),
                  )
                  .toList(),
            );
          }).toList();
      if (!mounted) return;
      setState(() {
        _newsItems = fetchedNews;
        _inboxItems = fetchedInbox;
        _selectedNotificationId = _firstNotificationId(
          _showInbox ? fetchedInbox : fetchedNews,
        );
        _loading = false;
        _newsError = null;
        _inboxError = null;
        _lastUpdated = DateTime.now();
      });
      unreadInboxMessagesNotifier.value = 0;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final summary = fetchedNews
            .take(3)
            .map((item) => item.title)
            .join('\n');
        unawaited(
          WidgetService.updateNotificationWidget(
            summary,
            accountId: activeUntisAccountId ?? 'active',
          ),
        );
      }
      return;
    }

    if (sessionID.isEmpty || schoolUrl.isEmpty || schoolName.isEmpty) {
      final reAuthenticated = await _reAuthenticate();
      if (!reAuthenticated ||
          sessionID.isEmpty ||
          schoolUrl.isEmpty ||
          schoolName.isEmpty) {
        if (!mounted) return;
        setState(() {
          _newsItems = const [];
          _inboxItems = const [];
          _selectedNotificationId = null;
          _loading = false;
          _newsError = appL10nFor(appLocaleNotifier.value).infoLoginRequired;
          _inboxError = _newsError;
          _lastUpdated = DateTime.now();
        });
        unreadInboxMessagesNotifier.value = 0;
        return;
      }
    }

    if ((showSpinner || (_newsItems.isEmpty && _inboxItems.isEmpty)) &&
        mounted) {
      setState(() {
        _loading = true;
        _newsError = null;
        _inboxError = null;
      });
    }

    try {
      final fetched = await _fetchSchoolNotifications();
      if (!mounted) return;
      setState(() {
        if (fetched.newsFailure == null) _newsItems = fetched.news;
        if (fetched.inboxFailure == null) _inboxItems = fetched.inbox;
        _newsError = fetched.newsFailure == null
            ? null
            : _messageForFailure(fetched.newsFailure!);
        _inboxError = fetched.inboxFailure == null
            ? null
            : _messageForFailure(fetched.inboxFailure!);
        final active = _showInbox ? _inboxItems : _newsItems;
        final hasExistingSelection = active.any(
          (item) => item.id == _selectedNotificationId,
        );
        _selectedNotificationId = hasExistingSelection
            ? _selectedNotificationId
            : _firstNotificationId(active);
        _loading = false;
        _lastUpdated = DateTime.now();
      });
      if (fetched.inboxFailure == null) {
        unawaited(_refreshInboxUnread(fetched.inbox));
      }
      if (fetched.newsFailure == null &&
          !kIsWeb &&
          (Platform.isAndroid || Platform.isIOS)) {
        final summary = fetched.news
            .take(3)
            .map((item) => item.title)
            .join('\n');
        unawaited(
          WidgetService.updateNotificationWidget(
            summary.isEmpty
                ? appL10nFor(appLocaleNotifier.value).notificationsNone
                : summary,
            accountId: activeUntisAccountId ?? 'active',
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _newsError = appL10nFor(appLocaleNotifier.value).infoFetchError;
        _inboxError = _newsError;
        _lastUpdated = DateTime.now();
      });
    }
  }

  Future<
    ({
      List<_SchoolNotificationItem> inbox,
      List<_SchoolNotificationItem> news,
      WebUntisFailure? inboxFailure,
      WebUntisFailure? newsFailure,
    })
  >
  _fetchSchoolNotifications() async {
    List<_MessageAttachment> parseMessageAttachments(Map<String, dynamic> map) {
      final out = <_MessageAttachment>[];
      final messageId =
          (map['id'] ?? map['messageId'] ?? '').toString().trim();
      final entries = <dynamic>[];
      for (final key in const [
        'attachments',
        'fileAttachments',
        'attachmentList',
        'files',
        'attachedFiles',
        'messageAttachments',
      ]) {
        final value = map[key];
        if (value is List) {
          entries.addAll(value);
        }
      }
      for (final key in const ['attachment', 'fileAttachment', 'file']) {
        final value = map[key];
        if (value is Map) entries.add(value);
      }
      for (final entry in entries) {
        if (entry is! Map) continue;
        final attachment = Map<String, dynamic>.from(entry);
        final id = (attachment['fileId'] ??
                attachment['attachmentId'] ??
                attachment['fileAttachmentId'] ??
                attachment['id'] ??
                attachment['uuid'] ??
                attachment['storageId'] ??
                '')
            .toString()
            .trim();
        final name = (attachment['fileRegularName'] ??
                attachment['fileName'] ??
                attachment['filename'] ??
                attachment['regularName'] ??
                attachment['name'] ??
                attachment['displayName'] ??
                attachment['title'] ??
                attachment['originalName'] ??
                attachment['originalFileName'] ??
                '')
            .toString()
            .trim();
        final url = attachment['url']?.toString();
        if (id.isEmpty && name.isEmpty) continue;
        out.add(
          _MessageAttachment(
            id: id,
            name: name.isNotEmpty ? name : 'Attachment',
            messageId: messageId.isNotEmpty ? messageId : null,
            url: url,
          ),
        );
      }
      return out;
    }

    List<_SchoolNotificationItem> toItems(List<Map<String, dynamic>> raw) {
      final seen = <String>{};
      final items = <_SchoolNotificationItem>[];

      for (final map in raw) {
        final title =
            (map['title'] ??
                    map['subject'] ??
                    map['headline'] ??
                    map['name'] ??
                    '')
                .toString()
                .trim();
        final body =
            (map['message'] ??
                    map['text'] ??
                    map['content'] ??
                    map['description'] ??
                    '')
                .toString()
                .trim();
        if (title.isEmpty && body.isEmpty) continue;

        final id =
            (map['id'] ?? map['messageId'] ?? map['uuid'] ?? '$title-$body')
                .toString();
        if (!seen.add(id)) continue;

        final dt = _parseNotificationDate(
          map['date'] ??
              map['startDate'] ??
              map['publishDate'] ??
              map['timestamp'] ??
              map['created'] ??
              map['createdAt'] ??
              map['lastModified'],
        );

        items.add(
          _SchoolNotificationItem(
            id: id,
            title: title.isEmpty
                ? appL10nFor(appLocaleNotifier.value).infoTitle
                : title,
            body: body,
            fullBody: (map['fullBody'] ?? map['content'] ?? '')
                .toString()
                .trim(),
            date: dt,
            author:
                (map['author'] ?? map['createdBy'] ?? map['publisher'] ?? '')
                    .toString()
                    .trim()
                    .isEmpty
                ? null
                : (map['author'] ?? map['createdBy'] ?? map['publisher'])
                      .toString()
                      .trim(),
            url: _pickNotificationUrl(map),
            attachments: parseMessageAttachments(map),
          ),
        );
      }

      items.sort((a, b) => b.sortValue.compareTo(a.sortValue));
      return items;
    }

    final fetched = await SchoolInfoRepository().fetch(
      schoolUrl: schoolUrl,
      schoolName: schoolName,
      sessionId: sessionID,
      reauthenticate: () async => await _reAuthenticate() ? sessionID : null,
    );
    return (
      inbox: toItems(fetched.inbox),
      news: toItems(fetched.news),
      inboxFailure: fetched.inboxFailure,
      newsFailure: fetched.newsFailure,
    );
  }

  DateTime? _parseNotificationDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      if (raw > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      if (raw > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
      }
    }
    final untisDate = parseUntisDate(raw);
    if (untisDate != null) return untisDate;
    return DateTime.tryParse(raw.toString().trim());
  }

  String? _pickNotificationUrl(Map<String, dynamic> map) {
    final candidates = [
      map['url'],
      map['link'],
      map['href'],
      map['targetUrl'],
      map['attachmentUrl'],
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (isSafeSchoolExternalUrl(text)) return text;
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(
      'dd.MM.yyyy, HH:mm',
      _icuLocale(appLocaleNotifier.value),
    ).format(date);
  }

  Future<void> _openInfoUrl(BuildContext context, String? value) async {
    if (!isSafeSchoolExternalUrl(value)) return;
    final ok = await url_launcher.launchUrlString(
      value!,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      context.showUntisSnackBar(
        appL10nFor(appLocaleNotifier.value).settingsGithubOpenFailed,
      );
    }
  }

  String? _firstNotificationId(List<_SchoolNotificationItem> items) =>
      items.isEmpty ? null : items.first.id;

  _SchoolNotificationItem? _selectedItem(List<_SchoolNotificationItem> items) {
    for (final item in items) {
      if (item.id == _selectedNotificationId) return item;
    }
    return items.isEmpty ? null : items.first;
  }

  Widget _buildTabletNotificationList(
    BuildContext context,
    List<_SchoolNotificationItem> items,
    _SchoolNotificationItem? selected,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isExpressive = _usesExpressiveComponents(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.id == selected?.id;
        final isUnread = _showInbox && _unreadMessageIds.contains(item.id);
        final itemRadius = BorderRadius.circular(isExpressive ? 20 : 16);
        return Material(
          color: isSelected
              ? cs.secondaryContainer.withValues(alpha: 0.85)
              : cs.surfaceContainerLow.withValues(alpha: 0.56),
          borderRadius: itemRadius,
          child: InkWell(
            borderRadius: itemRadius,
            onTap: () {
              if (_showInbox) _markMessageOpened(item);
              setState(() => _selectedNotificationId = item.id);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isExpressive ? 12 : 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: isExpressive ? 44 : 40,
                    height: isExpressive ? 44 : 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withValues(alpha: 0.22)
                          : (_showInbox
                              ? cs.secondary.withValues(alpha: 0.16)
                              : cs.primary.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(
                        isExpressive ? 14 : 12,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _showInbox
                          ? (isUnread
                              ? Icons.mark_email_unread_rounded
                              : Icons.mail_rounded)
                          : Icons.campaign_rounded,
                      color: isSelected
                          ? cs.primary
                          : (_showInbox ? cs.secondary : cs.primary),
                      size: isExpressive ? 22 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  fontSize: 15,
                                  color: isSelected
                                      ? cs.onSecondaryContainer
                                      : cs.onSurface,
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.previewBody.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.previewBody,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: isSelected
                                  ? cs.onSecondaryContainer.withValues(
                                      alpha: 0.8,
                                    )
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (item.date != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            _formatDate(item.date),
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? cs.onSecondaryContainer.withValues(
                                      alpha: 0.75,
                                    )
                                  : cs.onSurfaceVariant.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMessageComposer() async {
    final sent = await Navigator.push<bool>(
      context,
      _buildBouncyRoute(const _MessageComposePage()),
    );
    if (!mounted || sent != true) return;
    setState(() => _showInbox = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appL10nFor(appLocaleNotifier.value).messageSent),
        behavior: SnackBarBehavior.floating,
      ),
    );
    unawaited(_reload());
  }

  @override
  Widget build(BuildContext context) {
    final l = appL10nFor(appLocaleNotifier.value);
    final cs = Theme.of(context).colorScheme;
    final tokens = untisThemeTokensOf(context);
    final isExpressive = _usesExpressiveComponents(context);
    final rawActiveItems = _showInbox ? _inboxItems : _newsItems;
    final activeItems = _filterItems(rawActiveItems);
    final isExpanded = UntisLayout.isTablet(context);
    final masterWidth = (MediaQuery.sizeOf(context).width * 0.34)
        .clamp(280.0, 360.0)
        .toDouble();
    final selectedItem = _selectedItem(activeItems);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _mainTabHeaderAppBar(
        context,
        l.infoTitle,
        actions: [
          if (_showInbox)
            IconButton(
              tooltip: l.messageComposeTitle,
              onPressed: _openMessageComposer,
              icon: const Icon(Icons.edit_rounded),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: _lastUpdated == null
                  ? l.reload
                  : '${l.reload} (${_formatDate(_lastUpdated)})',
              onPressed: _refreshing ? null : _reload,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _refreshing
                    ? SizedBox(
                        key: const ValueKey('notifications-refreshing'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        key: ValueKey('notifications-refresh'),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ExpressiveRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: UntisLayout.pagePadding(context, bottom: 150).copyWith(
                top: MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
              ),
              children: [
                _buildSearchBar(context, l),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isExpressive ? 20 : 16,
                        ),
                      ),
                    ),
                    side: WidgetStateProperty.resolveWith((states) {
                      return BorderSide(
                        color: cs.outlineVariant.withValues(
                          alpha: isExpressive ? 0.20 : 0.32,
                        ),
                        width: tokens.borderWidth,
                      );
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return cs.secondaryContainer.withValues(alpha: 0.90);
                      }
                      return cs.surfaceContainerLow.withValues(alpha: 0.50);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return cs.onSecondaryContainer;
                      }
                      return cs.onSurfaceVariant;
                    }),
                    textStyle: WidgetStateProperty.all(
                      GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(l.start),
                      icon: Icon(
                        _showInbox
                            ? Icons.campaign_outlined
                            : Icons.campaign_rounded,
                      ),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(l.notifications),
                      icon: Badge(
                        isLabelVisible: _unreadMessageIds.isNotEmpty,
                        label: Text('${_unreadMessageIds.length}'),
                        child: Icon(
                          _showInbox
                              ? Icons.inbox_rounded
                              : Icons.inbox_outlined,
                        ),
                      ),
                    ),
                  ],
                  selected: {_showInbox},
                  onSelectionChanged: (selection) {
                    final showInbox = selection.first;
                    if (showInbox == _showInbox) return;
                    unawaited(AppHaptics.selection());
                    setState(() {
                      _showInbox = showInbox;
                      _selectedNotificationId = _firstNotificationId(
                        showInbox ? _inboxItems : _newsItems,
                      );
                    });
                  },
                ),
                if (_loading && rawActiveItems.isEmpty) ...[
                  const SizedBox(height: 100),
                  const Center(child: CircularProgressIndicator()),
                ] else ...[
                  if (_refreshing && activeItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ThemedSurface(
                        borderRadius: BorderRadius.circular(
                          isExpressive ? 20 : 16,
                        ),
                        color: cs.errorContainer.withValues(alpha: 0.55),
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.3),
                          width: tokens.borderWidth,
                        ),
                        respectSurfaceCornerPreference: false,
                        showShadow: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: cs.error,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: GoogleFonts.outfit(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (rawActiveItems.isEmpty)
                    _buildUnifiedEmptyState(
                      context: context,
                      icon: _showInbox
                          ? Icons.inbox_outlined
                          : Icons.campaign_outlined,
                      title: l.infoEmpty,
                      hint: l.infoEmptyHint,
                    )
                  else if (activeItems.isEmpty)
                    _buildUnifiedEmptyState(
                      context: context,
                      icon: Icons.search_off_rounded,
                      title: _infoLabel(l, 'search_empty'),
                      hint: _infoLabel(l, 'search_empty_hint'),
                    )
                  else if (isExpanded)
                    SizedBox(
                      height: (MediaQuery.sizeOf(context).height - 250).clamp(
                        420.0,
                        980.0,
                      ),
                      child: Row(
                        key: const ValueKey('notifications-master-detail'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: masterWidth,
                            child: _buildTabletNotificationList(
                              context,
                              activeItems,
                              selectedItem,
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                isExpressive ? 24 : 16,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: selectedItem == null
                                    ? Center(
                                        key: const ValueKey(
                                          'notifications-empty-detail',
                                        ),
                                        child: _buildUnifiedEmptyState(
                                          context: context,
                                          icon: _showInbox
                                              ? Icons.inbox_outlined
                                              : Icons.campaign_outlined,
                                          title: l.infoEmpty,
                                          hint: l.infoEmptyHint,
                                        ),
                                      )
                                    : KeyedSubtree(
                                        key: ValueKey(selectedItem.id),
                                        child: _SchoolNotificationDetailPage(
                                          item: selectedItem,
                                          isInbox: _showInbox,
                                        ).buildEmbedded(context),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...activeItems.map((item) {
                      final isUnread =
                          _showInbox && _unreadMessageIds.contains(item.id);
                      final cardRadius = BorderRadius.circular(
                        isExpressive ? 24 : 18,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ThemedSurface(
                          borderRadius: cardRadius,
                          color: isUnread
                              ? cs.secondaryContainer.withValues(alpha: 0.55)
                              : cs.surfaceContainerLow.withValues(alpha: 0.65),
                          border: Border.all(
                            color: isUnread
                                ? cs.secondary.withValues(alpha: 0.3)
                                : cs.outlineVariant.withValues(
                                    alpha: isExpressive ? 0.20 : 0.30,
                                  ),
                            width: tokens.borderWidth,
                          ),
                          respectSurfaceCornerPreference: false,
                          showShadow: false,
                          child: Material(
                            type: MaterialType.transparency,
                            borderRadius: cardRadius,
                            child: InkWell(
                              borderRadius: cardRadius,
                              onTap: () {
                                if (_showInbox) _markMessageOpened(item);
                                Navigator.push(
                                  context,
                                  _buildBouncyRoute(
                                    _SchoolNotificationDetailPage(
                                      item: item,
                                      isInbox: _showInbox,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: isExpressive ? 44 : 40,
                                          height: isExpressive ? 44 : 40,
                                          decoration: BoxDecoration(
                                            color: _showInbox
                                                ? (isUnread
                                                    ? cs.secondaryContainer
                                                    : cs.secondary.withValues(
                                                        alpha: 0.16,
                                                      ))
                                                : cs.primary.withValues(
                                                    alpha: 0.12,
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(
                                              isExpressive ? 14 : 12,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            _showInbox
                                                ? (isUnread
                                                    ? Icons
                                                        .mark_email_unread_rounded
                                                    : Icons.mail_rounded)
                                                : Icons.campaign_rounded,
                                            color: _showInbox
                                                ? (isUnread
                                                    ? cs.onSecondaryContainer
                                                    : cs.secondary)
                                                : cs.primary,
                                            size: isExpressive ? 22 : 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 16.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        height: 1.2,
                                                        color: cs.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isUnread) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      width: 9,
                                                      height: 9,
                                                      decoration:
                                                          BoxDecoration(
                                                        color: cs.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    if (item.previewBody.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        item.previewBody,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurfaceVariant,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if (item.date != null)
                                          _infoChip(
                                            context,
                                            _formatDate(item.date),
                                            Icons.schedule_rounded,
                                          ),
                                        if ((item.author ?? '').isNotEmpty)
                                          _infoChip(
                                            context,
                                            item.author!,
                                            Icons.person_outline_rounded,
                                          ),
                                        if (item.attachments.isNotEmpty)
                                          _infoAttachmentSummary(
                                            context,
                                            item,
                                          ),
                                      ],
                                    ),
                                    if (item.url != null) ...[
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _openInfoUrl(context, item.url),
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          l.infoOpenLink,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(BuildContext context, String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final isExpressive = _usesExpressiveComponents(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(isExpressive ? 12 : 8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoAttachmentSummary(
    BuildContext context,
    _SchoolNotificationItem item,
  ) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final isExpressive = _usesExpressiveComponents(context);
    final ext = item.uniformAttachmentExtension;
    final label = l.infoAttachmentLabel(item.attachments.length, ext);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(isExpressive ? 12 : 8),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file_rounded, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight renderer for the safe subset of HTML returned by Untis.
/// It deliberately keeps layout elements such as headings, lists and tables
/// while avoiding a WebView or an HTML rendering package in the app bundle.
class _InfoHtmlBody extends StatelessWidget {
  const _InfoHtmlBody({required this.document, required this.onOpenUrl});

  final html_dom.Document document;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final nodes = document.body?.nodes ?? const <html_dom.Node>[];
    final blocks = nodes
        .map((node) => _block(context, node))
        .whereType<Widget>()
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget? _block(BuildContext context, html_dom.Node node) {
    if (node is html_dom.Text) {
      final value = _normalizedText(node.data);
      if (value.trim().isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _richText(context, [node]),
      );
    }
    if (node is! html_dom.Element) return null;

    switch (node.localName) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
        final size = switch (node.localName) {
          'h1' => 22.0,
          'h2' => 19.0,
          'h3' => 17.0,
          _ => 15.0,
        };
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: _richText(
            context,
            node.nodes,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w900),
          ),
        );
      case 'ul':
      case 'ol':
        final items = node.children.where((item) => item.localName == 'li');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in items.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          node.localName == 'ol' ? '${entry.$1 + 1}.' : '•',
                          style: _baseStyle(context),
                        ),
                      ),
                      Expanded(child: _richText(context, entry.$2.nodes)),
                    ],
                  ),
                ),
            ],
          ),
        );
      case 'table':
        return _table(context, node);
      case 'img':
        final source = node.attributes['src'];
        if (source == null || source.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              source,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _richText(context, node.nodes),
        );
    }
  }

  Widget _table(BuildContext context, html_dom.Element table) {
    final cs = Theme.of(context).colorScheme;
    final rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(
            color: cs.outlineVariant.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          children: [
            for (final row in rows)
              TableRow(
                children: [
                  for (final cell in row.children.where(
                    (item) => item.localName == 'th' || item.localName == 'td',
                  ))
                    Container(
                      constraints: const BoxConstraints(minWidth: 96),
                      color: cell.localName == 'th'
                          ? cs.primaryContainer
                          : cs.surfaceContainerHigh,
                      padding: const EdgeInsets.all(8),
                      child: _richText(
                        context,
                        cell.nodes,
                        style: cell.localName == 'th'
                            ? TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _richText(
    BuildContext context,
    List<html_dom.Node> nodes, {
    TextStyle? style,
  }) {
    return Text.rich(
      TextSpan(
        style: _baseStyle(context).merge(style),
        children: _spans(context, nodes, style),
      ),
    );
  }

  List<InlineSpan> _spans(
    BuildContext context,
    List<html_dom.Node> nodes,
    TextStyle? inherited,
  ) {
    final spans = <InlineSpan>[];
    var endsWithBreak = false;
    for (final node in nodes) {
      if (node is html_dom.Text) {
        final value = _normalizedText(node.data);
        if (value.isNotEmpty) {
          spans.add(TextSpan(text: value));
          endsWithBreak = value.endsWith('\n');
        }
        continue;
      }
      if (node is! html_dom.Element) continue;
      if (node.localName == 'br') {
        spans.add(const TextSpan(text: '\n'));
        endsWithBreak = true;
        continue;
      }

      final style = switch (node.localName) {
        'strong' || 'b' => const TextStyle(fontWeight: FontWeight.w800),
        'em' || 'i' => const TextStyle(fontStyle: FontStyle.italic),
        'code' => TextStyle(
          fontFamily: 'monospace',
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
        _ => null,
      };
      if (node.localName == 'a') {
        final href = node.attributes['href'];
        final label = _normalizedText(node.text);
        if (href != null && href.isNotEmpty && label.isNotEmpty) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: InkWell(
                onTap: () => onOpenUrl(href),
                child: Text(
                  label,
                  style: _baseStyle(context).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          );
        }
        continue;
      }
      if (_infoBlockTags.contains(node.localName)) {
        if (!endsWithBreak) spans.add(const TextSpan(text: '\n'));
        spans.add(
          TextSpan(
            style: inherited?.merge(style) ?? style,
            children: _spans(context, node.nodes, style),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
        endsWithBreak = true;
        continue;
      }
      spans.add(
        TextSpan(
          style: inherited?.merge(style) ?? style,
          children: _spans(context, node.nodes, style),
        ),
      );
    }
    return spans;
  }

  static const Set<String> _infoBlockTags = {
    'div',
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'section',
    'article',
    'ul',
    'ol',
    'table',
    'pre',
  };

  TextStyle _baseStyle(BuildContext context) => GoogleFonts.outfit(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 14,
    height: 1.4,
  );

  String _normalizedText(String value) {
    var result = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    result = result.replaceAll(RegExp(r' *\n *'), '\n');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return result;
  }
}
