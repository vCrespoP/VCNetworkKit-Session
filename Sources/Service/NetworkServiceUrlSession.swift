// swiftlint:disable file_length
import Foundation
import VCNetworkKit

public class NetworkServiceUrlSession {
    
    // MARK: - Properties
    public let baseUrl: URL
    public let session: URLSession
    public let isDebugMode: Bool
    
    // MARK: - Life Cycle
    public required init(baseUrl: URL, session: URLSession, isDebugMode: Bool) {
        self.baseUrl = baseUrl
        self.session = session
        self.isDebugMode = isDebugMode
    }
    
    public convenience init(baseUrl: URL) {
        self.init(
            baseUrl: baseUrl,
            session: URLSession(configuration: .default),
            isDebugMode: false)
    }
    
}

// MARK: - Network Service
extension NetworkServiceUrlSession: NetworkService {
    
    @discardableResult public func request(_ request: Request,
                                           completion: @escaping NetworkCompletionHandler<Data>) -> CancelRequest {
        
        // Calculate the complete Url depending on the type
        let finalUrl = request.fullUrl(baseUrl: baseUrl)
        
        // Print debug information for the request if needed
        if self.isDebugMode {
            Swift.print(request.curlDescription(baseUrl: baseUrl))
        }
        
        // Split the logic between a request and a multipart upload
        switch request.type {
            
        case .request(let parameters, let parametersEncoding):
            return self.request(
                request: request,
                url: finalUrl,
                parameters: parameters,
                parametersEncoding: parametersEncoding,
                completion: completion)
            
        case .uploadMultipartData(let parameters):
            return uploadMultipart(
                request: request,
                url: finalUrl,
                parameters: parameters,
                completion: completion
            )
        }
    }
    
}

// MARK: - Request
private extension NetworkServiceUrlSession {
    
    func request(request: Request,
                 url: URL,
                 parameters: HttpParameters?,
                 parametersEncoding: ParametersEncoding,
                 completion: @escaping NetworkCompletionHandler<Data>) -> CancelRequest {
        
        guard let urlRequest: URLRequest = self.createRequestUrl(
            request: request,
            url: url,
            parameters: parameters,
            parametersEncoding: parametersEncoding
            ) else {
                let error = RequestError.parameterEncoding
                completion(NetworkResponse.encodingError(error))
                return {}
        }
        
        // Create the network call
        let operation = session.dataTask(with: urlRequest) { data, response, error in
            
            self.processResponse(
                request: request,
                url: url,
                data: data,
                response: response,
                error: error,
                completion: completion)
            
        }
        
        // Perform the network call
        operation.resume()
        
        // On cancel action
        return {
            operation.cancel()
        }
        
    }
    
    func createRequestUrl(request: Request,
                          url: URL,
                          parameters: HttpParameters?,
                          parametersEncoding: ParametersEncoding) -> URLRequest? {
        
        // Create the UrlRequest from the given request
        var urlRequest = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData, // TODO: As property if needed
            timeoutInterval: request.timeout
        )
        
        // Process Method
        let urlRequestMethod = request.method.urlRequestMethod
        urlRequest.httpMethod = urlRequestMethod
        
        // Process parameters if they're present
        if let parameters = parameters, parameters.isEmpty == false {
            switch parametersEncoding {
            case .url:
                guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    return nil
                }
                let queryItems: [URLQueryItem] = parameters.map { key, value in
                    return URLQueryItem(name: key, value: "\(value)")
                }
                urlComponents.queryItems = queryItems
                urlRequest.url = urlComponents.url
            case .json:
                let jsonData = try? JSONSerialization.data(
                    withJSONObject: parameters,
                    options: []
                )
                guard let jsonParameters = jsonData else {
                    return nil
                }
                urlRequest.httpBody = jsonParameters
                // Add application/json header
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        
        // Process headers if they're present
        if let headers = request.headers, headers.isEmpty == false {
            headers.forEach { key, value in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return urlRequest
    }
    
}

// MARK: - Multipart Upload
private extension NetworkServiceUrlSession {
    
    func uploadMultipart(request: Request,
                         url: URL,
                         parameters: [[String: MultipartParameter]],
                         completion: @escaping (NetworkResponse<Data>) -> Void) -> NetworkService.CancelRequest {
        
        // Create a boundary
        let boundary = UUID().uuidString
        
        let urlRequest: URLRequest = self.createUploadRequestUrl(
            request: request,
            url: url,
            parameters: parameters,
            boundary: boundary
        )
        
        guard let bodyData: Data = self.createUploadRequestData(
            parameters: parameters,
            boundary: boundary
            ) else {
                let error = RequestError.parameterEncoding
                completion(NetworkResponse.encodingError(error))
                return {}
        }
        
        // Create the network call
        let operation = session.uploadTask(with: urlRequest, from: bodyData, completionHandler: { responseData, response, error in
            
            self.processResponse(
                request: request,
                url: url,
                data: responseData,
                response: response,
                error: error,
                completion: completion
            )

        })
        
        // Perform the network call
        operation.resume()
        
        // On cancel action
        return {
            operation.cancel()
        }
        
    }
    
    func createUploadRequestUrl(request: Request,
                                url: URL,
                                parameters: [[String: MultipartParameter]],
                                boundary: String) -> URLRequest {
        
        // Create the UrlRequest from the given request
        var urlRequest = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData, // TODO: As property if needed
            timeoutInterval: request.timeout
        )
        
        // Process Method
        let urlRequestMethod = request.method.urlRequestMethod
        urlRequest.httpMethod = urlRequestMethod
        
        // Add multipart/form-data header
        let contentTypeheader = [
            "multipart/form-data;",
            "boundary=\(boundary)"
            ].joined(separator: " ")
        urlRequest.setValue(contentTypeheader, forHTTPHeaderField: "Content-Type")
        
        // Process headers if they're present
        if let headers = request.headers, headers.isEmpty == false {
            headers.forEach { key, value in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return urlRequest
    }
    
    func createUploadRequestData(parameters: [[String: MultipartParameter]],
                                 boundary: String) -> Data? {
        
        // Process parameters
        var bodyData = Data()
        
        parameters.forEach { parameter in
            parameter.forEach { (key, value) in
                var bodyString = ""
                // Boundary
                bodyString += [
                    "\r\n",
                    "--\(boundary)",
                    "\r\n"
                    ]
                    .joined(separator: "")
                
                // Name
                bodyString += [
                    "Content-Disposition: form-data;",
                    " ",
                    "name=\"\(key)\";",
                    " ",
                    "filename=\"\(value.fileParameter?.fileName ?? "")\"",
                    "\r\n"
                    ]
                    .joined()
                
                // Mime Type
                bodyString += [
                    "Content-Type: \(value.fileParameter?.mimeType ?? "")",
                    "\r\n\r\n"
                    ].joined()
                   
                // Convert to Data
                bodyData = bodyString.data(using: .utf8)! // FIXME: Throw
                
                // Append binary data
                bodyData.append(value.data)
            }
        }
        
        // End the raw http request data, note that there is 2 extra dash ("-")
        // at the end, this is to indicate the end of the data
        // According to the HTTP 1.1 specification
        // https://tools.ietf.org/html/rfc7230
        bodyData.append([
            "\r\n--",
            "\(boundary)",
            "--\r\n"
            ]
            .joined()
            .data(using: .utf8)!)
        
        return bodyData
    }
    
}

// MARK: - Common
private extension NetworkServiceUrlSession {
    
    // swiftlint:disable:next function_parameter_count
    func processResponse(request: Request,
                         url: URL,
                         data: Data?,
                         response: URLResponse?,
                         error: Error?,
                         completion: @escaping NetworkCompletionHandler<Data>) {
        
        // Make sure it's a valid Http response
        guard let responseHttp = response as? HTTPURLResponse else {
            let error = ResponseError.noHttpResponse
            let networkResponse = NetworkResponse<Data>.networkError(error, nil)
            printIfNeeded(networkResponse)
            completion(networkResponse)
            return
        }
        
        // If there's error, process it
        if let error = error {
            let error = ResponseError.network(error)
            let errorResponse = HttpResponse(
                httpUrlResponse: responseHttp,
                url: url,
                data: data
            )
            let networkResponse = NetworkResponse<Data>.networkError(error, errorResponse)
            printIfNeeded(networkResponse)
            completion(networkResponse)
            return
        }
        
        // Validate http code success
        guard request.successCodes.contains(responseHttp.statusCode) == true else {
            let error = ResponseError.errorStatusCode
            let networkResponse = NetworkResponse<Data>.networkError(error, nil)
            printIfNeeded("Status code: \(responseHttp.statusCode). \(networkResponse)")
            completion(networkResponse)
            return
        }
        
        // If there's no data, just return the http response
        guard let data = data else {
            let successResponse = HttpResponse(
                httpUrlResponse: responseHttp,
                url: url,
                data: nil
            )
            let networkResponse = NetworkResponse<Data>.success(nil, successResponse)
            printIfNeeded(networkResponse)
            completion(networkResponse)
            return
        }
        
        // Everything's correct and we have data
        let successResponse = HttpResponse(
            httpUrlResponse: responseHttp,
            url: url,
            data: data
        )
        let networkResponse = NetworkResponse<Data>.success(data, successResponse)
        printIfNeeded(networkResponse)
        completion(networkResponse)
        return
    }
    
}

private extension NetworkServiceUrlSession {
    
    func printIfNeeded(_ object: Any) {
        if self.isDebugMode {
            Swift.print(object)
        }
    }
    
}
