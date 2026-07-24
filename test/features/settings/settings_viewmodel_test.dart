import 'package:dotnest/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('未保存过配置时使用默认字号缩放', () async {
    final vm = SettingsViewModel();
    await Future<void>.delayed(Duration.zero);

    expect(vm.fontScale, SettingsViewModel.defaultFontScale);
  });

  test('setFontScale 持久化后新建实例可读取到已保存的值', () async {
    final vm = SettingsViewModel();
    await Future<void>.delayed(Duration.zero);
    await vm.setFontScale(1.3);

    final reloaded = SettingsViewModel();
    await Future<void>.delayed(Duration.zero);

    expect(reloaded.fontScale, 1.3);
  });

  test('setFontScale 会将超出范围的值裁剪到 min/max 之间', () async {
    final vm = SettingsViewModel();
    await Future<void>.delayed(Duration.zero);

    await vm.setFontScale(10);
    expect(vm.fontScale, SettingsViewModel.maxFontScale);

    await vm.setFontScale(0);
    expect(vm.fontScale, SettingsViewModel.minFontScale);
  });

  test('resetFontScale 恢复为默认字号缩放', () async {
    final vm = SettingsViewModel();
    await Future<void>.delayed(Duration.zero);
    await vm.setFontScale(1.3);

    await vm.resetFontScale();

    expect(vm.fontScale, SettingsViewModel.defaultFontScale);
  });
}
