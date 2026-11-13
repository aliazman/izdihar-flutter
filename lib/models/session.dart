class TextEntry {
  const TextEntry({required this.id, required this.text, required this.group, this.isVerse = false});
  final String id;
  final String text;
  final String group;
  final bool isVerse;
}

class Session {
  const Session({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.goal,
    required this.money,
    required this.mind,
    required this.quran,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json['quran'] as Map);
    return Session(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      goal: json['goal'] as String,
      money: List<String>.from(json['money'] as List),
      mind: List<String>.from(json['mind'] as List),
      quran: {
        for (final key in const ['rizq', 'love', 'success', 'status'])
          key: List<String>.from(raw[key] as List),
      },
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String goal;
  final List<String> money;
  final List<String> mind;
  final Map<String, List<String>> quran;

  List<TextEntry> get entries => [
    for (var i = 0; i < money.length; i++)
      TextEntry(id: '$id:money:$i', text: money[i], group: 'المال والوفرة'),
    for (var i = 0; i < mind.length; i++)
      TextEntry(id: '$id:mind:$i', text: mind[i], group: 'برمجة العقل الباطن'),
    for (final group in quran.keys)
      for (var i = 0; i < quran[group]!.length; i++)
        TextEntry(id: '$id:quran:$group:$i', text: quran[group]![i], group: group, isVerse: true),
  ];

  int get totalEntries => entries.length;
}

const quranHeadings = {
  'rizq': 'الرزق',
  'love': 'المحبة',
  'success': 'التوفيق',
  'status': 'علو الجاه والمكانة',
};
