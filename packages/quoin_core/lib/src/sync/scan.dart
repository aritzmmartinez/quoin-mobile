List<int>? _octets(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return null;
  final octets = <int>[];
  for (final part in parts) {
    final n = int.tryParse(part);
    if (n == null || n < 0 || n > 255 || '$n' != part) return null;
    octets.add(n);
  }
  return octets;
}

bool isPrivateIpv4(String ip) => switch (_octets(ip)) {
      [10, ...] => true,
      [172, final b, ...] => b >= 16 && b <= 31,
      [192, 168, ...] => true,
      _ => false,
    };

List<String> scanCandidates(List<String> phoneIps, String savedHost) {
  final saved = _octets(savedHost);
  if (saved == null) return const [];
  final net = saved.take(3).join('.');
  final own = <int>{
    for (final ip in phoneIps)
      if (isPrivateIpv4(ip))
        if (_octets(ip) case [_, _, _, final last] when ip.startsWith('$net.'))
          last,
  };
  if (own.isEmpty) return const [];
  final start = saved[3];
  return [
    for (var step = 0; step < 256; step++)
      for (final last in step == 0 ? [start] : [start + step, start - step])
        if (last > 0 && last < 255 && !own.contains(last)) '$net.$last',
  ];
}

String? pickByFingerprint(
  List<String> candidates,
  Map<String, String> answers,
  String sha256,
) =>
    candidates.where((host) => answers[host] == sha256).firstOrNull;
