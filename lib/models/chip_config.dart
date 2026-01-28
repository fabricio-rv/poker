class ChipConfig {
  final int whiteChips; // Value: 1
  final int redChips; // Value: 5
  final int greenChips; // Value: 10
  final int blueChips; // Value: 25
  final int blackChips; // Value: 50

  const ChipConfig({
    this.whiteChips = 0,
    this.redChips = 0,
    this.greenChips = 0,
    this.blueChips = 0,
    this.blackChips = 0,
  });

  /// Calculate total number of physical chips
  int get totalChips {
    return whiteChips + redChips + greenChips + blueChips + blackChips;
  }

  /// Calculate total chip value
  int get totalValue {
    return (whiteChips * 1) +
        (redChips * 5) +
        (greenChips * 10) +
        (blueChips * 25) +
        (blackChips * 50);
  }

  ChipConfig copyWith({
    int? whiteChips,
    int? redChips,
    int? greenChips,
    int? blueChips,
    int? blackChips,
  }) {
    return ChipConfig(
      whiteChips: whiteChips ?? this.whiteChips,
      redChips: redChips ?? this.redChips,
      greenChips: greenChips ?? this.greenChips,
      blueChips: blueChips ?? this.blueChips,
      blackChips: blackChips ?? this.blackChips,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'whiteChips': whiteChips,
      'redChips': redChips,
      'greenChips': greenChips,
      'blueChips': blueChips,
      'blackChips': blackChips,
    };
  }

  factory ChipConfig.fromJson(Map<String, dynamic> json) {
    return ChipConfig(
      whiteChips: json['whiteChips'] as int? ?? 0,
      redChips: json['redChips'] as int? ?? 0,
      greenChips: json['greenChips'] as int? ?? 0,
      blueChips: json['blueChips'] as int? ?? 0,
      blackChips: json['blackChips'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'ChipConfig(W:$whiteChips, R:$redChips, G:$greenChips, B:$blueChips, BK:$blackChips)';
  }

  /// Format chips for display in Portuguese
  String toDisplayString() {
    List<String> parts = [];
    if (whiteChips > 0) parts.add('$whiteChips Brancas');
    if (redChips > 0) parts.add('$redChips Vermelhas');
    if (greenChips > 0) parts.add('$greenChips Verdes');
    if (blueChips > 0) parts.add('$blueChips Azuis');
    if (blackChips > 0) parts.add('$blackChips Pretas');
    return parts.join(', ');
  }
}
