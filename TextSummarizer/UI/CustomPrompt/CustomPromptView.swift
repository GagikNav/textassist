import SwiftUI

/// The SwiftUI content of the custom-prompt panel.
///
/// Shows a multi-line plain-text editor where the user can type instructions.
/// The captured text is appended automatically with `{{text}}`, so the user
/// only needs to write the instruction part.
struct CustomPromptView: View {
    /// The instructions typed by the user.
    @State private var promptText: String = ""

    /// Focus state so the text editor is active when the panel appears.
    @FocusState private var isTextEditorFocused: Bool

    /// Called with the trimmed instruction text when the user confirms.
    let onConfirm: (String) -> Void

    /// Called when the user cancels.
    let onCancel: () -> Void

    /// The instruction text with leading/trailing whitespace removed.
    private var trimmedPrompt: String {
        promptText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Prompt")
                .font(.headline)

            Text("Your instructions will be added before the selected text.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $promptText)
                .font(.body)
                .focused($isTextEditorFocused)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Summarize") {
                    onConfirm(trimmedPrompt)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(trimmedPrompt.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 360)
        .onAppear {
            isTextEditorFocused = true
        }
    }
}

#if DEBUG
#Preview {
    CustomPromptView(
        onConfirm: { _ in },
        onCancel: { }
    )
}
#endif
