part of ebisu.ebisu_dart_meta;

/// Access for member variable - ia - inaccessible, ro - read/only, rw read/write
class Access implements Comparable<Access> {
  static const IA = const Access._(0);
  static const RO = const Access._(1);
  static const RW = const Access._(2);
  static const WO = const Access._(3);

  static get values => [IA, RO, RW, WO];

  final int value;

  int get hashCode => value;

  const Access._(this.value);

  copy() => this;

  int compareTo(Access other) => value.compareTo(other.value);

  String toString() {
    switch (this) {
      case IA:
        return "Ia";
      case RO:
        return "Ro";
      case RW:
        return "Rw";
      case WO:
        return "Wo";
    }
    return null;
  }

  static Access fromString(String s) {
    if (s == null) return null;
    switch (s) {
      case "Ia":
        return IA;
      case "Ro":
        return RO;
      case "Rw":
        return RW;
      case "Wo":
        return WO;
      default:
        return null;
    }
  }

  int toJson() => value;
  static Access fromJson(int v) {
    return v == null ? null : values[v];
  }
}

/// Dependency type of a PubDependency
class PubDepType implements Comparable<PubDepType> {
  static const PATH = const PubDepType._(0);
  static const GIT = const PubDepType._(1);
  static const HOSTED = const PubDepType._(2);

  static get values => [PATH, GIT, HOSTED];

  final int value;

  int get hashCode => value;

  const PubDepType._(this.value);

  copy() => this;

  int compareTo(PubDepType other) => value.compareTo(other.value);

  String toString() {
    switch (this) {
      case PATH:
        return "Path";
      case GIT:
        return "Git";
      case HOSTED:
        return "Hosted";
    }
    return null;
  }

  static PubDepType fromString(String s) {
    if (s == null) return null;
    switch (s) {
      case "Path":
        return PATH;
      case "Git":
        return GIT;
      case "Hosted":
        return HOSTED;
      default:
        return null;
    }
  }

  int toJson() => value;
  static PubDepType fromJson(int v) {
    return v == null ? null : values[v];
  }
}

// custom <part dart_meta>

get IA => Access.IA;
get RO => Access.RO;
get RW => Access.RW;
get WO => Access.WO;

Id id(String _id) => new Id(_id);
Enum enum_(String _id) => new Enum(id(_id));
System system(String _id) => new System(id(_id));
App app(String _id) => new App(id(_id));
Library library(String _id) => new Library(id(_id));
Variable variable(String _id) => new Variable(id(_id));
Part part(String _id) => new Part(id(_id));
Class class_(String _id) => new Class(id(_id));

/// Create new member from snake case id
Member member(String _id) => new Member(id(_id));
PubSpec pubspec(String _id) => new PubSpec(id(_id));
PubDependency pubdep(String name) => new PubDependency(name);
Script script(String _id) => new Script(id(_id));
ScriptArg scriptArg(String _id) => new ScriptArg(id(_id));
Benchmark benchmark(String _id) => new Benchmark(id(_id));

final RegExp _jsonableTypeRe =
    new RegExp(r"\b(?:int|double|num|String|bool|DateTime)\b");
final RegExp _mapTypeRe = new RegExp(r"Map\b");
final RegExp _listTypeRe = new RegExp(r"List\b");
final RegExp _setTypeRe = new RegExp(r"\bSet\b");
final RegExp _splayTreeSetTypeRe = new RegExp(r"\bSplayTreeSet\b");
final RegExp _jsonMapTypeRe = new RegExp(r"Map<\s*.*\s*,\s*(.*?)\s*>");
final RegExp _jsonListTypeRe = new RegExp(r"List<\s*(.*?)\s*>");
final RegExp _templateParameterTypeRe = new RegExp(r"\w+<\s*(.*?)\s*>");
final RegExp _generalMapKeyTypeRe = new RegExp(r"Map<\s*([^,]+),.+\s*>");

bool isJsonableType(String t) => _jsonableTypeRe.firstMatch(t) != null;
bool isMapType(String t) => _mapTypeRe.firstMatch(t) != null;
bool isListType(String t) => _listTypeRe.firstMatch(t) != null;
bool isSetType(String t) => _setTypeRe.firstMatch(t) != null;
bool isSplayTreeSetType(String t) => _splayTreeSetTypeRe.firstMatch(t) != null;

String jsonMapValueType(String t) {
  Match m = _jsonMapTypeRe.firstMatch(t);
  if (m != null) {
    return m.group(1);
  }
  return 'dynamic';
}
String generalMapKeyType(String t) {
  Match m = _generalMapKeyTypeRe.firstMatch(t);
  if (m != null) {
    return m.group(1);
  }
  return 'String';
}
String jsonListValueType(String t) {
  Match m = _jsonListTypeRe.firstMatch(t);
  if (m != null) {
    return m.group(1);
  }
  return 'dynamic';
}
String templateParameterType(String t) {
  Match m = _templateParameterTypeRe.firstMatch(t);
  if (m != null) {
    return m.group(1);
  }
  return 'dynamic';
}

Library testLibrary(String s) => library(s)..isTest = true;
String importUri(String s) => Library.importUri(s);
String importStatement(String s) => Library.importStatement(s);

// end <part dart_meta>

RegExp _pubTypeRe = new RegExp(r"(git:|http:|[./.])");
