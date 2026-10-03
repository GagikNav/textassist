---
description: "Rules for TextAssist/Core and TextAssist/Providers — MainActor isolation, provider protocol shape, streaming, and orchestration constraints. Apply when editing capture, orchestration, hotkey, or provider code."
applyTo: ["TextAssist/Core/**", "TextAssist/Providers/**"]
---

# TextAssist core / provider rules

- **`@MainActor` is the default** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`). Cross
  isolation exactly like `OllamaProvider` (`await MainActor.run { … }`); mark pure
  helpers `nonisolated`.
- **Streaming contract** is `AsyncThrowingStream<String, Error>` yielding partial
  deltas. Do not change the `LLMProvider` protocol shape without an issue that says so.
- **`SummarizationOrchestrator.swift` is the shared hot spot.** Tasks `T3.5`, `T4.4`,
  `T6.1`, `T6.2` touch it and must run **one at a time**, in order.
- Sandbox stays off (AX capture + `CGEvent` posting depend on it).
- Keep `///` doc comments on new public types and methods.
