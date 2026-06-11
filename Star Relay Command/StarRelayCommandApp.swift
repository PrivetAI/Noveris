import SwiftUI

@main
struct StarRelayCommandApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var settings = AppSettings()
    @Environment(\.scenePhase) private var scenePhase

    @State private var starRelayLinkReady: Bool? = nil
    private let starRelaySourceLink = "https://example.com"
    private let starRelayCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = starRelayLinkReady {
                    if ready {
                        StarRelayWebPanel(urlString: starRelaySourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                            .environmentObject(store)
                            .environmentObject(settings)
                    }
                } else {
                    StarRelayLoadingScreen()
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
        guard let url = URL(string: starRelaySourceLink) else {
            starRelayLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = StarRelayRedirectTracker(checkDomain: starRelayCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    starRelayLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(starRelayCheckDomain) {
                    starRelayLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(starRelayCheckDomain) {
                    starRelayLinkReady = false; return
                }
                if error != nil {
                    starRelayLinkReady = false; return
                }
                starRelayLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if starRelayLinkReady == nil { starRelayLinkReady = false }
        }
    }
}

final class StarRelayRedirectTracker: NSObject, URLSessionTaskDelegate {
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
