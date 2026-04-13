import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/constants.dart';
import '../models/enums.dart';
import '../data/json_loader.dart';
import '../providers/player_provider.dart';
import '../services/name_generator.dart';

class HeroSelectScreen extends ConsumerStatefulWidget {
  const HeroSelectScreen({super.key});

  @override
  ConsumerState<HeroSelectScreen> createState() => _HeroSelectScreenState();
}

class _HeroSelectScreenState extends ConsumerState<HeroSelectScreen> {
  final _pageController = PageController(viewportFraction: 0.85);
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Varsayilan random isim
    _nameController.text = NameGenerator.generate();
  }

  static const _heroClasses = HeroClass.values;

  static const _classColors = {
    HeroClass.kalkanEr: Color(0xFF1565C0),
    HeroClass.kurtBoru: Color(0xFFC62828),
    HeroClass.kam: Color(0xFF6A1B9A),
    HeroClass.yayCi: Color(0xFF2E7D32),
    HeroClass.golgeBek: Color(0xFF4A148C),
  };

  static const _classIcons = {
    HeroClass.kalkanEr: Icons.shield,
    HeroClass.kurtBoru: Icons.pets,
    HeroClass.kam: Icons.auto_fix_high,
    HeroClass.yayCi: Icons.gps_fixed,
    HeroClass.golgeBek: Icons.visibility_off,
  };

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _heroName(AppLocalizations l10n, HeroClass cls) => switch (cls) {
        HeroClass.kalkanEr => l10n.heroKalkanEr,
        HeroClass.kurtBoru => l10n.heroKurtBoru,
        HeroClass.kam => l10n.heroKam,
        HeroClass.yayCi => l10n.heroYayCi,
        HeroClass.golgeBek => l10n.heroGolgeBek,
      };

  String _heroRole(AppLocalizations l10n, HeroClass cls) => switch (cls) {
        HeroClass.kalkanEr => l10n.roleKalkanEr,
        HeroClass.kurtBoru => l10n.roleKurtBoru,
        HeroClass.kam => l10n.roleKam,
        HeroClass.yayCi => l10n.roleYayCi,
        HeroClass.golgeBek => l10n.roleGolgeBek,
      };

  String _heroDesc(AppLocalizations l10n, HeroClass cls) => switch (cls) {
        HeroClass.kalkanEr => l10n.descKalkanEr,
        HeroClass.kurtBoru => l10n.descKurtBoru,
        HeroClass.kam => l10n.descKam,
        HeroClass.yayCi => l10n.descYayCi,
        HeroClass.golgeBek => l10n.descGolgeBek,
      };

  String _resourceName(AppLocalizations l10n, HeroClass cls) => switch (cls) {
        HeroClass.kalkanEr => l10n.resourceIrade,
        HeroClass.kurtBoru => l10n.resourceOfke,
        HeroClass.kam => l10n.resourceRuh,
        HeroClass.yayCi => l10n.resourceSoluk,
        HeroClass.golgeBek => l10n.resourceSir,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.chooseHero),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: AppSizes.paddingM),
          // Hero PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _heroClasses.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final cls = _heroClasses[index];
                return _HeroCard(
                  heroClass: cls,
                  color: _classColors[cls]!,
                  icon: _classIcons[cls]!,
                  name: _heroName(l10n, cls),
                  role: _heroRole(l10n, cls),
                  description: _heroDesc(l10n, cls),
                  resource: _resourceName(l10n, cls),
                  stats: _getBaseStats(cls),
                  l10n: l10n,
                  isActive: index == _currentPage,
                );
              },
            ),
          ),
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_heroClasses.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? _classColors[_heroClasses[i]]
                      : AppColors.textDim,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.paddingL),
          // Name input + Start button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.heroName,
                      hintText: l10n.heroNameHint,
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      hintStyle: const TextStyle(color: AppColors.textDim),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.casino, color: AppColors.gold),
                        tooltip: 'Random',
                        onPressed: () {
                          _nameController.text = NameGenerator.generate();
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                        borderSide:
                            const BorderSide(color: AppColors.textDim),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                        borderSide:
                            const BorderSide(color: AppColors.gold, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                        borderSide:
                            const BorderSide(color: AppColors.accent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                        borderSide:
                            const BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.nameRequired;
                      }
                      if (value.trim().length < 3) return l10n.nameTooShort;
                      if (value.trim().length > 12) return l10n.nameTooLong;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  ElevatedButton(
                    onPressed: _onStart,
                    child: Text(l10n.startAdventure),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingXL),
        ],
      ),
    );
  }

  Map<String, double> _getBaseStats(HeroClass cls) {
    final heroId = switch (cls) {
      HeroClass.kalkanEr => 'kalkan_er',
      HeroClass.kurtBoru => 'kurt_boru',
      HeroClass.kam => 'kam',
      HeroClass.yayCi => 'yay_ci',
      HeroClass.golgeBek => 'golge_bek',
    };
    final heroes = JsonLoader.instance.heroes;
    if (heroes.isEmpty) {
      return {'hp': 100, 'atk': 10, 'def': 5, 'spd': 1.0};
    }
    final heroData = heroes.firstWhere(
      (h) => h['id'] == heroId,
      orElse: () => heroes.first,
    );
    final stats = heroData['baseStats'] as Map<String, dynamic>;
    return {
      'hp': (stats['hp'] as num).toDouble(),
      'atk': (stats['atk'] as num).toDouble(),
      'def': (stats['def'] as num).toDouble(),
      'spd': (stats['spd'] as num).toDouble(),
    };
  }

  Future<void> _onStart() async {
    if (!_formKey.currentState!.validate()) return;

    final heroClass = _heroClasses[_currentPage];
    final name = _nameController.text.trim();

    await ref.read(playerProvider.notifier).createNew(heroClass, name);

    if (mounted) {
      context.go('/game');
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.heroClass,
    required this.color,
    required this.icon,
    required this.name,
    required this.role,
    required this.description,
    required this.resource,
    required this.stats,
    required this.l10n,
    required this.isActive,
  });

  final HeroClass heroClass;
  final Color color;
  final IconData icon;
  final String name;
  final String role;
  final String description;
  final String resource;
  final Map<String, double> stats;
  final AppLocalizations l10n;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: AppSizes.paddingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)]
                : null,
          ),
          padding: const EdgeInsets.all(AppSizes.paddingS),
          child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon placeholder
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: AppSizes.paddingS),
              // Name
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              // Role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              // Resource
              Text(
                resource,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.paddingS),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBadge(label: l10n.hp, value: stats['hp']!.toInt().toString()),
                  _StatBadge(label: l10n.atk, value: stats['atk']!.toInt().toString()),
                  _StatBadge(label: l10n.def, value: stats['def']!.toInt().toString()),
                  _StatBadge(label: l10n.spd, value: stats['spd']!.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
