part of ebisu.ebisu_dart_meta;

/// Metadata associated with a constructor
class Ctor {

  /// Name of the class of this ctor.
  String className;
  /// Name of the ctor. If 'default' generated as name of class, otherwise as CLASS.NAME()
  String name;
  /// List of members initialized in this ctor
  List<Member> members = [];
  /// List of optional members initialized in this ctor (i.e. those in [])
  List<Member> optMembers = [];
  /// List of optional members initialized in this ctor (i.e. those in {})
  List<Member> namedMembers = [];
  /// If true includes custom block for additional user supplied ctor code
  bool hasCustom = false;
  /// True if the variable is const
  bool isConst = false;

  // custom <class Ctor>

  Ctor();

  String get qualifiedName => (name == 'default' || name == '')?
    className : '${className}.${name}';

  String get ctorSansNew {
    var classId = idFromString(className);
    var id =
    (name == 'default' || name == '')?
    classId :
    ((name == '_default')?
        idFromString('${classId.snake}_default') :
        new Id('${classId.snake}_${idFromString(name).snake}'));

    List<String> parms = [];
    List<String> args = [];
    if(members.length > 0) {
      List<String> required = [];
      members.forEach((m) => required.add('${m.type} ${m.varName}'));
      parms.add("${required.join(',\n')}");
      args.add(members.map((m) => '  ${m.varName}').join(',\n'));
    }
    if(optMembers.length > 0) {
      List<String> optional = [];
      optMembers.forEach((m) =>
          optional.add('    ${m.type} ${m.varName}' +
              ((m.ctorInit == null)? '' : ' = ${m.ctorInit}')));
      parms.add("  [\n${optional.join(',\n')}\n  ]");
      args.add(optMembers.map((m) => '  ${m.varName}').join(',\n'));
    }
    if(namedMembers.length > 0) {
      List<String> named = [];
      namedMembers.forEach((m) =>
          named.add('    ${m.type} ${m.varName}' +
                    ((m.ctorInit == null)? '':' : ${m.ctorInit}')));
      parms.add("  {\n${named.join(',\n')}\n  }");
      args.add(namedMembers.map((m) => '  ${m.varName}:${m.varName}').join(',\n'));
    }
    String parmText = parms.join(',\n');
    String argText = args.join(',\n');
    bool hasParms = parms.length > 0;
    bool allowAllOptional = optMembers.length == 0 && namedMembers.length == 0;

    var lb = hasParms && allowAllOptional ? '[' : '';
    var rb = hasParms && allowAllOptional ? ']' : '';
    return '''

/// Create a ${className} sans new, for more declarative construction
${className}
${id.camel}($lb${leftTrim(chomp(indentBlock(parmText, '  ')))}$rb) =>
  new ${qualifiedName}(${leftTrim(chomp(indentBlock(argText, '    ')))});
''';
  }

  String get ctorText {
    List<String> result = [];
    if(members.length > 0) {
      List<String> required = [];
      members.forEach((m) => required.add('this.${m.varName}'));
      result.addAll(prepJoin(required));
    }
    if(optMembers.length > 0) {
      if(result.length > 0) result[result.length-1] += ',';
      result.add('[');
      List<String> optional = [];
      optMembers.forEach((m) =>
          optional.add('this.${m.varName}' +
              ((m.ctorInit == null)? '' : ' = ${m.ctorInit}')));
      result.addAll(prepJoin(optional));
      result.add(']');
    }
    if(namedMembers.length > 0) {
      if(result.length > 0) result[result.length-1] += ',';
      result.add('{');
      List<String> named = [];
      namedMembers.forEach((m) =>
        named.add('this.${m.varName}' +
            ((m.ctorInit == null)? '':' : ${m.ctorInit}')));
      result.addAll(prepJoin(named));
      result.add('}');
    }

    String cb = hasCustom?
    indentBlock(rightTrim(customBlock('${qualifiedName}'))): '';
    String constTag = isConst? 'const ' : '';
    String body = (isConst || !hasCustom)? ';' : ''' {
${chomp(cb, true)}
}''';

    List decl = [];
    var method = '${constTag}${qualifiedName}(';
    if(result.length > 0) {
      decl
        ..add('$method${result.removeAt(0)}')
        ..addAll(result);
    } else {
      decl.add(method);
    }

    return '''
${formatFill(decl)})${body}
''';
  }

  // end <class Ctor>
}

/// Metadata associated with a member of a Dart class
class Member {

  Member(this._id);

  /// Id for this class member
  Id get id => _id;
  /// Documentation for this class member
  String doc;
  /// Reference to parent of this class member
  dynamic get parent => _parent;
  /// Type of the member
  String type = 'String';
  /// Access level supported for this member
  Access access;
  /// If provided the member will be initialized with value.
  /// The type of the member can be inferred from the type
  /// of this value.  Member type is defaulted to String. If
  /// the type of classInit is a String and type of the
  /// member is String, the text will be quoted if it is not
  /// already. If the type of classInit is other than string
  /// and the type of member is String (which is default)
  /// the type of member will be set to
  /// classInit.runtimeType.
  dynamic classInit;
  /// If provided the member will be initialized to this
  /// text in generated ctor initializers
  String ctorInit;
  /// List of ctor names to include this member in
  List<String> ctors = [];
  /// List of ctor names to include this member in as optional parameter
  List<String> ctorsOpt = [];
  /// List of ctor names to include this member in as named optional parameter
  List<String> ctorsNamed = [];
  /// True if the member is final
  bool isFinal = false;
  /// True if the member is const
  bool isConst = false;
  /// True if the member is static
  bool isStatic = false;
  /// True if the member should not be serialized if the parent class has jsonSupport
  bool jsonTransient = false;
  /// If true annotated with observable
  bool isObservable = false;
  /// Name of variable for the member, excluding access prefix (i.e. no '_')
  String get name => _name;
  /// Name of variable for the member - varies depending on public/private
  String get varName => _varName;

  // custom <class Member>

  bool get isPublic => access == Access.RW;

  bool get isMap => isMapType(type);
  bool get isList => isListType(type);
  bool get isMapOrList => isMap || isList;

  set parent(p) {
    _name = id.camel;
    if(type == 'String' &&
        (classInit != null) &&
        (classInit is! String)) {
      type = '${classInit.runtimeType}';
      if(type.contains('LinkedHashMap')) type = 'Map';
    }
    if(access == null) access = Access.RW;
    _varName = isPublic? _name : "_$_name";
    _parent = p;
  }

  bool get hasGetter => !isPublic && access == RO;
  bool get hasSetter => !isPublic && access == WO;

  bool get hasPublicCode => isPublic || hasGetter || hasSetter;
  bool get hasPrivateCode => !isPublic;

  String get finalDecl => isFinal? 'final ' : '';
  String get observableDecl => isObservable? '@observable ' : '';
  String get staticDecl => isStatic? 'static ' : '';

  String get decl =>
    (classInit == null)?
    "${observableDecl}${staticDecl}${finalDecl}${type} ${varName};" :
    ((type == 'String')?
        "${observableDecl}${staticDecl}${finalDecl}${type} ${varName} = ${smartQuote(classInit)};" :
        "${observableDecl}${staticDecl}${finalDecl}${type} ${varName} = ${classInit};");

  String get publicCode {
    //print("$name has public code");
    var result = [];
    if(doc != null) result.add('${docComment(rightTrim(doc))}');
    if(hasGetter) {
      result.add('$type get $name => $varName;');
    }
    if(hasSetter) {
      result.add('set $name($type $name) => $varName = $name;');
    }
    if(isPublic) result.add(decl);
    return result.join('\n');
  }

  String get privateCode {
    var result = [];
    if(doc != null && !hasPublicCode) result.add('${docComment(rightTrim(doc))}');
    if(!isPublic) result.add(decl);
    return result.join('\n');
  }

  // end <class Member>
  final Id _id;
  dynamic _parent;
  String _name;
  String _varName;
}

/// Metadata associated with a Dart class
class Class {

  Class(this._id);

  /// Id for this Dart class
  Id get id => _id;
  /// Documentation for this Dart class
  String doc;
  /// Reference to parent of this Dart class
  dynamic get parent => _parent;
  /// True if Dart class is public.
  /// Code generation support will prefix private variables appropriately
  bool isPublic = true;
  /// List of mixins
  List<String> mixins = [];
  /// Any extends (NOTE extend not extends) declaration for the class - conflicts with mixin
  String extend;
  /// Any implements (NOTE implement not implements)
  List<String> implement = [];
  /// If true a custom section will be included for Dart class
  bool includeCustom = true;
  /// Default access for members
  set defaultMemberAccess(Access defaultMemberAccess) => _defaultMemberAccess = defaultMemberAccess;
  /// List of members of this class
  List<Member> members = [];
  /// List of ctors requiring custom block
  List<String> ctorCustoms = [];
  /// List of ctors that should be const
  List<String> ctorConst = [];
  /// List of ctors of this class
  Map<String,Ctor> get ctors => _ctors;
  /// If true, class is abstract
  bool isAbstract = false;
  /// If true, generate toJson/fromJson on all members that are not jsonTransient
  bool jsonSupport = false;
  /// If true, generate randJson function
  bool hasRandJson = false;
  /// If true, generate operator== using all members
  bool opEquals = false;
  /// If true, implements comparable
  bool comparable = false;
  /// If true adds '..ctors[''] to all members (i.e. ensures generation of empty ctor with all members passed as arguments)
  bool courtesyCtor = false;
  /// If true adds sets all members to final
  bool allMembersFinal = false;
  /// If true adds empty default ctor
  bool defaultCtor = false;
  /// If true creates library functions to construct forwarding to ctors
  set ctorSansNew(bool ctorSansNew) => _ctorSansNew = ctorSansNew;
  /// If true includes a copy function
  bool copyable = false;
  /// Name of the class - sans any access prefix (i.e. no '_')
  String get name => _name;
  /// Name of the class, including access prefix
  String get className => _className;
  /// Additional code included in the class near the top
  String topInjection;
  /// Additional code included in the class near the bottom
  String bottomInjection;

  // custom <class Class>


  bool get ctorSansNew => _ctorSansNew == null?
  _parent.ctorSansNew : _ctorSansNew;

  List<Member> get publicMembers =>
    members.where((member) => member.isPublic).toList();

  List<Member> get privateMembers =>
    members.where((member) => !member.isPublic).toList();

  List<Member> get nonStaticMembers =>
    members.where((member) => !member.isStatic).toList();

  List<Ctor> get publicCtors =>
    ctors
    .keys
    .where((String name) => name.length == 0 || name[0] != '_')
    .map((String name) => ctors[name])
    .toList();

  bool get requiresEqualityHelpers =>
    opEquals && members.any((m) => m.isMapOrList);

  String get jsonCtor {
    if(_ctors.containsKey('_default')) {
      return "${_className}._default";
    } else {
      return _className;
    }
  }

  static String memberCompare(m) {
    final myName = m.varName == 'other'? 'this.other' : m.varName;
    final otherName = 'other.${m.varName}';
    if(m.type.startsWith('List')) {
      return '    const ListEquality().equals($myName, $otherName)';
    } else if(m.type.startsWith('Map')) {
      return '    const MapEquality().equals($myName, $otherName)';
    } else {
      return '    $myName == $otherName';
    }
  }

  String get overrideHashCode {
    var parts = ['''{
  int result = 17;
  final int prime = 23;'''];
    nonStaticMembers.forEach((m) {
      if(m.isList) {
        parts.add('  result = result*prime + const ListEquality<${jsonListValueType(m.type)}>().hash(${m.varName});');
      } else if(m.isMap) {
        parts.add('  result = result*prime + const MapEquality().hash(${m.varName});');
      } else {
        parts.add('  result = result*prime + ${m.varName}.hashCode;');
      }
    });
    return (parts..addAll(['  return result;', '}'])).join('\n');
  }

  String get opEqualsMethod => '''
bool operator==($_className other) =>
  identical(this, other) ||
  ${nonStaticMembers.map((m) => memberCompare(m))
    .join(' &&\n')};

int get hashCode ${overrideHashCode}
''';

  static final _simpleCopies = new Set.from(['int', 'double', 'num', 'bool',
      'String', 'DateTime', 'Date' ]);

  static _assignCopy(String type, String varname) {
    if(_simpleCopies.contains(type)) return varname;
    if(isMapType(type)) {
      return 'valueApply($varname, (v) => ${_assignCopy(jsonMapValueType(type), "v")})';
    }
    if(isListType(type)) {
      final elementType = jsonListValueType(type);
      if(_simpleCopies.contains(elementType)) {
        return 'new List.from($varname)';
      } else {
        return 'new List.from(${varname}.map((e) => ${_assignCopy(elementType, "e")}))';
      }
    }
    return '${varname} == null? null : ${varname}.copy()';
  }

  String get copyMethod {
    var terms = [];
    members.forEach((m) {
      final rhs = _assignCopy(m.type, m.varName);
      terms.add('\n  ..${m.varName} = $rhs');
    });
    var ctorName = defaultCtor? _className : '${_className}._default';
    return 'copy() => new ${ctorName}()${terms.join()};\n';
  }

  String get comparableMethod {
    var comparableMembers = members;
    if(comparableMembers.length == 1) {
      return '''
int compareTo($_className other) =>
  ${comparableMembers[0].varName}.compareTo(other.${comparableMembers[0].varName});
''';
    }
    var terms = [];
    members.forEach((m) {
      terms.add('((result = ${m.varName}.compareTo(other.${m.varName})) == 0)');
    });
    return '''
int compareTo($_className other) {
  int result = 0;
  ${terms.join(' &&\n  ')};
  return result;
}
''';
  }


  get defaultMemberAccess => _defaultMemberAccess == null ?
    (_parent == null? null : _parent.defaultMemberAccess) : _defaultMemberAccess;

  setDefaultMemberAccess(Member m) {
    if(m.access == null) m.access = defaultMemberAccess;
  }

  set parent(p) {
    _parent = p;
    _name = id.capCamel;
    _className = isPublic? _name : "_$_name";
    _ctors.clear();

    if(defaultCtor && courtesyCtor) {
      throw new
        ArgumentError('$_name can not have defaultCtor and courtesyCtor both set to true');
    }

    if(defaultCtor)
      _ctors.putIfAbsent('', () => new Ctor()
          ..name = ''
          ..className = _className);

    if(allMembersFinal)
      members.forEach((m) => m.isFinal = true);

    if(comparable)
      implement.add('Comparable<$_className>');

    if(courtesyCtor)
      members.forEach(
        (m) {
          if(!m.ctors.contains('')) m.ctors.add('');
        });

    // Iterate on all members and create the appropriate ctors
    members.forEach((m) {

      setDefaultMemberAccess(m);

      m.parent = this;

      makeCtorName(ctorName) {
        if(ctorName == '') return '';
        bool isPrivate = ctorName.startsWith('_');
        if(isPrivate) {
          return '_${idFromString(ctorName.substring(1)).camel}';
        } else {
          return idFromString(ctorName).camel;
        }
      }

      m.ctors.forEach((ctorName) {
        ctorName = makeCtorName(ctorName);
        Ctor ctor = _ctors.putIfAbsent(ctorName, () => new Ctor())
          ..name = ctorName
          ..hasCustom = ctorCustoms.contains(ctorName)
          ..isConst = ctorConst.contains(ctorName)
          ..className = _className
          ..members.add(m);
      });
      m.ctorsOpt.forEach((ctorName) {
        ctorName = makeCtorName(ctorName);
        Ctor ctor = _ctors.putIfAbsent(ctorName, () => new Ctor())
          ..name = ctorName
          ..hasCustom = ctorCustoms.contains(ctorName)
          ..isConst = ctorConst.contains(ctorName)
          ..className = _className
          ..optMembers.add(m);
      });
      m.ctorsNamed.forEach((ctorName) {
        ctorName = makeCtorName(ctorName);
        Ctor ctor = _ctors.putIfAbsent(ctorName, () => new Ctor())
          ..name = ctorName
          ..hasCustom = ctorCustoms.contains(ctorName)
          ..isConst = ctorConst.contains(ctorName)
          ..className = _className
          ..namedMembers.add(m);
      });
    });

    // To deserialize or copy a default ctor is needed
    if(_hasPrivateDefaultCtor) {
      _ctors.putIfAbsent('_default', () => new Ctor())
        ..name = '_default'
        ..className = _name;
    }
  }

  bool get _hasPrivateDefaultCtor => (copyable || jsonSupport) && !defaultCtor;

  List get orderedCtors {
    var keys = _ctors.keys.toList();
    bool hasDefault = keys.remove('');
    var privates = keys.where((k) => k[0]=='_').toList();
    var publics = keys.where((k) => k[0]!='_').toList();
    privates.sort();
    publics.sort();
    var result = new List.from(publics)..addAll(privates);
    if(hasDefault) {
      result.insert(0, '');
    }
    return result;
  }

  String get implementsClause {
    if(implement.length>0) {
      return ' implements ${implement.join(',\n    ')} ';
    } else {
      return ' ';
    }
  }

  static String _fromJsonData(String type, String source) {
    if(isClassJsonable(type)) {
      return '${type}.fromJson($source)';
    } else if(type == 'DateTime') {
      return 'DateTime.parse($source)';
    }
    return source;
  }

  static String _stringCheck(String type, String source) => type == 'String'?
  source : '$type.fromString($source)';

  String _fromJsonMapMember(Member member, [ String source = 'jsonMap' ]) {
    List results = [];
    var lhs = '${member.varName}';
    var key = '"${member.name}"';
    var value = '$source[$key]';
    String rhs;
    if(isClassJsonable(member.type)) {
      results.add('$lhs = ${member.type}.fromJson($value);');
    } else {
      if(isMapType(member.type)) {
        results.add('''

// ${member.name} is ${member.type}
$lhs = {};
$value.forEach((k,v) {
  $lhs[
  ${indentBlock(_stringCheck(generalMapKeyType(member.type), 'k'))}
  ] = ${_fromJsonData(jsonMapValueType(member.type), 'v')};
});''');
      } else if(isListType(member.type)) {
        results.add('''

// ${member.name} is ${member.type}
$lhs = [];
$value.forEach((v) {
  $lhs.add(${_fromJsonData(jsonListValueType(member.type), 'v')});
});''');
      } else {
        results.add('$lhs = $value;');
      }
    }
    return results.join('\n');
  }

  String fromJsonMapImpl() {
    List result = [ 'void _fromJsonMapImpl(Map jsonMap) {' ];

    result
      .add(
        indentBlock(
          members
          .where((m) => !m.jsonTransient)
          .map((m) => _fromJsonMapMember(m))
          .join('\n'))
           );
    result.add('}');
    return result.join('\n');
  }

  String define() {
    if(parent == null) parent = library('stub');
    return _content;
  }

  dynamic noSuchMethod(Invocation msg) {
    throw new ArgumentError("Class does not support ${msg.memberName}");
  }

  get _content =>
    [
      _docComment,
      _classOpener,
      _orderedCtors,
      _opEquals,
      _comparable,
      _copyable,
      _memberPublicCode,
      _topInjection,
      _includeCustom,
      _jsonSerialization,
      _randJson,
      _memberPrivateCode,
      _bottomInjection,
      _classCloser,
      _ctorSansNewImpl
    ]
    .where((line) => line != '')
    .join('\n');

  get _docComment => doc != null? docComment(doc) : '';
  get _abstractTag => isAbstract? 'abstract ':'';
  get _classOpener => '$_classWithExtends${implementsClause}{\n';
  get _classWithExtends => mixins.length>0?
    ('${_abstractTag}class $className extends $extend with ${mixins.join(',')}') :
    (extend != null?
        '${_abstractTag}class $className extends $extend' :
        '${_abstractTag}class $className');
  get _orderedCtors => orderedCtors
    .map((c) => indentBlock(ctors[c].ctorText)).join('\n');
  get _opEquals => opEquals? indentBlock(opEqualsMethod):'';
  get _comparable => comparable? indentBlock(comparableMethod):'';
  get _copyable => copyable? indentBlock(copyMethod):'';
  get _memberPublicCode => members
    .where((m) => m.hasPublicCode)
    .map((m) => indentBlock(chomp(m.publicCode)))
    .join('\n');
  get _topInjection => topInjection!=null? indentBlock(topInjection):'';
  get _includeCustom => includeCustom?
    "\n${rightTrim(indentBlock(customBlock('class $name')))}" : '';

  get _jsonMembers => members
    .where((m) => !m.jsonTransient)
    .map((m) => '"${m.name}": ebisu_utils.toJson(${m.hasGetter? m.name : m.varName}),')
    .join('\n');

  get _jsonExtend =>
    extend!=null? indentBlock('\n"$extend": super.toJson()', '      ') :
    ((mixins.length>0)? '// TODO: consider mixin support' : '');

  get _jsonSerialization => jsonSupport? '''

  Map toJson() {
    return {
${indentBlock(_jsonMembers, '      ')}$_jsonExtend
    };
  }

  static $name fromJson(Object json) {
    if(json == null) return null;
    if(json is String) {
      json = convert.JSON.decode(json);
    }
    assert(json is Map);
    $name result = new $jsonCtor();
    result._fromJsonMapImpl(json);
    return result;
  }

${indentBlock(fromJsonMapImpl())}
''':'';
  get _randJson => hasRandJson? ''' // TODO: randjson support
''':'';

  get _memberPrivateCode => members
    .where((m) => m.hasPrivateCode)
    .map((m) => indentBlock(chomp(m.privateCode)))
    .join('\n');

  get _bottomInjection => bottomInjection != null?
    indentBlock(bottomInjection) : '';

  get _ctorSansNewImpl => ctorSansNew?
    ((ctors.length > 0)?
        publicCtors
        .map((ctor) => ctor.ctorSansNew)
        .join('\n') :
        '${id.camel}() => new ${name}();'
     ) + '\n': '';

  get _classCloser => '}';


  // end <class Class>
  final Id _id;
  dynamic _parent;
  Access _defaultMemberAccess;
  Map<String,Ctor> _ctors = {};
  bool _ctorSansNew;
  String _name;
  String _className;
}
// custom <part class>
// end <part class>
