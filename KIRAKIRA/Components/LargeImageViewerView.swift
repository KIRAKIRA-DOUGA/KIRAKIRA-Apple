import Photos
import SwiftUI
import UIKit

struct LargeImageViewerView: View {
    let imageURL: URL
    let title: String?
    let context: LargeImageViewerContext

    @Environment(\.openURL) private var openURL

    @State private var isSaving = false
    @State private var saveError: LargeImageSaveError?
    @State private var completedAction: LargeImageAction?
    @State private var completionResetTask: Task<Void, Never>?

    init(
        imageURL: URL,
        title: String? = nil,
        context: LargeImageViewerContext
    ) {
        self.imageURL = imageURL
        self.title = title
        self.context = context
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZoomingImageView(imageURL: imageURL, context: context)

                if context.loadedImage == nil {
                    if context.didImageLoadFail {
                        ContentUnavailableView {
                            Label(.imageViewerLoadFailed, systemImage: "photo.badge.exclamationmark")
                        }
                    } else {
                        ProgressView()
                            .controlSize(.regular)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close, action: context.dismiss)
                        .disabled(context.isDismissing)
                }

                if let loadedImage = context.loadedImage {
                    ToolbarItemGroup(placement: .bottomBar) {
                        ShareLink(
                            item: Image(uiImage: loadedImage),
                            preview: SharePreview(
                                title ?? String(localized: .imageViewerImageAccessibility),
                                image: Image(uiImage: loadedImage)
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(Text(.share))
                    }

                    ToolbarSpacer(placement: .bottomBar)

                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            copyToPasteboard(loadedImage)
                        } label: {
                            Image(
                                systemName: completedAction == .copy
                                    ? "checkmark"
                                    : "document.on.document"
                            )
                            .contentTransition(.symbolEffect(.replace))
                        }
                        .accessibilityLabel(Text(.actionCopy))

                        Button {
                            Task { await saveToPhotoLibrary() }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.regular)
                            } else {
                                Image(
                                    systemName: completedAction == .save
                                        ? "checkmark"
                                        : "square.and.arrow.down"
                                )
                                .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .disabled(isSaving)
                        .accessibilityLabel(Text(.imageViewerSaveToPhotos))
                    }
                }
            }
            .toolbar(context.areControlsVisible ? .automatic : .hidden, for: .navigationBar)
            .toolbar(context.areControlsVisible ? .automatic : .hidden, for: .bottomBar)
        }
        .environment(\.colorScheme, .dark)
        .background(Color.black)
        .statusBarHidden(!context.areControlsVisible)
        .persistentSystemOverlays(context.areControlsVisible ? .visible : .hidden)
        .sensoryFeedback(.success, trigger: completedAction) { _, newValue in
            newValue != nil
        }
        .onDisappear {
            completionResetTask?.cancel()
        }
        .alert(
            String(localized: .imageViewerSaveFailed),
            isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )
        ) {
            if saveError == .photoLibraryAccessDenied {
                Button(.imageViewerOpenSettings) {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(settingsURL)
                }
            }
            Button(.actionOk, role: .cancel) { saveError = nil }
        } message: {
            Text(saveError?.localizedDescription ?? String(localized: .imageViewerSaveErrorFallback))
        }
    }

    @MainActor
    private func saveToPhotoLibrary() async {
        guard !isSaving else { return }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard authorization == .authorized || authorization == .limited else {
                throw LargeImageSaveError.photoLibraryAccessDenied
            }

            var request = URLRequest(url: imageURL)
            request.setValue("image/jpeg,image/png,image/heic,image/*;q=0.8", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                !data.isEmpty
            else {
                throw LargeImageSaveError.downloadFailed
            }

            let options = PHAssetResourceCreationOptions()
            options.originalFilename = suggestedFilename(mimeType: httpResponse.mimeType)
            try await PHPhotoLibrary.shared().performChanges {
                let assetRequest = PHAssetCreationRequest.forAsset()
                assetRequest.addResource(with: .photo, data: data, options: options)
            }

            showCompletion(for: .save)
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch let error as LargeImageSaveError {
            saveError = error
        } catch {
            saveError = .underlying(error.localizedDescription)
        }
    }

    private func copyToPasteboard(_ image: UIImage) {
        UIPasteboard.general.image = image
        showCompletion(for: .copy)
    }

    private func showCompletion(for action: LargeImageAction) {
        completionResetTask?.cancel()
        withAnimation {
            completedAction = action
        }

        completionResetTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(1.5))
            } catch {
                return
            }
            guard completedAction == action else { return }
            withAnimation {
                completedAction = nil
            }
            completionResetTask = nil
        }
    }

    private func suggestedFilename(mimeType: String?) -> String {
        let filenameExtension = switch mimeType?.lowercased() {
        case "image/png": "png"
        case "image/heic", "image/heif": "heic"
        case "image/gif": "gif"
        case "image/webp": "webp"
        case "image/avif": "avif"
        default: "jpg"
        }
        return "KIRAKIRA-\(UUID().uuidString).\(filenameExtension)"
    }
}

private enum LargeImageAction {
    case copy
    case save
}

private enum LargeImageSaveError: LocalizedError, Equatable {
    case photoLibraryAccessDenied
    case downloadFailed
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            String(localized: .imageViewerPhotoAccessDenied)
        case .downloadFailed:
            String(localized: .imageViewerDownloadFailed)
        case .underlying(let message):
            message
        }
    }
}

#Preview {
    LargeImageViewerView(
        imageURL: CFImageURLBuilder.url(
            for: "video-cover-1-bgIW1F8TToVkXmH0xY5GoiUWuHWtt0j8-1722614549190"
        )!,
        title: "Sample",
        context: LargeImageViewerContext()
    )
}
