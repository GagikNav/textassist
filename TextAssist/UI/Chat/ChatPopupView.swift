import SwiftUI
import MarkdownUI
import AppKit

/// The SwiftUI content of the chat popup.
///
/// Shows the pinned selection as context, a streaming multi-turn message list,
/// and a plain-return input bar. The `ChatViewModel` owns streaming, so this
/// view only renders state and forwards user actions.
struct ChatPopupView: View {
    @ObservedObject var viewModel: ChatViewModel

    /// Focus state so the input field is active when the panel appears.
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            pinnedContext
            Divider()
            messageList
            Divider()
            inputBar
        }
        .frame(minWidth: 380, minHeight: 320)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "bubble.left.and.bubble.right")

            Text("Chat with Selection")
                .font(.headline)

            Spacer()

            Button {
                viewModel.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("w", modifiers: .command)
            .help("Close (⌘W)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Pinned context

    private var pinnedContext: some View {
        DisclosureGroup(isExpanded: $viewModel.isContextExpanded) {
            ScrollView {
                Text(viewModel.capturedText.text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 140)
        } label: {
            Label(
                "Selected text · \(viewModel.wordCount) words · from \(viewModel.capturedText.sourceAppName)",
                systemImage: "text.quote"
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        starterChips
                    }

                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(message: errorMessage)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: viewModel.messages) { _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var starterChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
            ForEach(ChatViewModel.starterPrompts, id: \.self) { prompt in
                Button(prompt) {
                    viewModel.send(prompt)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        if message.role == .user {
            userBubble(message)
        } else {
            assistantBubble(message)
        }
    }

    private func userBubble(_ message: ChatMessage) -> some View {
        HStack {
            Spacer(minLength: 40)
            Text(message.content)
                .padding(10)
                .background(Color.accentColor.opacity(0.25))
                .cornerRadius(10)
                .textSelection(.enabled)
        }
    }

    private func assistantBubble(_ message: ChatMessage) -> some View {
        let isLastMessage = message.id == viewModel.messages.last?.id

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Markdown(message.content.isEmpty ? "…" : message.content)
                    .markdownTextStyle(textStyle: {
                        FontFamily(.custom(".AppleSystemUIFont"))
                        FontSize(15)
                    })

                if !viewModel.isStreaming || !isLastMessage {
                    copyButton(for: message)
                }

                if isLastMessage, !viewModel.isStreaming {
                    regenerateButton
                }
            }
            Spacer(minLength: 40)
        }
    }

    private func copyButton(for message: ChatMessage) -> some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(message.content, forType: .string)
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help("Copy")
    }

    private var regenerateButton: some View {
        Button {
            viewModel.regenerateLast()
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help("Regenerate")
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .foregroundStyle(.primary)
        .font(.system(size: 15))
        .padding(12)
        .background(Color.red.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask about the selected text…", text: $viewModel.draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit {
                    viewModel.sendDraft()
                }
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            if viewModel.isStreaming {
                Button {
                    viewModel.stop()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(.borderless)
                .help("Stop")
            } else {
                Button {
                    viewModel.sendDraft()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.canSend)
                .help("Send")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#if DEBUG
#Preview {
    let captured = CapturedText(
        text: "This is a preview of the selected text, used to pin context for the chat.",
        sourceAppName: "Preview"
    )
    let provider = OllamaProvider(settings: SettingsStore())
    let seed: [LLMMessage] = [
        LLMMessage(role: .user, content: "What's the main point?"),
        LLMMessage(role: .assistant, content: "The main point is that **context is pinned** for the whole conversation.")
    ]
    let viewModel = ChatViewModel(capturedText: captured, provider: provider, seed: seed)

    return ChatPopupView(viewModel: viewModel)
        .frame(width: 520, height: 560)
}

#Preview("Empty state") {
    let captured = CapturedText(
        text: "This is a preview of the selected text, used to pin context for the chat.",
        sourceAppName: "Preview"
    )
    let provider = OllamaProvider(settings: SettingsStore())
    let viewModel = ChatViewModel(capturedText: captured, provider: provider)

    return ChatPopupView(viewModel: viewModel)
        .frame(width: 520, height: 560)
}
#endif
