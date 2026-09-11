import 'package:flutter/material.dart';

import 'scys_api_client.dart';

enum NativeProfileStatus { signedOut, loading, ready, error }

class NativeProfileState {
  const NativeProfileState._({
    required this.status,
    this.profile,
    this.message,
  });

  const NativeProfileState.signedOut()
    : this._(status: NativeProfileStatus.signedOut);

  const NativeProfileState.loading()
    : this._(status: NativeProfileStatus.loading);

  const NativeProfileState.ready(ScysUserProfile profile)
    : this._(status: NativeProfileStatus.ready, profile: profile);

  const NativeProfileState.error(String message)
    : this._(status: NativeProfileStatus.error, message: message);

  final NativeProfileStatus status;
  final ScysUserProfile? profile;
  final String? message;
}

typedef NativeProfileLoader = Future<ScysUserProfile> Function();

class NativeProfileController extends ChangeNotifier {
  NativeProfileController(this._loader);

  final NativeProfileLoader _loader;
  NativeProfileState _state = const NativeProfileState.signedOut();

  NativeProfileState get state => _state;

  Future<void> refresh() async {
    _setState(const NativeProfileState.loading());
    try {
      _setState(NativeProfileState.ready(await _loader()));
    } on ScysAuthenticationRequired {
      _setState(const NativeProfileState.signedOut());
    } on ScysApiException catch (error) {
      _setState(NativeProfileState.error(error.message));
    } catch (_) {
      _setState(const NativeProfileState.error('暂时无法读取个人资料，请稍后重试'));
    }
  }

  void _setState(NativeProfileState value) {
    _state = value;
    notifyListeners();
  }
}

class NativeProfileView extends StatelessWidget {
  const NativeProfileView({
    super.key,
    required this.state,
    required this.onLogin,
    required this.onRefresh,
  });

  final NativeProfileState state;
  final VoidCallback onLogin;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F5EF),
      child: SafeArea(
        bottom: false,
        child: switch (state.status) {
          NativeProfileStatus.signedOut => _SignedOut(onLogin: onLogin),
          NativeProfileStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          NativeProfileStatus.ready => _ProfileContent(
            profile: state.profile!,
            onRefresh: onRefresh,
          ),
          NativeProfileStatus.error => _ProfileError(
            message: state.message ?? '暂时无法读取个人资料',
            onRefresh: onRefresh,
          ),
        },
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 68,
              color: Color(0xFF00897B),
            ),
            const SizedBox(height: 20),
            Text('登录后查看原生个人页', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              '登录仍在官网安全完成，成功后 App 会自动同步登录状态。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('前往网页登录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRefresh});

  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onRefresh});

  final ScysUserProfile profile;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          Row(
            children: [
              _ProfileAvatar(profile: profile),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (profile.memberNumber > 0)
                      Text('生财号 ${profile.memberNumber}'),
                  ],
                ),
              ),
              IconButton(
                tooltip: '刷新资料',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (profile.intro.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(profile.intro, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  _Stat(label: '关注', value: profile.followCount),
                  _Stat(label: '粉丝', value: profile.followerCount),
                  _Stat(label: '收藏', value: profile.favoriteCount),
                  _Stat(label: '消息', value: profile.unreadCount),
                ],
              ),
            ),
          ),
          if (profile.expiresAt case final expiresAt?) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: const Color(0xFFE4F4EF),
              child: ListTile(
                leading: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFF00897B),
                ),
                title: const Text('生财有术会员'),
                subtitle: Text('会员有效期：$expiresAt'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final ScysUserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: 72,
        child: Image.network(
          profile.resolvedAvatarUri.toString(),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(
            color: const Color(0xFFE4F4EF),
            child: Center(
              child: Text(
                profile.name.characters.first,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(color: const Color(0xFF00897B)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
