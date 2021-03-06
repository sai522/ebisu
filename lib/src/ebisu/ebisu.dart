part of ebisu.ebisu;

// custom <part ebisu>

/// Return a new string with [text] wrapped in `/*...*/` comment block
String blockComment(String text, [String indent = '   ']) {
  return "/**\n${indentBlock(text, indent)}\n*/";
}

/// Return a new string with [text] wrapped in `///` doc comment block
String docComment(String text, [String indent = ' ']) {
  String guts = text
      .split('\n')
      .join("\n///$indent")
      .replaceAll(_commentLineTrailingWhite, '///\n')
      .replaceAll(_commentFinalTrailingWhite, '///');
  return "///$indent$guts";
}

/// Return a new string with each line [block] indented by [indent]
String indentBlock(String block, [String indent = '  ']) {
  return block == null
      ? null
      : block
          .split('\n')
          .map((p) => "$indent$p".replaceAll(_allWhiteSpace, ''))
          .join('\n');
}

/// Given list of lines, appends a suffix to all lines but the last.
List<String> prepJoin(List<String> lines, [String suffix = ',']) {
  for (int i = 0; i < lines.length - 1; i++) {
    lines[i] += suffix;
  }
  return lines;
}

/// Given list of lines, joins with sep on all including the last
String joinIncludeEnd(List<String> lines, [String sep = ';\n']) =>
    (lines.length > 0) ? (lines.join(sep) + sep) : '';

/// Join the entries with spaces by default taking care break at maxLenth
String formatFill(List<String> entries,
    {String indent: '  ', String sep: ' ', int maxLength: 80}) {
  if (entries.length == 0) return '';
  List<String> result = [];
  String current = '${entries.first}';
  int currentLength = 0;
  for (int i = 1; i < entries.length; i++) {
    var entry = entries[i];
    if ((current.length + entry.length) >= maxLength) {
      result.add(current);
      current = '$indent$entry';
    } else {
      current += '$sep$entry';
    }
  }
  if (current.length > 0) {
    result.add(current);
  }
  return result.join('\n');
}

const String customBegin = r'//\s*custom';
const String customEnd = r'//\s*end';
const String customBlockText = '''
// ${'custom'} <TAG>
// ${'end'} <TAG>
''';

/// Returns an empty customBlock_ with the [tag] as identifier.  The
/// customBlock_ is a block of code that can be stored in a C, Dart, D,
/// etc. code file allowing custom_ (i.e. user hand written) text to be
/// protected during the (re)generation of that code file.
///
/// For example, the call to `customBlock('main')` would return:
///
///     // custom <main>
///     // end <main>
///
/// thus allowing lines of text to be written between the lines containing `//
/// custom <main>` and `// end <main>`
String customBlock(String tag) {
  return customBlockText.replaceAll('TAG', tag);
}

const String htmlCustomBegin = r'<!--\s*custom';
const String htmlCustomEnd = r'<!--\s*end';
const String htmlCustomBlockText = '''
<!-- custom <TAG> -->
<!-- end <TAG> -->
''';
String htmlCustomBlock(String tag) {
  return htmlCustomBlockText.replaceAll('TAG', tag);
}

bool htmlMergeWithFile(String generated, String destFilePath) {
  return mergeWithFile(generated, destFilePath, htmlCustomBegin, htmlCustomEnd);
}

const String panDocCustomBegin = r'<!---\s*custom';
const String panDocCustomEnd = r'<!---\s*end';
const String panDocCustomBlockText = '''
<!--- custom <TAG> --->
<!--- end <TAG> --->
''';
String panDocCustomBlock(String tag) {
  return panDocCustomBlockText.replaceAll('TAG', tag);
}

bool panDocMergeWithFile(String generated, String destFilePath) {
  return mergeWithFile(
      generated, destFilePath, panDocCustomBegin, panDocCustomEnd);
}

const String cssCustomBegin = r'/\*\s*custom';
const String cssCustomEnd = r'/\*\s*end';
const String cssCustomBlockText = '''
/* custom <TAG> */
/* end <TAG> */
''';
String cssCustomBlock(String tag) {
  return cssCustomBlockText.replaceAll('TAG', tag);
}

bool cssMergeWithFile(String generated, String destFilePath) {
  return mergeWithFile(generated, destFilePath, cssCustomBegin, cssCustomEnd);
}

const String scriptCustomBegin = r'#\s*custom';
const String scriptCustomEnd = r'#\s*end';
const String scriptCustomBlockText = '''
# custom <TAG>
# end <TAG>
''';
String scriptCustomBlock(String tag) {
  return scriptCustomBlockText.replaceAll('TAG', tag);
}

bool scriptMergeWithFile(String generated, String destFilePath) {
  return mergeWithFile(
      generated, destFilePath, scriptCustomBegin, scriptCustomEnd);
}

final RegExp _trailingNewline = new RegExp(r'\n$');
final RegExp _trailingNewlines = new RegExp(r'\n*$');
final RegExp _leadingWhiteSpace = new RegExp(r'^\s+');
final RegExp _trailingWhiteSpace = new RegExp(r'\s+$');
final RegExp _anyWhiteSpace = new RegExp(r'\s+');
final RegExp _allWhiteSpace = new RegExp(r'^\s+$');
final RegExp _multipleNewlines = new RegExp(r'\n\n+');
final RegExp _commentLineTrailingWhite = new RegExp(r'///\s+\n');
final RegExp _commentFinalTrailingWhite = new RegExp(r'///\s+$');

/// Removes trailing any `\n` from `s`
String chomp(String s, [bool multiple = false]) {
  String result = multiple
      ? s.replaceFirst(_trailingNewlines, '')
      : s.replaceFirst(_trailingNewline, '');
  return result;
}

/// Removes left side white space
String leftTrim(String s) => s.replaceFirst(_leadingWhiteSpace, '');
String rightTrim(String s) => s.replaceFirst(_trailingWhiteSpace, '');

String reduceVerticalWhitespace(String s) =>
    s.replaceAll(_multipleNewlines, '\n\n');

const List _defaultProtectionPair = const [customBegin, customEnd];
const List _defaultProtections = const [_defaultProtectionPair];

typedef String PostProcessor(String);

bool mergeBlocksWithFile(String generated, String destFilePath,
    [List protections = _defaultProtections, PostProcessor postProcessor]) {
  File inFile = new File(destFilePath);
  if (inFile.existsSync()) {
    String currentText = inFile.readAsStringSync();
    protections.forEach((pair) {
      generated = mergeWithContents(generated, currentText, pair[0], pair[1]);
    });

    if (postProcessor != null) {
      generated = postProcessor(generated);
    }

    if (generated == currentText) {
      print('No change: $destFilePath');
      return false;
    } else {
      inFile.writeAsStringSync(generated);
      print('Wrote: $destFilePath');
    }
  } else {
    new Directory(path.dirname(destFilePath))..createSync(recursive: true);
    inFile.writeAsStringSync(generated);
    print('Created $destFilePath');
  }
}

bool mergeWithFile(String generated, String destFilePath,
    [String beginProtect = customBegin, String endProtect = customEnd,
    PostProcessor postProcessor]) {
  return mergeBlocksWithFile(
      generated, destFilePath, [[beginProtect, endProtect]], postProcessor);
}

String mergeWithContents(String generated, String currentText,
    String beginProtect, String endProtect) {
  Map<String, String> captures = {};
  Map<String, String> empties = {};

  RegExp block = new RegExp('\\n?[^\\S\\n]*?${beginProtect}' // Look for begin
      '\\s+<(.*?)>(?:.|\\n)*?' // Eat - non-greedy
      '${endProtect}\\s+<\\1>', // Require matching end
      multiLine: true);

  block.allMatches(currentText).forEach((m) {
    captures[m.group(1)] = m.group(0);
  });
  block.allMatches(generated).forEach((m) {
    empties[m.group(1)] = m.group(0);
  });

  captures.forEach((k, v) {
    if (!empties.containsKey(k)) {
      print('Warning: protect block <$k> removed');
    } else {
      generated = generated.replaceFirst(empties[k], captures[k]);
    }
  });
  return generated;
}

List<String> cleanImports(List<String> dirtyImports) {
  List<String> result = [];
  var hit = new Set<String>();
  dirtyImports.forEach((i) {
    i = i.replaceAll('"', "'");
    if (hit.contains(i)) return;
    hit.add(i);
    result.add(i);
  });
  result.sort();
  return result;
}

String smartQuote(String s) =>
    ((s.indexOf("'") == -1) && (s.indexOf('"') == -1)) ? "'$s'" : s;

var _normalizeRe = new RegExp(r'\s+');
var _blockCommentRe =
    new RegExp(r'/\*[^*]*\*+(?:[^*/][^*]*\*+)*/', multiLine: true);
var _lineCommentRe = new RegExp(r'//.*');

decomment(String s) =>
    s.replaceAll(_blockCommentRe, '').replaceAll(_lineCommentRe, '');

bool codeEquivalent(String s1, String s2, {bool stripComments: false}) {
  if (stripComments) {
    s1 = decomment(s1);
    s2 = decomment(s2);
  }
  return s1.replaceAll(_normalizeRe, ' ') == s2.replaceAll(_normalizeRe, ' ');
}

String darkMatter(String s) => s.replaceAll(_anyWhiteSpace, '');

final _dartFormatter = new DartFormatter();

/// Passes *contents* through *dart_style* formatting
String dartFormat(String contents) {
  try {
    return _dartFormatter.format(contents);
  } on Exception catch (ex) {
    _logger.warning('''
Caught exception $ex
-------------------------------------------------------------
$contents
-------------------------------------------------------------
''');
    return contents;
  }
}

bool _useDartFormatter = Platform.environment['EBISU_DART_FORMAT'] != null &&
    Platform.environment['EBISU_DART_FORMAT'] != '';

/// when set will format generated code using awesome *dart_style* package
set useDartFormatter(bool v) => _useDartFormatter = v;
get useDartFormatter => _useDartFormatter;

bool mergeWithDartFile(String generated, String destFilePath,
    {bool useFormatter}) {
  if (useFormatter == null) useFormatter = _useDartFormatter;
  return mergeWithFile(generated, destFilePath, customBegin, customEnd,
      useFormatter ? dartFormat : null);
}

/// ignores null objects and empty strings
bool _ignored(Object o) => o == null || (o is String && o == '');

/// If provided an iterable of items joins each with *nl*
///  mnemonic: like <br> in html
String br(Object o) => o == null
    ? null
    : o is Iterable ? br(combine(o)) : _ignored(o) ? '' : '$o\n';

/// combines the parts recursively if necessary
String combine(Iterable<Object> parts) {
  final result = parts
      .map((o) => (o is Iterable) ? combine(o) : o)
      .where((o) => !_ignored(o))
      .join('\n');
  return result;
}

// end <part ebisu>
