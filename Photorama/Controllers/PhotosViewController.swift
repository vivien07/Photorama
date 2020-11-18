import UIKit

class PhotosViewController: UICollectionViewController {
    
    
    private let photoStore: PhotoStore = PhotoStore()
    private let photoDataSource = PhotoDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = photoDataSource
        photoStore.fetchPhotos { (photosResult) -> Void in
            switch photosResult {
            case let .success(photos):
                print("Successfully found \(photos.count) photos.")
                self.photoDataSource.photos = photos
            case let .failure(error):
                print("Error fetching interesting photos: \(error)")
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
        
    }
    
    
    
    
}

