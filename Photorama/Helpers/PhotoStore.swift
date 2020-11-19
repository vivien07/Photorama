import UIKit

enum PhotoError: Error {
    case imageCreationError
    case missingImageURL
}

//responsible for initiating the web service requests = fetching a list of interesting photos and downloading the image data for each photo.
class PhotoStore {
    
    private let imageStore = ImageStore()
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    
    private func processPhotosRequest(data: Data?, error: Error?) -> Result<[Photo], Error> {
        
        guard let jsonData = data else {
            return .failure(error!)
        }
        return FlickrAPI.photos(fromJSON: jsonData)
        
    }
    
    private func processImageRequest(data: Data?, error: Error?) -> Result<UIImage, Error> {
        
        guard let imageData = data, let image = UIImage(data: imageData) else {
            // Couldn't create an image
            if data == nil {
                return .failure(error!)
            } else {
                return .failure(PhotoError.imageCreationError)
            }
        }
        return .success(image)
        
    }
    
    
    //create a URLRequest that connects to api.flickr.com and asks for the list of interesting photos.
    func fetchPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        
        let url = FlickrAPI.interestingPhotosURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            let result = self.processPhotosRequest(data: data, error: error)
            if let response = response as? HTTPURLResponse {
                print("Status code: \(response.statusCode)")
                print("Header fields: \(response.allHeaderFields)")
            }
            DispatchQueue.main.async {
                completion(result)  //closure that will be called once the web service request is completed
            }
        }
        task.resume()   //start the web service request
        
    }
    
    
    func fetchImage(for photo: Photo,  completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        //load the images from the cache
        let photoKey = photo.photoID
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        guard let photoURL = photo.remoteURL else {
            completion(.failure(PhotoError.missingImageURL))
            return
        }
        let request = URLRequest(url: photoURL)
        let task = session.dataTask(with: request) { (data, response, error) in
            let result = self.processImageRequest(data: data, error: error)
            //when the image data is downloaded, it will be saved to the filesystem.
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            DispatchQueue.main.async {
                completion(result)
            }
        }
        task.resume()
        
    }
    
    
    
    
    
}
/*
 URLSessionTask communicates with the web service
 URLSessionDataTask retrieves data from the server and returns it as Data in memory.
 URLSessionDownloadTask retrieves data from the server and returns it as a file saved to the filesystem.
 URLSessionUploadTask sends data to the server.
 URLSession specifies properties that are common across all the tasks that it creates.
 */
