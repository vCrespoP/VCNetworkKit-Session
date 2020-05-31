@testable import VCNetworkKitSession
import Foundation
import XCTest

private enum Endpoint: String {
    case urlEncoding
    case jsonEncoding
    case decodable
    case uploadMultipart
}

class NetworkServiceUrlSessionTests: BaseTest {
   
    // MARK: - Properties
    
    // MARK: - Life Cycle
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
}

// MARK: - Unit Tests
extension NetworkServiceUrlSessionTests {

    // Ensures the request, with parameters and headers is well constructed
    func test_UrlRequest_And_UrlEncoding_GET() {
     
        // Given
        let method = HttpMethod.get
        let url = RequestUrl.endpoint(Endpoint.urlEncoding.rawValue)
        let parameters: HttpParameters = [
            "parameterString": "ValueString",
            "parameterInt": 11
        ]
        let headers: HttpHeaders = [
            "Accept-Language": "en"
        ]
        let request = Request(
            method: method,
            url: url,
            type: .request(
                parameters: parameters,
                parametersEncoding: .url
            ),
            timeout: 1.0,
            headers: headers,
            successCodes: 200 ..< 300
        )
        
        let responseData: Data? = Data()
        let response: URLResponse = URLResponse()
        let responseError: Error? = nil
        
        let service = NetworkServiceUrlSessionMock().createMockService(
            data: responseData,
            response: response,
            error: responseError
        )
        
        let expectation = XCTestExpectation()
        
        // When
        _ = service.request(request, completion: { (networkResponse: NetworkResponse) in
            guard let session = service.session as? URLSessionMock else {
                XCTFail("No mock session")
                return
            }
            guard let urlRequest = session.urlRequest else {
                XCTFail("No url request")
                return
            }
            
            // Then
            XCTAssertTrue(urlRequest.url!.absoluteString.contains("parameterString=ValueString"))
            XCTAssertTrue(urlRequest.url!.absoluteString.contains("parameterInt=11"))
            XCTAssertEqual(urlRequest.allHTTPHeaderFields, request.headers)
            XCTAssertEqual(urlRequest.httpMethod, "GET")
            XCTAssertNil(urlRequest.httpBody)
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // Ensures the request, with parameters and headers is well constructed
    func test_UrlRequest_And_JsonEncoding_POST() {
     
        // Given
        let method = HttpMethod.post
        let url = RequestUrl.endpoint(Endpoint.jsonEncoding.rawValue)
        let parameters: HttpParameters = [
            "parameterString": "ValueString",
            "parameterInt": 11
        ]
        let headers: HttpHeaders = [
            "Accept-Language": "en"
        ]
        let request = Request(
            method: method,
            url: url,
            type: .request(
                parameters: parameters,
                parametersEncoding: .json
            ),
            timeout: 1.0,
            headers: headers,
            successCodes: 200 ..< 300
        )
        
        let responseData: Data? = Data()
        let response: URLResponse = URLResponse()
        let responseError: Error? = nil
        
        let service = NetworkServiceUrlSessionMock().createMockService(
            data: responseData,
            response: response,
            error: responseError
        )
        
        let expectation = XCTestExpectation()
        
        // When
        _ = service.request(request, completion: { (networkResponse: NetworkResponse) in
            guard let session = service.session as? URLSessionMock else {
                XCTFail("No mock session")
                return
            }
            guard let urlRequest = session.urlRequest else {
                XCTFail("No url request")
                return
            }
            
            // Then
            let expectedUrl = "https://test.com/jsonEncoding"
            XCTAssertEqual(urlRequest.url!.absoluteString, expectedUrl)
            let expectedHeaders = request.headers!
                .merging(["Content-Type": "application/json"]) { (key1, key2) -> String in
                return key1
            }
            XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaders)
            XCTAssertEqual(urlRequest.httpMethod, "POST")
            XCTAssertNotNil(urlRequest.httpBody)
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // Ensures the service returns a valid response & parses to a Decodable object
    func test_Response_and_Decodable_POST() {
     
        // Given
        let method = HttpMethod.get
        let url = RequestUrl.endpoint(Endpoint.decodable.rawValue)
        let parameters: HttpParameters = [:]
        let headers: HttpHeaders = [:]
        let request = Request(
            method: method,
            url: url,
            type: .request(
                parameters: parameters,
                parametersEncoding: .json
            ),
            timeout: 1.0,
            headers: headers,
            successCodes: 200 ..< 300
        )
        
        let responseDataString: String =
        """
        {
            "myString": "myStringValue",
            "myInt": 1,
            "myArray": ["1", "2", "3"]
        }
        """
        let responseData: Data? = responseDataString.data(using: .utf8)
        let response: URLResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [:]
        )!
        let responseError: Error? = nil
        
        let service = NetworkServiceUrlSessionMock().createMockService(
            data: responseData,
            response: response,
            error: responseError
        )
        
        let expectation = XCTestExpectation()
        
        // When
        _ = service.requestParsed(
            request,
            completion: { (networkResponse: NetworkResponse<DecodableStruct>)  in
                switch networkResponse {
                case .success(let entity, let response):
                    XCTAssertEqual(entity?.myString, "myStringValue")
                    XCTAssertEqual(entity?.myInt, 1)
                    XCTAssertEqual(entity?.myArray, ["1", "2", "3"])
                    XCTAssertEqual(response.responseCode, 200)
                default:
                    XCTFail("Wrong response")
                    return
                }
                
                expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
}

// MARK: - Multipart upload
extension NetworkServiceUrlSessionTests {
    
    // Ensures the request, with parameters and headers is well constructed
    func test_MultipartUpload() {
     
        // Given
        let method = HttpMethod.post
        let url = RequestUrl.endpoint(Endpoint.uploadMultipart.rawValue)
        let data = "MyTest".data(using: .utf8)!
        
        let parameters: [[String: MultipartParameter]] = [
            [
                "parameterString": MultipartParameter(
                    data: data,
                    fileParameter: MultipartFileParameter(
                        mimeType: "text/plain",
                        fileName: nil
                    )
                )
            ]
        ]
        let headers: HttpHeaders = [
            "Accept-Language": "en"
        ]
        let request = Request(
            method: method,
            url: url,
            type: .uploadMultipartData(
                parameters: parameters
            ),
            timeout: 1.0,
            headers: headers,
            successCodes: 200 ..< 300
        )
        
        let responseData: Data? = Data()
        let response: URLResponse = URLResponse()
        let responseError: Error? = nil
        
        let service = NetworkServiceUrlSessionMock().createMockService(
            data: responseData,
            response: response,
            error: responseError
        )
        
        let expectation = XCTestExpectation()
        
        // When
        _ = service.request(request, completion: { (networkResponse: NetworkResponse) in
            guard let session = service.session as? URLSessionMock else {
                XCTFail("No mock session")
                return
            }
            guard let urlRequest = session.urlRequest else {
                XCTFail("No url request")
                return
            }
            
            // Then
            let expectedUrl = "https://test.com/uploadMultipart"
            XCTAssertEqual(urlRequest.url!.absoluteString, expectedUrl)
            XCTAssertEqual(urlRequest.httpMethod, "POST")
            XCTAssertNil(urlRequest.httpBody)
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
}

private struct DecodableStruct: Codable {
    
    // MARK: - Properties
    var myString: String
    var myInt: Int
    var myArray: [String]
    
}
