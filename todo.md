# Project TODO

- [x] Trace the current PNG invoice export handler through widget rendering, capture, file generation, and sharing.
- [x] Establish the exact render-boundary or data-lifecycle cause of the blank/gray PNG from source evidence.
- [x] Apply only the minimal PNG rendering/capture correction; do not modify PDF, dashboard, or business logic.
- [x] Run static checks and release build, then confirm both GitHub Actions workflows and the APK artifact.
- [ ] Confirm on a physical Android device that the generated and shared PNG visually contains the full invoice before declaring success.
- [ ] Determine whether a connected Android device or usable emulator is available for direct PNG invoice verification.
- [ ] If an Android runtime is available, install the latest release APK and verify the exported PNG visually contains invoice content.
- [x] Locate every `late` or conditionally initialized local that can execute in the active mounted-overlay PNG capture path.
- [x] Fix only the proven uninitialized local/control-flow error while preserving the overlay boundary, frame waits, PNG file flow, and share flow.
- [x] Validate the LateInitializationError repair through CI and deliver a new APK artifact for physical-device testing.
- [x] Trace every async callback, helper, dependency, and platform call reachable from the PNG export action for the exact local `result` error.
- [x] Identify the first exact `result` read before initialization and the reachable branch that leaves it unassigned.
- [ ] Apply only the proven initialization/control-flow fix, then validate CI and provide a new APK for device retest.
- [x] Trace the active PNG capture boundary, its direct child, and the selected-sales data handoff for the gray-image device result.
- [x] Prove why the background paints but the invoice child content does not, without changing the working PNG file/share flow.
- [x] Apply and validate only the smallest render-tree correction that makes complete invoice content paint inside the existing PNG boundary.
