import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

bool isSafeSchoolExternalUrl(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'https' || uri.scheme == 'http');
}

html_dom.Document sanitizeSchoolHtml(String source) {
  final document = html_parser.parse(source);

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
      if (value != null && !isSafeSchoolExternalUrl(value)) {
        element.attributes.remove(attribute);
      }
    }
  }

  return document;
}

String normalizeSchoolPlainText(String value) {
  var result = value.replaceAll(RegExp(r'[ \t]+'), ' ');
  result = result.replaceAll(RegExp(r' *\n *'), '\n');
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return result.trim();
}

String schoolHtmlToPlainText(html_dom.Document document) {
  final buffer = StringBuffer();
  var lastWasSpace = true;

  void writeText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (!lastWasSpace) buffer.write(' ');
    buffer.write(trimmed);
    lastWasSpace = false;
  }

  void walk(Iterable<html_dom.Node> nodes) {
    for (final node in nodes) {
      if (node is html_dom.Text) {
        writeText(node.data);
        continue;
      }
      if (node is! html_dom.Element) continue;
      final tag = node.localName;
      if (tag == 'br') {
        buffer.write('\n');
        lastWasSpace = true;
        continue;
      }
      const blocks = {
        'p',
        'div',
        'h1',
        'h2',
        'h3',
        'h4',
        'blockquote',
        'pre',
        'section',
        'article',
        'ul',
        'ol',
        'table',
      };
      if (tag == 'li') {
        buffer.write('\n• ');
        lastWasSpace = true;
      }
      if (blocks.contains(tag) && tag != 'li') {
        buffer.write('\n');
        lastWasSpace = true;
      }
      if (tag == 'td' || tag == 'th') {
        buffer.write(' – ');
        lastWasSpace = true;
      }
      walk(node.nodes);
      if (blocks.contains(tag) && tag != 'li') {
        buffer.write('\n');
        lastWasSpace = true;
      }
    }
  }

  walk(document.body?.nodes ?? const []);
  return normalizeSchoolPlainText(buffer.toString());
}
