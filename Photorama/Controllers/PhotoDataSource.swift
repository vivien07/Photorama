import UIKit


//To conform to the UICollectionViewDataSource protocol, a type also needs to conform to the NSObjectProtocol.
//The easiest and most common way to conform to this protocol is to subclass from NSObject
class PhotoDataSource: NSObject, UICollectionViewDataSource {
    
    var photos = [Photo]()
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "PhotoCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PhotoCollectionViewCell
        let photo = photos[indexPath.row]
        cell.photoDescription = photo.title
        cell.update(displaying: nil)
        return cell
    }
    
    
}
