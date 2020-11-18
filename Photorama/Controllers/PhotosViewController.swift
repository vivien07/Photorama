import UIKit

class PhotosViewController: UIViewController {
    
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    private let photoStore: PhotoStore = PhotoStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.addTarget(self, action: #selector(photoTypeChanged), for: .valueChanged)
        photoTypeChanged(segmentedControl)
    }
    
    
    @objc func photoTypeChanged(_ segControl: UISegmentedControl) {
        
        var url: URL!
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            url = FlickrAPI.recentPhotosURL
            break
        case 1:
            url = FlickrAPI.interestingPhotosURL
            break
        default:
            break
        }
        photoStore.fetchPhotos(url: url) { (photosResult) in
            switch photosResult {
            case let .success(photos):
                print("Successfully found \(photos.count) photos.")
                if let firstPhoto = photos.first {
                    self.updateImageView(for: firstPhoto)
                }
            case let .failure(error):
                print("Error fetching interesting photos: \(error)")
            }
        }

 
    }
    
    
    func updateImageView(for photo: Photo) {
        
        photoStore.fetchImage(for: photo) { (imageResult) in
            switch imageResult {
            case let .success(image):
                self.imageView.image = image
            case let .failure(error):
                print("Error downloading image: \(error)")
            }
        }
        
    }
    
    
}

