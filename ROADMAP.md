# Roadmap

This document tracks the public direction of Godot Shader Studio.

## Current focus

- Complete end-user documentation and practical examples
- Refine editor UX, onboarding, and feedback around validation errors
- Expand the bundled library of reusable subgraphs and example graphs
- Prepare the addon for publication in the Godot Asset Library

## Near-term goals

- Improve import, save, and iteration workflows for larger graphs
- Expand node coverage for common material, VFX, and post-process use cases
- Strengthen preview tooling and shader debugging ergonomics
- Continue hardening compiler and graph serialization behavior

## Release direction

- `1.0.0` should represent the first stable public release
- File formats and public APIs should remain compatible across `1.x` whenever possible
- Breaking changes should be reserved for cases where format or architecture evolution makes them necessary

## Out of scope for now

- Native modules or GDExtension dependencies
- A separate runtime dependency outside the addon itself
- Format churn without a clear migration path
