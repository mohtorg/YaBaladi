// screens/rewards_screen.dart
// واجهة المستخدم للنقاط والمكافآت.
// تعرض الرصيد وكتالوج المكافآت، وعند الاستبدال تنشئ طلبًا فقط.
// خصم النقاط وإصدار الكوبون لا يتمان على الهاتف لتجنب تزوير الرصيد.

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/reward_model.dart';
import '../services/rewards_service.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    final service = RewardsService();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('rewards', lang)),
        backgroundColor: const Color(0xFF1454A3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          StreamBuilder(
            stream: service.watchMyWallet(),
            builder: (context, snapshot) {
              final wallet = snapshot.data;
              return Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.stars)),
                  title: Text(AppStrings.of('points_balance', lang)),
                  subtitle: Text('${wallet?.balance ?? 0} ${AppStrings.of('points', lang)}'),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<Reward>>(
              stream: service.watchActiveRewards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                final rewards = snapshot.data ?? const <Reward>[];
                if (rewards.isEmpty) return Center(child: Text(AppStrings.of('no_rewards', lang)));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.card_giftcard),
                        title: Text(reward.nameFor(lang)),
                        subtitle: Text('${reward.descriptionFor(lang)}\n${reward.pointsCost} ${AppStrings.of('points', lang)}'),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () async {
                            try {
                              await service.requestRedemption(reward);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppStrings.of('redemption_submitted', lang))),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                              }
                            }
                          },
                          child: Text(AppStrings.of('redeem', lang)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
