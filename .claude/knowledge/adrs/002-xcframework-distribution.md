# ADR-002: XCFramework Distribution

## Status
Accepted

## Context
iOS adapters need to support multiple architectures: arm64 for devices, x86_64/arm64 for simulators. Apple's transition to Apple Silicon means simulator builds also need arm64. Traditional fat/universal frameworks cannot contain two arm64 slices (device + simulator).

## Decision
Adapters are built as xcframeworks using build scripts that:
1. Build the adapter for device (arm64) using `xcodebuild archive`
2. Build for simulator (x86_64, arm64) using `xcodebuild archive`
3. Combine using `xcodebuild -create-xcframework`
4. Output the final `.xcframework` bundle

Build scripts clean previous artifacts before rebuilding to ensure clean state.

## Consequences
- Full support for both Intel and Apple Silicon Macs (simulator)
- xcframework is Apple's recommended multi-architecture format
- Build scripts must be maintained alongside source code
- Larger distribution size compared to source-only distribution
- Enables binary distribution for partners who cannot compile from source
- Compatible with both CocoaPods and manual integration
