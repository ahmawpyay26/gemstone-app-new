# Project TODO

- [x] Trace the current PNG invoice export handler through widget rendering, capture, file generation, and sharing.
- [x] Establish the exact render-boundary or data-lifecycle cause of the blank/gray PNG from source evidence.
- [x] Apply only the minimal PNG rendering/capture correction; do not modify PDF, dashboard, or business logic.
- [x] Run static checks and release build, then confirm both GitHub Actions workflows and the APK artifact.
- [ ] Confirm on a physical Android device that the generated and shared PNG visually contains the full invoice before declaring success.
- [x] Trace the active PNG capture boundary, its direct child, and the selected-sales data handoff for the gray-image device result.
- [x] Prove why the background paints but the invoice child content does not, without changing the working PNG file/share flow.
- [ ] Apply and validate only the smallest render-tree correction that makes complete invoice content paint inside the existing PNG boundary.
