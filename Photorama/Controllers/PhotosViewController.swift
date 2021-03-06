import UIKit

class PhotosViewController: UIViewController {
    
    @IBOutlet var collectionView: UICollectionView!
    private let photoStore: PhotoStore = PhotoStore()
    private let photoDataSource = PhotoDataSource()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
        updateDataSource()
        
        photoStore.fetchPhotos { (photosResult) -> Void in
            self.updateDataSource()
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "showPhoto":
            if let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
                let photo = photoDataSource.photos[selectedIndexPath.row]
                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = photoStore
            }
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
        
    }
    
    
    private func updateDataSource() {
        
        photoStore.fetchAllPhotos { (photosResult) in
            switch photosResult {
            case let .success(photos):
                self.photoDataSource.photos = photos
            case .failure:
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
        
    }
    
    
    
}


//delegate is responsible for handling user interaction with the collection view
extension PhotosViewController: UICollectionViewDelegate {
    
    //called every time a cell is getting displayed onscreen
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photo = photoDataSource.photos[indexPath.row]
        // Download the image data, which could take some time
        photoStore.fetchImage(for: photo) { (result) -> Void in
            // The index path for the photo might have changed between the time the request started and finished, so find the most recent index path
            guard let photoIndex = self.photoDataSource.photos.firstIndex(of: photo),
                  case let .success(image) = result else { return}
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            // When the request finishes, find the current cell for this photo
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                cell.update(displaying: image)
            }
        }
        
    }
    
}
