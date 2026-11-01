import 'dart:io';

const _target = 'packages/quoin_core/test/contract';
const _sourceFile = '$_target/SOURCE';

void main(List<String> args) {
  final check = args.contains('--check');
  final rest = [
    for (final arg in args)
      if (arg != '--check') arg,
  ];
  final quoin = rest.isEmpty ? '../quoin' : rest.single;
  final from = Directory('$quoin/test/contract');
  if (!from.existsSync()) _fail('No contract folder at ${from.path}');

  exit(check ? _check(from) : _sync(quoin, from));
}

int _sync(String quoin, Directory from) {
  final dirty = _git(quoin, ['status', '--porcelain', '--', 'test/contract']);
  if (dirty.isNotEmpty) {
    _fail(
      'test/contract has uncommitted changes in $quoin; SOURCE must name a '
      'commit that holds these exact files:\n$dirty',
    );
  }
  final commit = _git(quoin, ['rev-parse', 'HEAD']);

  final incoming = _contracts(from);
  for (final name in _contracts(Directory(_target)).keys) {
    if (!incoming.containsKey(name)) File('$_target/$name').deleteSync();
  }
  for (final MapEntry(key: name, value: text) in incoming.entries) {
    File('$_target/$name').writeAsStringSync(text);
  }
  File(_sourceFile).writeAsStringSync('$commit\n');
  stdout.writeln('${incoming.length} contracts from $commit');
  return 0;
}

int _check(Directory from) {
  final expected = _contracts(from);
  final actual = _contracts(Directory(_target));
  final problems = [
    for (final name in expected.keys)
      if (!actual.containsKey(name))
        'missing: $name'
      else if (actual[name] != expected[name])
        'differs: $name',
    for (final name in actual.keys)
      if (!expected.containsKey(name)) 'not in Quoin: $name',
  ];
  final commit = File(_sourceFile).existsSync()
      ? File(_sourceFile).readAsStringSync().trim()
      : '(no SOURCE)';
  if (problems.isEmpty) {
    stdout.writeln('${expected.length} contracts match Quoin $commit');
    return 0;
  }
  stderr.writeln('Contracts do not match Quoin $commit:');
  problems.forEach(stderr.writeln);
  stderr.writeln('Run `dart run tool/sync_contracts.dart` against Quoin.');
  return 1;
}

Map<String, String> _contracts(Directory dir) {
  final files = [
    for (final entity in dir.listSync())
      if (entity is File && entity.path.endsWith('.json')) entity,
  ]..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final file in files)
      file.uri.pathSegments.last: file.readAsStringSync().replaceAll(
        '\r\n',
        '\n',
      ),
  };
}

String _git(String repo, List<String> args) {
  final result = Process.runSync('git', ['-C', repo, ...args]);
  if (result.exitCode != 0) _fail('git ${args.join(' ')}: ${result.stderr}');
  return (result.stdout as String).trim();
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
