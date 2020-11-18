import Foundation


class Photo: Codable {
    
    //all properties are codable
    let title: String
    let remoteURL: URL? //not every photo will have that key
    let photoID: String
    let dateTaken: Date
    
    
    init(title: String, remoteURL: URL, id: String, dateTaken: Date) {
        self.title = title
        self.remoteURL = remoteURL
        photoID = id
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
