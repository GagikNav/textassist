import SwiftUI
import MarkdownUI

/// The SwiftUI content of the summary popup.
///
/// Displays the streamed Markdown summary, a style switcher, error banner,
/// and toolbar actions for Copy and Regenerate.
struct SummaryPopupView: View {
    @StateObject var viewModel: SummaryPopupViewModel

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            Divider()
            content
            Divider()
            bottomToolbar
        }
        .frame(minWidth: 360, minHeight: 280)
    }

    // MARK: - Top toolbar

    private var topToolbar: some View {
        HStack(spacing: 14) {
            stylePicker

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

    private var stylePicker: some View {
        Picker("Style", selection: Binding(
            get: { viewModel.currentStyle.id },
            set: { newID in
                if let newStyle = viewModel.availableStyles.first(where: { $0.id == newID }) {
                    viewModel.changeStyle(to: newStyle)
                }
            }
        )) {
            ForEach(viewModel.availableStyles, id: \.id) { style in
                Text(style.name)
                    .tag(style.id)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .font(.system(size: 15))
        .frame(maxWidth: 260)
    }

    // MARK: - Content

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(message: errorMessage)
                    }

                    Markdown(viewModel.streamedText.isEmpty ? " " : viewModel.streamedText)
                        .markdownTextStyle(
                            textStyle: {
                                FontFamily(.custom(".AppleSystemUIFont"))
                                FontSize(16)
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    Spacer(minLength: 0)

                    Color.clear
                        .frame(height: 1)
                        .id("scrollBottom")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: viewModel.streamedText) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.errorMessage) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
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
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.linear(duration: 0.1)) {
            proxy.scrollTo("scrollBottom", anchor: .bottom)
        }
    }

    // MARK: - Bottom toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 14) {
            Button {
                viewModel.copyToPasteboard()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .keyboardShortcut("c", modifiers: .command)
            .disabled(viewModel.streamedText.isEmpty || viewModel.errorMessage != nil)

            Button {
                viewModel.regenerate()
            } label: {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(viewModel.isStreaming)

            Spacer()

            statusView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var statusView: some View {
        if let elapsedTime = viewModel.elapsedTime {
            Text(String(format: "%.1f s", elapsedTime))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        } else if viewModel.isStreaming {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Streaming…")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    let captured = CapturedText(
        text: "This is a preview of captured text.",
        sourceAppName: "Preview"
    )
    let viewModel = SummaryPopupViewModel(
        capturedText: captured,
        currentStyle: .bulletPoints,
        availableStyles: SummaryStyle.builtIn
    )
    viewModel.streamedText = "- First point\n- Second point"
    viewModel.isStreaming = false
    viewModel.elapsedTime = 1.2

    return SummaryPopupView(viewModel: viewModel)
        .frame(width: 600, height: 420)
}
#endif
