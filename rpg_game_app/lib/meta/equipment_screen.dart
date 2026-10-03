import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';

/// 装備・職業・連続学習のごほうび
class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  Future<void> _update(
    BuildContext context,
    RpgProgress Function(RpgProgress p) change,
  ) async {
    final repo = RpgServices.of(context).repository;
    await repo.save(change(await repo.load()));
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return StreamBuilder<RpgProgress>(
      stream: services.repository.watch(),
      builder: (context, snap) {
        final p = snap.data ?? RpgProgress.initial;
        final owned = Gear.owned(p);
        final equipped = Gear.equipped(p);
        final job = JobDef.parse(p.job);
        final today = RpgServices.today();
        final streak = services.meta.record.streakDays(today);
        final claimable = Gear.claimable(p, services.meta.record, today);
        return Scaffold(
          appBar: AppBar(title: Text('装備・職業', style: serif(18))),
          body: NotebookPaper(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text('連続学習 🔥 $streak 日', style: serif(16)),
                const SizedBox(height: 4),
                Text(
                  '毎日やらなくても大丈夫。続いた日数に応じて、ごほうびがもらえます。',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
                for (final s in StreakReward.all)
                  Card(
                    margin: const EdgeInsets.only(top: 6),
                    child: ListTile(
                      dense: true,
                      leading: Text(
                        '${s.days}日',
                        style: serif(15, color: TsuzuriColors.accent),
                      ),
                      title: Text(s.label),
                      trailing: p.claimedRewards.contains(s.id)
                          ? const Text('受け取りずみ')
                          : claimable.contains(s)
                          ? FilledButton(
                              onPressed: () =>
                                  _update(context, (x) => Gear.claim(x, s)),
                              child: const Text('受け取る'),
                            )
                          : Text('あと${s.days - streak}日'),
                    ),
                  ),
                const SizedBox(height: 18),
                Text('職業：${job.label}', style: serif(16)),
                const SizedBox(height: 4),
                Text(job.description, style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final j in JobDef.values)
                      Tooltip(
                        message: j.description,
                        child: ChoiceChip(
                          label: Text(j.label),
                          selected: j == job,
                          onSelected: (_) =>
                              _update(context, (x) => x.copyWith(job: j.name)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                for (final slot in GearSlot.values) ...[
                  Text(slot.label, style: serif(16)),
                  const SizedBox(height: 4),
                  for (final g in GearDef.all.where((g) => g.slot == slot))
                    Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        enabled: owned.contains(g.id),
                        leading: Icon(
                          equipped.contains(g)
                              ? Icons.check_circle
                              : owned.contains(g.id)
                              ? Icons.circle_outlined
                              : Icons.lock_outline,
                          color: equipped.contains(g)
                              ? TsuzuriColors.correct
                              : TsuzuriColors.inkSoft,
                        ),
                        title: Text(owned.contains(g.id) ? g.name : '？？？'),
                        subtitle: Text(
                          owned.contains(g.id)
                              ? g.description
                              : '入手：${g.howToGet}',
                        ),
                        onTap: owned.contains(g.id)
                            ? () => _update(
                                context,
                                (x) => x.copyWith(
                                  equipped: {
                                    ...x.equipped,
                                    slot.name:
                                        equipped.contains(g) &&
                                            slot == GearSlot.accessory
                                        ? ''
                                        : g.id,
                                  },
                                ),
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
                Text(
                  '装備はレア度をきそうものではなく、学習と結びついた効果をもちます。'
                  '欠片を取りもどした教科の武器は、その教科のバトルで力を発揮します。',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
