part of '../main.dart';

class _MessageAttachment {
  final String id;
  final String name;
  final bool isDemo;

  const _MessageAttachment({
    required this.id,
    required this.name,
    this.isDemo = false,
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

  const _SchoolNotificationItem({
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
  String? _error;
  DateTime? _lastUpdated;

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

  Future<void> _reload({bool showSpinner = false}) async {
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
        _error = null;
        _lastUpdated = DateTime.now();
      });
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
          _error = null;
          _lastUpdated = DateTime.now();
        });
        return;
      }
    }

    if ((showSpinner || (_newsItems.isEmpty && _inboxItems.isEmpty)) &&
        mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final fetched = await _fetchSchoolNotifications();
      if (!mounted) return;
      setState(() {
        _newsItems = fetched.news;
        _inboxItems = fetched.inbox;
        final active = _showInbox ? fetched.inbox : fetched.news;
        final hasExistingSelection = active.any(
          (item) => item.id == _selectedNotificationId,
        );
        _selectedNotificationId = hasExistingSelection
            ? _selectedNotificationId
            : _firstNotificationId(active);
        _loading = false;
        _error = null;
        _lastUpdated = DateTime.now();
      });
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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
        _error = appL10nFor(appLocaleNotifier.value).infoFetchError;
        _lastUpdated = DateTime.now();
      });
    }
  }

  Future<
    ({List<_SchoolNotificationItem> inbox, List<_SchoolNotificationItem> news})
  >
  _fetchSchoolNotifications() async {
    final start = DateTime.now().subtract(const Duration(days: 45));
    final end = DateTime.now().add(const Duration(days: 90));
    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);

    String encodedSchoolName() {
      try {
        return '_${base64Encode(utf8.encode(schoolName))}';
      } catch (_) {
        return schoolName;
      }
    }

    final schoolCookieCandidates = <String>{
      encodedSchoolName(),
      schoolName,
    }.where((e) => e.isNotEmpty).toList(growable: false);

    Map<String, String> buildHeaders(
      String schoolCookie, {
      Map<String, String>? extra,
    }) {
      return {
        'Cookie': 'JSESSIONID=$sessionID; schoolname=$schoolCookie',
        'Accept': 'application/json',
        ...?extra,
      };
    }

    Future<http.Response?> requestWithCookieFallback(
      Future<http.Response> Function(Map<String, String> headers) sender, {
      bool retry = true,
    }) async {
      for (final schoolCookie in schoolCookieCandidates) {
        try {
          final response = await sender(buildHeaders(schoolCookie));
          if (response.statusCode == 200) return response;
          if ((response.statusCode == 401 || response.statusCode == 403) &&
              retry &&
              await _reAuthenticate()) {
            return await requestWithCookieFallback(sender, retry: false);
          }
        } catch (_) {}
      }
      return null;
    }

    List<dynamic> extractList(dynamic decoded) {
      if (decoded is List) return decoded;
      if (decoded is Map) {
        for (final value in decoded.values) {
          final nested = extractList(value);
          if (nested.isNotEmpty) return nested;
        }
      }
      return const [];
    }

    Future<String?> fetchJwtToken() async {
      final uri = Uri.parse('https://$schoolUrl/WebUntis/api/token/new');
      final response = await requestWithCookieFallback(
        (headers) => http.get(uri, headers: headers),
      );
      if (response == null || response.body.trim().isEmpty) return null;

      final raw = response.body.trim();
      if (!raw.startsWith('{')) return raw.replaceAll('"', '').trim();
      try {
        final decoded = jsonDecode(raw);
        if (decoded is String && decoded.trim().isNotEmpty) {
          return decoded.trim();
        }
        if (decoded is Map) {
          final token =
              decoded['token'] ??
              decoded['jwt'] ??
              decoded['jwt_token'] ??
              decoded['accessToken'];
          if (token != null && token.toString().trim().isNotEmpty) {
            return token.toString().trim();
          }
        }
      } catch (_) {}
      return null;
    }

    List<_MessageAttachment> parseMessageAttachments(Map<String, dynamic> map) {
      final out = <_MessageAttachment>[];
      dynamic rawAttachments;
      for (final key in const [
        'attachments',
        'fileAttachments',
        'attachmentList',
        'files',
      ]) {
        final value = map[key];
        if (value is List) {
          rawAttachments = value;
          break;
        }
      }
      if (rawAttachments is! List) return out;
      for (final entry in rawAttachments) {
        if (entry is! Map) continue;
        final attachment = Map<String, dynamic>.from(entry);
        final id =
            (attachment['fileId'] ??
                    attachment['attachmentId'] ??
                    attachment['fileAttachmentId'] ??
                    attachment['id'] ??
                    '')
                .toString();
        final name =
            (attachment['fileRegularName'] ??
                    attachment['fileName'] ??
                    attachment['regularName'] ??
                    attachment['name'] ??
                    '')
                .toString()
                .trim();
        if (id.isEmpty && name.isEmpty) continue;
        out.add(_MessageAttachment(id: id, name: name));
      }
      return out;
    }

    Future<List<Map<String, dynamic>>> fetchInboxMessages() async {
      final token = await fetchJwtToken();
      if (token == null || token.isEmpty) return const [];
      final uri = Uri.parse(
        'https://$schoolUrl/WebUntis/api/rest/view/v1/messages',
      );
      final response = await requestWithCookieFallback(
        (headers) => http.get(
          uri,
          headers: {...headers, 'Authorization': 'Bearer $token'},
        ),
      );
      if (response == null || response.body.trim().isEmpty) return const [];
      try {
        final decoded = jsonDecode(response.body);
        final incoming = decoded is Map ? decoded['incomingMessages'] : null;
        if (incoming is! List) return const [];
        return incoming
            .whereType<Map>()
            .map((raw) {
              final rawMap = Map<String, dynamic>.from(raw);
              // Some WebUntis deployments wrap the fields in a "message"
              // object, others expose them directly on the entry.
              final map = rawMap['message'] is Map
                  ? Map<String, dynamic>.from(rawMap['message'])
                  : rawMap;
              final sender = map['sender'];
              final preview =
                  map['contentPreview'] ?? map['message'] ?? map['text'] ?? '';
              final content = map['content'] ?? preview;
              return {
                ...map,
                'message': preview,
                'fullBody': content,
                'author': sender is Map
                    ? sender['displayName'] ?? sender['name']
                    : null,
                'date': map['sentDateTime'] ?? map['date'] ?? map['sendTime'],
                'attachments': parseMessageAttachments(map),
              };
            })
            .toList(growable: false);
      } catch (_) {
        return const [];
      }
    }

    Future<List<Map<String, dynamic>>> fetchNewsWidgetMessages() async {
      final out = <Map<String, dynamic>>[];
      final days = List.generate(
        4,
        (index) => DateTime.now().subtract(Duration(days: index)),
      );

      for (final day in days) {
        final untisDate = DateFormat('yyyyMMdd').format(day);
        final uri = Uri.parse(
          'https://$schoolUrl/WebUntis/api/public/news/newsWidgetData?date=$untisDate',
        );
        final response = await requestWithCookieFallback(
          (headers) => http.get(uri, headers: headers),
        );
        if (response == null || response.body.trim().isEmpty) continue;

        try {
          final decoded = jsonDecode(response.body);
          final data = decoded is Map ? decoded['data'] : null;
          final messagesOfDay = data is Map ? data['messagesOfDay'] : null;
          if (messagesOfDay is! List) continue;

          for (final entry in messagesOfDay) {
            if (entry is! Map) continue;
            final map = Map<String, dynamic>.from(entry);
            out.add({
              ...map,
              'date': map['date'] ?? untisDate,
              'message': map['text'] ?? map['message'] ?? '',
            });
          }
        } catch (_) {}
      }

      return out;
    }

    Future<List<dynamic>> tryGet(String path, {bool retry = true}) async {
      final uri = Uri.parse('https://$schoolUrl$path');
      final response = await requestWithCookieFallback(
        (headers) => http.get(uri, headers: headers),
        retry: retry,
      );

      if (response == null || response.body.trim().isEmpty) {
        return const [];
      }

      try {
        return extractList(jsonDecode(response.body));
      } catch (_) {}
      return const [];
    }

    Future<List<dynamic>> tryJsonRpc(
      String method,
      Map<String, dynamic> params, {
      bool retry = true,
    }) async {
      final uri = Uri.parse(
        'https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName',
      );
      final response = await requestWithCookieFallback(
        (headers) => http.post(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': 'school-info',
            'method': method,
            'params': params,
            'jsonrpc': '2.0',
          }),
        ),
        retry: retry,
      );

      if (response == null || response.body.trim().isEmpty) {
        return const [];
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          return const [];
        }
        if (decoded is Map) {
          return extractList(decoded['result'] ?? decoded);
        }
        return extractList(decoded);
      } catch (_) {}
      return const [];
    }

    // WebUntis distinguishes personal Mitteilungen from its public Start
    // feed. Fetch both in parallel and keep them separate in the UI so a
    // reload cannot silently replace one category with the other.
    final initialResults = await Future.wait([
      fetchInboxMessages(),
      fetchNewsWidgetMessages(),
    ]);
    final inboxMessages = initialResults[0];
    List<dynamic> schoolMessages = initialResults[1];

    if (schoolMessages.isEmpty) {
      final schoolFallbacks = [
        () => tryJsonRpc('getMessagesOfDay2017', {
          'date': DateFormat('yyyyMMdd').format(DateTime.now()),
        }),
        () => tryGet(
          '/WebUntis/api/public/messages?startDate=$startStr&endDate=$endStr',
        ),
        () => tryGet(
          '/WebUntis/api/messages?startDate=$startStr&endDate=$endStr',
        ),
        () => tryGet(
          '/WebUntis/api/public/notifications?startDate=$startStr&endDate=$endStr',
        ),
        () => tryGet(
          '/WebUntis/api/public/notices?startDate=$startStr&endDate=$endStr',
        ),
        () => tryJsonRpc('getMessagesOfDay', {
          'date': DateFormat('yyyyMMdd').format(DateTime.now()),
        }),
        () => tryJsonRpc('getMessages', {
          'startDate': startStr,
          'endDate': endStr,
        }),
      ];

      for (final fallback in schoolFallbacks) {
        schoolMessages = await fallback();
        if (schoolMessages.isNotEmpty) break;
      }
    }

    List<_SchoolNotificationItem> toItems(List<dynamic> raw) {
      final seen = <String>{};
      final items = <_SchoolNotificationItem>[];

      for (final entry in raw) {
        if (entry is! Map) continue;
        final map = Map<String, dynamic>.from(entry);

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
        if (seen.contains(id)) continue;
        seen.add(id);

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

    return (inbox: toItems(inboxMessages), news: toItems(schoolMessages));
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
      final s = raw.toString();
      if (s.length == 8) {
        try {
          return DateTime.parse(
            '${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}',
          );
        } catch (_) {
          return null;
        }
      }
    }

    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      try {
        return DateTime.parse(
          '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}',
        );
      } catch (_) {
        return null;
      }
    }
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
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
      if (text.startsWith('http://') || text.startsWith('https://')) {
        return text;
      }
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

  bool _isSafeExternalUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  html_dom.Document _safeInfoDocument(String source) {
    final document = html_parser.parse(source);

    // School notices are remote content. Keep their visual structure but never
    // render executable or embedded browser content inside the app.
    for (final element in document.querySelectorAll(
      'script, style, iframe, object, embed, form, input, button, video, audio, source',
    )) {
      element.remove();
    }

    for (final element in document.querySelectorAll('*')) {
      final attributes = element.attributes.keys.toList(growable: false);
      for (final rawAttribute in attributes) {
        final attribute = rawAttribute.toString();
        if (attribute.toLowerCase().startsWith('on')) {
          element.attributes.remove(attribute);
        }
      }
      for (final attribute in const ['href', 'src']) {
        final value = element.attributes[attribute];
        if (value != null && !_isSafeExternalUrl(value)) {
          element.attributes.remove(attribute);
        }
      }
    }
    return document;
  }

  Future<void> _openInfoUrl(BuildContext context, String? value) async {
    if (!_isSafeExternalUrl(value)) return;
    final ok = await url_launcher.launchUrlString(
      value!,
      mode: url_launcher.LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appL10nFor(appLocaleNotifier.value).settingsGithubOpenFailed,
          ),
        ),
      );
    }
  }

  Widget _buildFormattedInfoBody(BuildContext context, String body) {
    return _InfoHtmlBody(
      document: _safeInfoDocument(body),
      onOpenUrl: (url) => _openInfoUrl(context, url),
    );
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item.id == selected?.id;
        return Material(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.72)
              : cs.surfaceContainerLow.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _selectedNotificationId = item.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _showInbox
                        ? Icons.mail_outline_rounded
                        : Icons.campaign_rounded,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? cs.onPrimaryContainer
                                : cs.onSurface,
                          ),
                        ),
                        if (item.body.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            _normalizedDetailText(
                              _detailToPlainText(
                                _detailSafeInfoDocument(item.body),
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
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
    final activeItems = _showInbox ? _inboxItems : _newsItems;
    final isExpanded = UntisLayout.isExpanded(context);
    final selectedItem = _selectedItem(activeItems);

    return Scaffold(
      backgroundColor: cs.surface,
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
              tooltip: l.infoReload,
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _AnimatedBackground(child: SizedBox.expand())),
          ExpressiveRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: UntisLayout.pagePadding(context, bottom: 150),
              children: [
                if (_loading && activeItems.isEmpty) ...[
                  const SizedBox(height: 140),
                  const Center(child: CircularProgressIndicator()),
                ] else ...[
                  _buildInfoSummaryCard(cs, l, activeItems.length),
                  Row(
                    children: [
                      Expanded(
                        child: _infoModeButton(
                          label: l.start,
                          icon: Icons.campaign_rounded,
                          selected: !_showInbox,
                          onTap: () => setState(() {
                            _showInbox = false;
                            _selectedNotificationId = _firstNotificationId(
                              _newsItems,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _infoModeButton(
                          label: l.notifications,
                          icon: Icons.mail_outline_rounded,
                          selected: _showInbox,
                          onTap: () => setState(() {
                            _showInbox = true;
                            _selectedNotificationId = _firstNotificationId(
                              _inboxItems,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _glassContainer(
                        context: context,
                        borderRadius: BorderRadius.circular(18),
                        color: cs.errorContainer.withValues(alpha: 0.55),
                        border: Border.all(
                          color: cs.error.withValues(alpha: 0.3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _error!,
                            style: GoogleFonts.outfit(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (activeItems.isEmpty)
                    _glassContainer(
                      context: context,
                      borderRadius: BorderRadius.circular(24),
                      color: cs.primaryContainer.withValues(alpha: 0.2),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.infoEmpty,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.infoEmptyHint,
                              style: GoogleFonts.outfit(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            width: 360,
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
                            child: selectedItem == null
                                ? Center(
                                    child: Text(
                                      l.infoEmpty,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : _SchoolNotificationDetailPage(
                                    item: selectedItem,
                                    isInbox: _showInbox,
                                  ).buildEmbedded(context),
                          ),
                        ],
                      ),
                    )
                  else
                    ...activeItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _glassContainer(
                          context: context,
                          borderRadius: BorderRadius.circular(24),
                          color: cs.surfaceContainerLow.withValues(alpha: 0.62),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
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
                                    children: [
                                      Icon(
                                        _showInbox
                                            ? Icons.mail_outline_rounded
                                            : Icons.campaign_rounded,
                                        size: 18,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.body.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildFormattedInfoBody(context, item.body),
                                  ],
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
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
                                    ],
                                  ),
                                  if (item.attachments.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _infoAttachmentSummary(context, item),
                                  ],
                                  if (item.url != null) ...[
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openInfoUrl(context, item.url),
                                      icon: const Icon(
                                        Icons.open_in_new_rounded,
                                      ),
                                      label: Text(l.infoOpenLink),
                                    ),
                                  ],
                                ],
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

  Widget _buildInfoSummaryCard(ColorScheme cs, AppL10n l, int count) {
    final subtitle = _lastUpdated == null
        ? l.infoTitle
        : '${l.infoUpdated}: ${_formatDate(_lastUpdated)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _glassContainer(
        context: context,
        borderRadius: BorderRadius.circular(24),
        color: cs.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _showInbox
                      ? Icons.mail_outline_rounded
                      : Icons.campaign_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1 ? '1 ${l.infoTitle}' : '$count ${l.infoTitle}',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoModeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(14),
      color: selected
          ? cs.primary
          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
      border: Border.all(
        color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: selected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return _glassContainer(
      context: context,
      borderRadius: BorderRadius.circular(999),
      color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoAttachmentSummary(
    BuildContext context,
    _SchoolNotificationItem item,
  ) {
    final cs = Theme.of(context).colorScheme;
    final l = appL10nFor(appLocaleNotifier.value);
    final ext = item.uniformAttachmentExtension;
    final label = l.infoAttachmentLabel(item.attachments.length, ext);
    return Row(
      children: [
        Icon(Icons.attach_file_rounded, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
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
      if (value.isEmpty) return null;
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
    for (final node in nodes) {
      if (node is html_dom.Text) {
        final value = _normalizedText(node.data);
        if (value.isNotEmpty) spans.add(TextSpan(text: value));
        continue;
      }
      if (node is! html_dom.Element) continue;
      if (node.localName == 'br') {
        spans.add(const TextSpan(text: '\n'));
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
      spans.add(
        TextSpan(
          style: inherited?.merge(style) ?? style,
          children: _spans(context, node.nodes, style),
        ),
      );
    }
    return spans;
  }

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
