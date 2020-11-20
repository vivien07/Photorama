import UIKit
import CoreData

enum PhotoError: Error {
    case imageCreationError
    case missingImageURL
}

//responsible for initiating the web service requests = fetching a list of interesting photos and downloading the image data for each photo.
class PhotoStore {
    
    private let imageStore = ImageStore()
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { (description, error) in
            if let err = error {
                print("Error setting up Core Data (\(err)).")
            }
            print(description)
        }
        return container
    }()
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    
    private func processPhotosRequest(data: Data?, error: Error?) -> Result<[Photo], Error> {
        
        guard let jsonData = data else {
            return .failure(error!)
        }
        let context = persistentContainer.viewContext
        
        switch FlickrAPI.photos(fromJSON: jsonData) {
        case let .success(flickrPhotos):
            let photos = flickrPhotos.map { flickrPhoto -> Photo in
                let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                let predicate = NSPredicate( format: "\(#keyPath(Photo.photoID)) == \(flickrPhoto.photoID)")
                fetchRequest.predicate = predicate
                var fetchedPhotos: [Photo]?
                context.performAndWait {
                    fetchedPhotos = try? fetchRequest.execute()
                }
                if let existingPhoto = fetchedPhotos?.first {
                    return existingPhoto
                }
                var photo: Photo!
                context.performAndWait {
                    photo = Photo(context: context)
                    photo.title = flickrPhoto.title
                    photo.photoID = flickrPhoto.photoID
                    photo.remoteURL = flickrPhoto.remoteURL
                    photo.dateTaken = flickrPhoto.dateTaken
                }
                return photo
            }
            return .success(photos)
        case let .failure(error):
            return .failure(error)
        }
        
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
            var result = self.processPhotosRequest(data: data, error: error)
            //save the changes to the context
            if case .success = result {
                do {
                    try self.persistentContainer.viewContext.save()
                } catch {
                    result = .failure(error)
                }
            }
            DispatchQueue.main.async {
                completion(result)  //closure that will be called once the web service request is completed
            }
        }
        task.resume()   //start the web service request
        
    }
    
    
    func fetchImage(for photo: Photo,  completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        //load the images from the cache
        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo expected to have an ID.")
        }
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
    
    
    func fetchAllPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken), ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
            } catch {
                completion(.failure(error))
            }
        }
        
    }
    
    
    func fetchAllTags(completion: @escaping (Result<[Tag], Error>) -> Void) {
        
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: #keyPath(Tag.name), ascending: true)
        fetchRequest.sortDescriptors = [sortByName]

        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
        
    }
    
    
    
    
}
/*
 URLSessionTask communicates with the web service
 URLSessionDataTask retrieves data from the server and returns it as Data in memory.
 URLSessionDownloadTask retrieves data from the server and returns it as a file saved to the filesystem.
 URLSessionUploadTask sends data to the server.
 URLSession specifies properties that are common across all the tasks that it creates.
 */
