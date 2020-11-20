import Foundation


class FlickrPhoto: Codable {
    
    //all properties are codable
    let photoID: String
    let title: String
    let remoteURL: URL? //not every photo will have that key
    let dateTaken: Date
    
    
    init(id: String, title: String, remoteURL: URL,  dateTaken: Date) {
        photoID = id
        self.title = title
        self.remoteURL = remoteURL
        self.dateTaken = dateTaken
    }
    
    //CodingKey protocol that maps the preferred property name to the key name in the JSON
    enum CodingKeys: String, CodingKey {
        case title
        case remoteURL = "url_z"
        case photoID = "id"
        case dateTaken = "datetaken"
    }
    
}


extension FlickrPhoto: Equatable {
    
    
    //Two Photos are the same if they have the same photoID
    static func == (lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
        return (lhs.photoID == rhs.photoID)
    }
    
    
  
}
