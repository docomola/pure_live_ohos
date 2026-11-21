import 'package:media_core/media_core.dart';

import 'av_player_adapter.dart';

/// Creates [AvPlayerAdapter] instances for the HarmonyOS system engine.
final class AvPlayerAdapterFactory implements PlayerAdapterFactory {
  const AvPlayerAdapterFactory({this.capabilities = AvPlayerAdapter.defaultCapabilities, this.priority = 200});

  final PlayerAdapterCapabilities capabilities;

  /// Selection priority. Above the other backends so an OHOS build that keeps
  /// them registered still prefers the engine that actually works there.
  final int priority;

  @override
  PlayerAdapter create(String id) => AvPlayerAdapter(id: id, capabilities: capabilities);

  @override
  bool supports(String id) => id == kAvPlayerBackendId;

  /// Registration entry for `PlayerKernel.registerBackend`.
  PlayerAdapterRegistration registration() =>
      PlayerAdapterRegistration(id: kAvPlayerBackendId, factory: this, capabilities: capabilities, priority: priority);
}
