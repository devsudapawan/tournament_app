import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../common/providers/providers.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../../../common/widgets/shared_widgets.dart';

final _profileLoadingProvider = StateProvider<bool>((_) => false);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _age     = TextEditingController();
  String? _gender;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ref.read(getProfileUseCaseProvider).call();
    result.fold((_) {}, (data) {
      if (data != null) {
        _name.text = data['name'] ?? '';
        _age.text  = data['age']?.toString() ?? '';
        setState(() => _gender = data['gender']);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(_profileLoadingProvider.notifier).state = true;

    final result = await ref.read(saveProfileUseCaseProvider).call({
      'name':   _name.text.trim(),
      'age':    int.tryParse(_age.text.trim()),
      'gender': _gender?.toLowerCase().replaceAll(' ', '_'),
    });

    ref.read(_profileLoadingProvider.notifier).state = false;
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => context.go(AppRoutes.home),
    );
  }

  @override
  void dispose() {
    _name.dispose(); _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_profileLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text('Skip', style: AppTextStyles.label(
                color: AppColors.muted, size: 13)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set up profile',
                    style: AppTextStyles.display(size: 26)),
                const SizedBox(height: 8),
                Text('This helps organizers identify you',
                    style: AppTextStyles.body(color: AppColors.muted)),
                const SizedBox(height: 36),

                // Avatar placeholder
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bg3,
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_outline,
                            size: 40, color: AppColors.muted),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.yellow,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                AppTextField(
                  label: 'Full name',
                  hint: 'Your name',
                  controller: _name,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Age',
                  hint: '18',
                  controller: _age,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 10 || n > 100) return 'Enter valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const SectionLabel('Gender'),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _genders.map((g) {
                    final isSelected = _gender == g;
                    return GestureDetector(
                      onTap: () => setState(() => _gender = g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.yellow.withOpacity(0.1)
                              : AppColors.bg3,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.yellow
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          g,
                          style: AppTextStyles.body(
                            color: isSelected
                                ? AppColors.yellow
                                : AppColors.grey,
                            size: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),
                AppButton(
                  label: 'Save & Continue',
                  onTap: _save,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
