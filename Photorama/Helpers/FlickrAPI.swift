import Foundation



enum EndPoint: String {
    case interestingPhotos = "flickr.interestingness.getList"
    case recentPhotos = "flickr.photos.getRecent"
}


struct FlickrResponse: Codable {
    
    let photosInfo: FlickrPhotosResponse
    
    enum CodingKeys: String, CodingKey {
        case photosInfo = "photos"
    }
    
}

struct FlickrPhotosResponse: Codable {
    
    let photos: [FlickrPhoto]
    
    enum CodingKeys: String, CodingKey {
        case photos = "photo"
    }
    
}


//builds up a URL
struct FlickrAPI {
    
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "a6d819499131071f158fd740860a5a88"
    
    static var interestingPhotosURL: URL {
        return flickrURL(endPoint: .interestingPhotos, parameters: ["extras": "url_z,date_taken"])
    }
    static var recentPhotosURL: URL {
         return flickrURL(endPoint: .recentPhotos, parameters: ["extras": "url_z,date_taken"])
    }


    //method that builds up the Flickr URL for a specific endpoint
    private static func flickrURL(endPoint: EndPoint, parameters: [String:String]?) -> URL {
        
        var components = URLComponents(string: baseURLString)!
        var queryItems = [URLQueryItem]()
        //parameters that are common to all requests
        let baseParams = [
            "method": endPoint.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "api_key": apiKey
        ]
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        //specific parameters
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        
        return components.url!
        
    }
    
    
    static func photos(fromJSON data: Data) -> Result<[FlickrPhoto], Error> {
        
        do { //A successful result status will be tied to the data containing interesting photos
            let decoder = JSONDecoder()
            //custom date decoding strategy for fixing an error
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            let flickrResponse = try decoder.decode(FlickrResponse.self, from: data)
            
            let photos = flickrResponse.photosInfo.photos.filter { $0.remoteURL != nil }
            return .success(photos)
            
        } catch {   //A failure result status will be tied with error information
            return .failure(error)
        }
        
    }
    
    
    
}
