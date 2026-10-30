/// Where the owner is tax resident. Not a territory and not a zone: the
/// régimen común will be one territory spanning two zones (Canarias runs an
/// hour behind). Stored by its [name].
enum Residence { bizkaia }

/// Spanish IRPF territories only (foral and común), not a multi-country
/// abstraction.
enum Territory { bizkaia }

/// The territory whose rules apply, and the zone its calendar is read in.
final class Jurisdiction {
  const Jurisdiction({required this.territory, required this.zone});

  final Territory territory;
  final String zone;
}

Jurisdiction jurisdictionOf(Residence residence) => switch (residence) {
      Residence.bizkaia => const Jurisdiction(
          territory: Territory.bizkaia,
          zone: 'Europe/Madrid',
        ),
    };
