import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/session.dart';
import '../services/app_store.dart';
import 'theme.dart';

const _arWeekdays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const _arMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
String _friendlyDate(DateTime d) => '${_arWeekdays[d.weekday - 1]}، ${d.day} ${_arMonths[d.month - 1]}';

Color _accent(String sessionId) => switch (sessionId) {
  'morning' => C.gold,
  'evening' => C.violet,
  _ => C.mint,
};
IconData _sessionIcon(String sessionId) => switch (sessionId) {
  'morning' => Icons.wb_sunny_outlined,
  'evening' => Icons.wb_twilight_rounded,
  _ => Icons.nightlight_round,
};

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final AppStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _tab = 0;
  String _today = dayId(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.store.reminder.attachNavigation(_openById);
    });
  }

  void _openById(String sessionId) {
    final matches = widget.store.sessions.where((s) => s.id == sessionId);
    if (!mounted || matches.isEmpty) return;
    _open(matches.first);
  }

  @override
  void dispose() {
    widget.store.reminder.detachNavigation();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final day = dayId(DateTime.now());
    if (_today != day) {
      _today = day;
      setState(() {});
    }
    widget.store.refreshReminders();
  }

  void _open(Session session) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SessionPage(store: widget.store, session: session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store, onOpen: _open),
      SessionsListPage(store: widget.store, onOpen: _open),
      JourneyPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];
    return AuroraScaffold(
      bottomNavigationBar: _NavBar(index: _tab, onChange: (next) => setState(() => _tab = next)),
      child: IndexedStack(index: _tab, children: pages),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onChange});
  final int index;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 11, bottom: 18, left: 10, right: 10),
    decoration: BoxDecoration(
      color: C.surface2.withValues(alpha: .98),
      border: const Border(top: BorderSide(color: C.line, width: .65)),
      boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x50000000))],
    ),
    child: Row(
      children: [
        _nav(Icons.home_rounded, 'الرئيسية', 0),
        _nav(Icons.auto_stories_rounded, 'الجلسات', 1),
        _nav(Icons.bar_chart_rounded, 'إنجازاتي', 2),
        _nav(Icons.tune_rounded, 'الإعدادات', 3),
      ],
    ),
  );

  Widget _nav(IconData icon, String label, int id) {
    final active = index == id;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChange(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: active ? C.gold.withValues(alpha: .12) : Colors.transparent,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 22, color: active ? C.gold : C.muted),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? C.gold : C.muted)),
          ]),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store, required this.onOpen});
  final AppStore store;
  final ValueChanged<Session> onOpen;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final progress = store.completedToday() / 3;
    final entryOfDay = store.sessions.first.money[(now.day + now.month) % store.sessions.first.money.length];
    return _PageScroll(children: [
      Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: C.gold.withValues(alpha: .16)),
          child: const Icon(Icons.spa_outlined, color: C.gold, size: 27),
        ),
        const SizedBox(width: 11),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('اِزْدِهَار', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23, letterSpacing: 1.1)),
          Text('مساحة يومية للنمو والطمأنينة', style: TextStyle(color: C.muted, fontSize: 11)),
        ]),
        const Spacer(),
        IconButton(onPressed: () => store.refreshReminders(), icon: const Icon(Icons.notifications_active_outlined, color: C.gold)),
      ]),
      const SizedBox(height: 28),
      Text(_friendlyDate(now), style: const TextStyle(color: C.muted, fontSize: 13)),
      const SizedBox(height: 6),
      const Text('يومٌ جديد، فرصةٌ جديدة\nلتزدهر حياتك ✨', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.48)),
      const SizedBox(height: 22),
      _ProgressHero(value: progress, done: store.completedToday(), streak: store.streak),
      const SizedBox(height: 29),
      const SectionLabel('جلساتك لهذا اليوم'),
      const SizedBox(height: 13),
      ...store.sessions.map((session) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: _SessionCard(
          session: session,
          readCount: store.countRead(session),
          completed: store.isFinished(session.id),
          onTap: () => onOpen(session),
        ),
      )),
      const SizedBox(height: 13),
      const SectionLabel('رسالة اليوم'),
      const SizedBox(height: 13),
      GlassCard(
        borderColor: C.gold.withValues(alpha: .35),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.format_quote_rounded, color: C.gold, size: 30),
          const SizedBox(height: 8),
          Text(entryOfDay, style: const TextStyle(fontSize: 19, height: 1.9, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('توكيد للتأمل، وخطوة عملية لإكمال الطريق.', style: TextStyle(color: C.muted, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 16),
      const Text('التفاؤل يقود الانتباه، والعمل يصنع الأثر. الآيات للتدبر وليست توكيدات أو وِردًا مخصصًا لهذه الأوقات.',
        textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 11, height: 1.8)),
    ]);
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.value, required this.done, required this.streak});
  final double value;
  final int done;
  final int streak;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(29),
      gradient: const LinearGradient(colors: [Color(0xFF2C4150), Color(0xFF1B3141), Color(0xFF233443)], begin: Alignment.topRight, end: Alignment.bottomLeft),
      border: Border.all(color: C.gold.withValues(alpha: .28)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('إنجازك اليوم', style: TextStyle(color: C.gold, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 4),
        Text('$done من 3 جلسات', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.local_fire_department_outlined, color: C.gold, size: 18),
          const SizedBox(width: 5),
          Text('$streak يوم متتابع', style: const TextStyle(color: C.muted, fontSize: 12)),
        ]),
      ])),
      ProgressRing(value: value, size: 94, stroke: 8),
    ]),
  );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.readCount, required this.completed, required this.onTap});
  final Session session;
  final int readCount;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(session.id);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      borderColor: completed ? accent.withValues(alpha: .62) : C.line,
      child: Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: accent.withValues(alpha: .14), borderRadius: BorderRadius.circular(19)),
          child: Icon(_sessionIcon(session.id), color: accent, size: 27)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('جلسة ${session.title}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            if (completed) ...[
              const SizedBox(width: 7),
              Icon(Icons.verified_rounded, color: accent, size: 17),
            ],
          ]),
          Text(session.subtitle, style: const TextStyle(color: C.muted, fontSize: 11)),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
            value: readCount / session.totalEntries,
            minHeight: 5,
            color: accent,
            backgroundColor: C.line,
          )),
          const SizedBox(height: 5),
          Text(completed ? 'اكتملت الجلسة' : '$readCount / ${session.totalEntries} قراءة', style: TextStyle(color: completed ? accent : C.muted, fontSize: 11)),
        ])),
        const SizedBox(width: 8),
        Icon(Icons.arrow_back_ios_new_rounded, color: accent, size: 16),
      ]),
    );
  }
}

class SessionsListPage extends StatelessWidget {
  const SessionsListPage({super.key, required this.store, required this.onOpen});
  final AppStore store;
  final ValueChanged<Session> onOpen;

  @override
  Widget build(BuildContext context) => _PageScroll(children: [
    const _PageHeading(title: 'جلساتك', subtitle: 'ثلاث محطات يومية تمنح يومك معنى'),
    const SizedBox(height: 24),
    for (final session in store.sessions) ...[
      _SessionCard(
        session: session, readCount: store.countRead(session),
        completed: store.isFinished(session.id), onTap: () => onOpen(session),
      ),
      const SizedBox(height: 14),
    ],
    const SizedBox(height: 8),
    GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Icon(Icons.lightbulb_outline, color: C.gold),
      SizedBox(height: 10),
      Text('كيف تقرأ داخل الجلسة؟', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      SizedBox(height: 7),
      Text('اضغط «تمت القراءة» بجانب كل توكيد أو آية، ويمكنك بعدها اعتماد الجلسة كاملة. ستُحفظ القراءات حسب اليوم.',
        style: TextStyle(color: C.muted, height: 1.9, fontSize: 13)),
    ])),
  ]);
}

class JourneyPage extends StatelessWidget {
  const JourneyPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _PageScroll(children: [
      const _PageHeading(title: 'رحلة ازدهارك', subtitle: 'كل يوم تحضر فيه لنفسك هو خطوة تستحق التقدير'),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: _MetricCard(icon: Icons.local_fire_department_rounded, value: '${store.streak}', label: 'أيام متتابعة', color: C.gold)),
        const SizedBox(width: 12),
        Expanded(child: _MetricCard(icon: Icons.workspace_premium_outlined, value: '${store.totalCompleteDays}', label: 'أيام مكتملة', color: C.mint)),
      ]),
      const SizedBox(height: 24),
      const SectionLabel('الأيام السبعة الأخيرة'),
      const SizedBox(height: 13),
      GlassCard(child: Column(children: [
        for (var i = 6; i >= 0; i--) ...[
          Builder(builder: (_) {
            final day = DateTime(now.year, now.month, now.day - i);
            final count = store.sessions.where((s) => store.isFinished(s.id, day)).length;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
              SizedBox(width: 76, child: Text(i == 0 ? 'اليوم' : '${_arWeekdays[day.weekday - 1]} ${day.day}', style: const TextStyle(fontSize: 12, color: C.muted))),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(9), child: LinearProgressIndicator(
                value: count / 3, minHeight: 10, color: count == 3 ? C.mint : C.gold, backgroundColor: C.line,
              ))),
              const SizedBox(width: 15),
              SizedBox(width: 32, child: Text('$count/3', textDirection: TextDirection.ltr, style: TextStyle(color: count == 3 ? C.mint : C.muted, fontSize: 11))),
            ]));
          }),
        ],
      ])),
      const SizedBox(height: 22),
      GlassCard(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('تقدمٌ حقيقي، لا مثالية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        SizedBox(height: 7),
        Text('لا يُقاس النجاح بعدد العبارات وحده. اكتب لنفسك هدفًا واقعيًا، واجعل القراءة وسيلة للتركيز والطمأنينة والعمل.',
          style: TextStyle(color: C.muted, height: 1.9, fontSize: 13)),
      ])),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.value, required this.label, required this.color});
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: color, size: 25),
    const SizedBox(height: 12),
    Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(color: C.muted, fontSize: 12)),
  ]));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});
  final AppStore store;

  Future<void> _chooseTime(BuildContext context, int index) async {
    final mins = store.times[index];
    final result = await showTimePicker(
      context: context, initialTime: TimeOfDay(hour: mins ~/ 60, minute: mins % 60),
      helpText: 'اختر موعد التذكير',
    );
    if (result != null) await store.updateTime(index, result.hour * 60 + result.minute);
  }

  @override
  Widget build(BuildContext context) => _PageScroll(children: [
    const _PageHeading(title: 'تذكيراتك', subtitle: 'المواعيد التي تناسب إيقاع يومك'),
    const SizedBox(height: 22),
    GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: store.remindersOn,
        onChanged: store.setReminders,
        activeTrackColor: C.gold,
        title: const Text('تفعيل التنبيهات', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('موعد الجلسة، ثم إعادة تذكير إذا لم تُكملها', style: TextStyle(color: C.muted, fontSize: 12)),
        secondary: const Icon(Icons.notifications_active_outlined, color: C.gold),
      ),
      const Divider(height: 28),
      for (var i = 0; i < 3; i++) ...[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_sessionIcon(store.sessions[i].id), color: _accent(store.sessions[i].id)),
          title: Text('جلسة ${store.sessions[i].title}', style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
            child: Text(clockString(store.times[i]), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
          ),
          onTap: () => _chooseTime(context, i),
        ),
      ],
    ])),
    const SizedBox(height: 22),
    const SectionLabel('إعادة التذكير عند النسيان'),
    const SizedBox(height: 12),
    GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('أعد تذكيري بعد الموعد بـ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final minutes in [15, 30, 45, 60, 90])
          ChoiceChip(
            label: Text('$minutes دقيقة'),
            selected: store.snoozeMinutes == minutes,
            onSelected: (_) => store.updateSnooze(minutes),
            selectedColor: C.gold,
            backgroundColor: C.surface2,
            labelStyle: TextStyle(color: store.snoozeMinutes == minutes ? C.bg : C.white, fontSize: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: store.snoozeMinutes == minutes ? C.gold : C.line),
          ),
      ]),
      const SizedBox(height: 9),
      const Text('يُلغي التطبيق تذكير الجلسة عند اعتمادك اكتمالها. يجب السماح بالتنبيهات من إعدادات الهاتف.',
        style: TextStyle(color: C.muted, height: 1.9, fontSize: 12)),
    ])),
    const SizedBox(height: 18),
    if (store.notificationError != null) ...[
      Text(store.notificationError!, style: const TextStyle(color: Color(0xFFFFB8AB), fontSize: 12)),
      const SizedBox(height: 10),
    ],
    GoldButton(text: 'حفظ وإعادة جدولة التذكيرات', icon: Icons.check_rounded, onPressed: () async {
      await store.refreshReminders();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث جدول التذكيرات المتاحة.')));
    }),
    const SizedBox(height: 19),
    const Text('تنبيه: التذكيرات محلية على الجهاز، وتُجدَّد للأيام العشرة القادمة عند فتح التطبيق. قد يؤخّر النظام الإشعارات بسبب توفير الطاقة أو الأذونات.',
      style: TextStyle(color: C.muted, fontSize: 11, height: 1.85)),
  ]);
}

class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.store, required this.session});
  final AppStore store;
  final Session session;
  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  bool favoritesOnly = false;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final session = widget.session;
      final store = widget.store;
      final done = store.isFinished(session.id);
      final count = store.countRead(session);
      return AuroraScaffold(
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(18, 13, 18, 23),
          decoration: const BoxDecoration(color: C.bg, border: Border(top: BorderSide(color: C.line))),
          child: SafeArea(top: false, child: GoldButton(
            text: done ? 'تم اعتماد الجلسة • التراجع' : 'أنهيت جلسة ${session.title}',
            icon: done ? Icons.undo_rounded : Icons.check_circle_rounded,
            onPressed: () => store.setFinished(session.id, !done),
          )),
        ),
        child: CustomScrollView(slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            title: Text('جلسة ${session.title}'),
            expandedHeight: 0,
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(17, 12, 17, 40),
            sliver: SliverList.list(children: [
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accent(session.id).withValues(alpha: .24), C.surface], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  border: Border.all(color: _accent(session.id).withValues(alpha: .35)),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(session.subtitle, style: TextStyle(color: _accent(session.id), fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(session.goal, style: const TextStyle(color: C.white, height: 1.75, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('$count من ${session.totalEntries} عنصرًا تمت قراءته اليوم', style: const TextStyle(color: C.muted, fontSize: 12)),
                  ])),
                  const SizedBox(width: 14),
                  ProgressRing(value: store.ratio(session), size: 74, color: _accent(session.id)),
                ]),
              ),
              const SizedBox(height: 19),
              Row(children: [
                const Text('المحتوى', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                const Spacer(),
                FilterChip(
                  label: const Text('المفضلة فقط'),
                  selected: favoritesOnly,
                  onSelected: (value) => setState(() => favoritesOnly = value),
                  selectedColor: C.gold,
                  backgroundColor: C.surface,
                  labelStyle: TextStyle(color: favoritesOnly ? C.bg : C.muted, fontSize: 12),
                  side: const BorderSide(color: C.line),
                ),
              ]),
              const SizedBox(height: 9),
              _ReadingSection(
                key: ValueKey('${session.id}-money'),
                title: 'توكيدات المال والوفرة', icon: Icons.savings_outlined,
                color: C.gold, initiallyExpanded: true,
                items: session.entries.where((e) => e.id.contains(':money:')).toList(),
                store: store, favoritesOnly: favoritesOnly,
              ),
              const SizedBox(height: 12),
              _ReadingSection(
                key: ValueKey('${session.id}-mind'),
                title: 'برمجة العقل الباطن', icon: Icons.psychology_outlined,
                color: C.violet, initiallyExpanded: false,
                items: session.entries.where((e) => e.id.contains(':mind:')).toList(),
                store: store, favoritesOnly: favoritesOnly,
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.fromLTRB(13, 8, 13, 10),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text('الآيات القرآنية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    subtitle: const Text('الرزق • المحبة • التوفيق • علو المكانة', style: TextStyle(color: C.muted, fontSize: 11)),
                    leading: const Icon(Icons.menu_book_outlined, color: C.mint),
                    iconColor: C.mint,
                    collapsedIconColor: C.muted,
                    initiallyExpanded: false,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                        child: Text('هذه الآيات مقتطفات للتدبّر، وليست توكيدات أو وردًا شرعيًا مخصصًا لهذا الوقت.',
                          style: TextStyle(color: C.muted, height: 1.8, fontSize: 11)),
                      ),
                      for (final key in quranHeadings.keys) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Align(alignment: Alignment.centerRight,
                            child: Text(quranHeadings[key]!, style: const TextStyle(color: C.mint, fontSize: 15, fontWeight: FontWeight.w800))),
                        ),
                        for (final item in session.entries.where((e) => e.group == key))
                          if (!favoritesOnly || store.isFavorite(item.id))
                            _ReadEntryTile(entry: item, store: store, accent: C.mint),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text('اضغط «تمت القراءة» بعد قراءة أي عبارة، ثم «أنهيت الجلسة» لإيقاف التذكير اللاحق لهذه الجلسة.',
                style: TextStyle(color: C.muted, fontSize: 12, height: 1.8), textAlign: TextAlign.center),
            ]),
          ),
        ]),
      );
    },
  );
}

class _ReadingSection extends StatelessWidget {
  const _ReadingSection({super.key, required this.title, required this.icon, required this.color,
    required this.items, required this.store, required this.favoritesOnly, required this.initiallyExpanded});
  final String title;
  final IconData icon;
  final Color color;
  final List<TextEntry> items;
  final AppStore store;
  final bool favoritesOnly;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final showing = favoritesOnly ? items.where((e) => store.isFavorite(e.id)).toList() : items;
    final read = items.where((e) => store.isRead(e.id)).length;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: color),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          subtitle: Text('$read من ${items.length} مقروء', style: const TextStyle(color: C.muted, fontSize: 11)),
          iconColor: color,
          collapsedIconColor: C.muted,
          children: showing.isEmpty
            ? [const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد عبارات مفضلة في هذا القسم.', style: TextStyle(color: C.muted)))]
            : showing.map((entry) => _ReadEntryTile(entry: entry, store: store, accent: color)).toList(),
        ),
      ),
    );
  }
}

class _ReadEntryTile extends StatelessWidget {
  const _ReadEntryTile({required this.entry, required this.store, required this.accent});
  final TextEntry entry;
  final AppStore store;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final read = store.isRead(entry.id);
    final favorite = store.isFavorite(entry.id);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      margin: const EdgeInsets.fromLTRB(3, 5, 3, 7),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: read ? accent.withValues(alpha: .10) : C.bg.withValues(alpha: .60),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: read ? accent.withValues(alpha: .36) : C.line.withValues(alpha: .7)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(
            entry.isVerse ? '﴿${entry.text}﴾' : entry.text,
            style: TextStyle(
              fontSize: entry.isVerse ? 17 : 15,
              height: entry.isVerse ? 2.15 : 1.9,
              fontWeight: entry.isVerse ? FontWeight.w700 : FontWeight.w600,
              color: read ? C.white : C.white.withValues(alpha: .95),
            ),
          )),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: favorite ? 'إزالة من المفضلة' : 'أضف للمفضلة',
            icon: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? C.gold : C.muted, size: 20),
            onPressed: () => store.toggleFavorite(entry.id),
          ),
        ]),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: InkWell(
            onTap: () { HapticFeedback.selectionClick(); store.toggleRead(entry.id); },
            borderRadius: BorderRadius.circular(13),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 190),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: read ? accent.withValues(alpha: .19) : C.surface,
                border: Border.all(color: read ? accent : C.line),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(read ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: read ? accent : C.muted, size: 19),
                const SizedBox(width: 9),
                Text(read ? (entry.isVerse ? 'تم التدبّر ✓' : 'تمت القراءة ✓') : (entry.isVerse ? 'تدبّرت الآية' : 'تمت القراءة'),
                  style: TextStyle(fontWeight: FontWeight.w800, color: read ? accent : C.white, fontSize: 12)),
              ]),
            ),
          )),
          const SizedBox(width: 9),
          IconButton(
            tooltip: 'نسخ النص',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: entry.isVerse ? '﴿${entry.text}﴾' : entry.text));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص')));
            },
            icon: const Icon(Icons.copy_outlined, color: C.muted, size: 20),
          ),
        ]),
      ]),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
    const SizedBox(height: 4),
    Text(subtitle, style: const TextStyle(color: C.muted, fontSize: 13)),
  ]);
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 125),
        children: children,
      ),
    ),
  );
}
