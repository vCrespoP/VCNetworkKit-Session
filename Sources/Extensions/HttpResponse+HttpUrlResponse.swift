import Foundation
import VCNetworkKit

extension HttpResponse {
    
    init(httpUrlResponse: HTTPURLResponse, url: URL, data: Data?) {
        self.responseCode = httpUrlResponse.statusCode
        self.data = data ?? Data()
        self.url = httpUrlResponse.url ?? url
        self.headerFields = httpUrlResponse.allHeaderFields as? [String: String]
    }
    
}
