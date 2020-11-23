import UIKit
import CoreData


//displays a list of all the tags
class TagsViewController: UITableViewController {
    
    
    var photoStore: PhotoStore!
    var photo: Photo!
    private let tagDataSource = TagDataSource()
    private var selectedIndexPaths = [IndexPath]()
    
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addNewtag(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Add Tag" , message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "tag name"
            textField.autocapitalizationType = .words
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            
            if let tagName = alert.textFields?.first?.text {
                let context = self.photoStore.persistentContainer.viewContext
                let newTag = Tag(context: context)
                newTag.setValue(tagName, forKey: "name")
                do {
                    try context.save()
                } catch {
                    print("Core Data save failed: \(error).")
                }
                self.updateTags()
            }
            
        })
        present(alert, animated: true)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = tagDataSource
        tableView.delegate = self
        
        updateTags()
        
    }
    
    
    private func updateTags() {
        
        photoStore.fetchAllTags { (tagsResult) in
            
            switch tagsResult {
            case let .success(tags):
                self.tagDataSource.tags = tags
                guard let photoTags = self.photo.tags as? Set<Tag> else { return }
                for tag in photoTags {
                    if let index = self.tagDataSource.tags.firstIndex(of: tag) {
                        let indexPath = IndexPath(row: index, section: 0)
                        self.selectedIndexPaths.append(indexPath)
                    }
                }
            case let .failure(error):
                print("Error fetching tags: \(error).")
            }
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
        }
        
    }
    
    
    
    // MARK: - UITableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let tag = tagDataSource.tags[indexPath.row]
        if let index = selectedIndexPaths.firstIndex(of: indexPath) {
            selectedIndexPaths.remove(at: index)
            photo.removeFromTags(tag)
        } else {
            selectedIndexPaths.append(indexPath)
            photo.addToTags(tag)
        }
        do {
            try photoStore.persistentContainer.viewContext.save()
        } catch {
            print("Core Data save failed: \(error).")
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if selectedIndexPaths.firstIndex(of: indexPath) != nil {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
}
