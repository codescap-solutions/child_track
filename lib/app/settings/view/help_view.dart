import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'widgets/section_card.dart';
import 'help_detail_view.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = [
      'Location Problems',
      'How do I cancel my subscription',
      'How do I add a new family member',
    ];
    final tiles = [
      'Troubleshooting',
      'Subscription & Billing',
      'Account & Data',
      'How do I use the app',
      'Getting Started',
      'GPS Device',
      'Privacy & Security',
      'The App on a Computer',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Help'),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        children: [
          SectionCard(
            child: Column(
              children: topics
                  .map(
                    (t) => Column(
                      children: [
                        _topicChip(t),
                        if (t != topics.last)
                          const SizedBox(height: AppSizes.spacingS),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            'All Articles',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, index) =>
                _articleTile(context, tiles[index]),
          ),
          const SizedBox(height: AppSizes.spacingL),
          TextButton(onPressed: () {}, child: const Text('Chat With Us')),
        ],
      ),
    );
  }

  Widget _topicChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: AppColors.primaryColor),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(child: Text(label)),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _articleTile(BuildContext context, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HelpDetailView(title: label)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE6F0FF),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primaryColor),
            const Spacer(),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
