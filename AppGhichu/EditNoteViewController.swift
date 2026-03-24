import UIKit
import PhotosUI

class EditNoteViewController: UIViewController {

    @IBOutlet weak var allmenu: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    private func showCurrentDate() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "d 'thg' M, yyyy"

        dateLabel.text = formatter.string(from: Date())
    }
    @IBOutlet weak var moreButton: UIButton!

    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    @IBOutlet weak var closeMapButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var mapContainerHeightConstraint: NSLayoutConstraint!
    
    private var pickedImageFilename: String?
    
    @IBAction func icn1(_ sender: Any) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @IBAction func icn2(_ sender: Any) {
    }
    
    @IBAction func removeImageTapped(_ sender: UIButton) {
        mapContainerView.isHidden = true
        mapContainerHeightConstraint.constant = 0
        pickedImageFilename = nil
        closeMapButton.isHidden = true
        locationLabel.isHidden = true
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textView1: UITextView!

    var note: Note?

    // 🔥 callback gửi dữ liệu về màn trước
    var onSave: ((Note) -> Void)?

    private let titlePlaceholderLabel = UILabel()
    private let bodyPlaceholderLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fillData()
    }
    

    private func setupUI() {
        mapContainerView.layer.cornerRadius = 12
        mapContainerView.clipsToBounds = true
        mapImageView.contentMode = .scaleAspectFill
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.minimumScaleFactor = 0.7
        dateLabel.numberOfLines = 1
        textView1.delegate = self   
        textView1.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineFragmentPadding = 0
        
        titlePlaceholderLabel.text = "Tiêu đề"
        titlePlaceholderLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView1.addSubview(titlePlaceholderLabel)
        NSLayoutConstraint.activate([
            titlePlaceholderLabel.topAnchor.constraint(equalTo: textView1.topAnchor, constant: 8),
            titlePlaceholderLabel.leadingAnchor.constraint(equalTo: textView1.leadingAnchor, constant: 8),
            titlePlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView1.trailingAnchor, constant: -8)
        ])
        
        bodyPlaceholderLabel.text = "Bắt đầu viết"
        bodyPlaceholderLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        bodyPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(bodyPlaceholderLabel)
        NSLayoutConstraint.activate([
            bodyPlaceholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            bodyPlaceholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 8),
            bodyPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -8)
        ])
        
        let targetIds = ["50M-Sa-2i3", "aDr-66-hQW"]
        func adjustConstraints(in view: UIView) {
            for c in view.constraints {
                if c.identifier == "50M-Sa-2i3" {
                    c.constant = 4
                }
                if c.identifier == "aDr-66-hQW" {
                    c.constant = 48
                }
            }
            for s in view.subviews {
                adjustConstraints(in: s)
            }
        }
        adjustConstraints(in: self.view)
        updatePlaceholderVisibility()
    }

    private func fillData() {
        guard let note = note else { return }

        textView.text = note.title
        dateLabel.text = formatDate(note.createdAt)
        locationLabel.text = "Chuyến thăm buổi chiều đến Công Ty Luki VN"
        
        if let range = note.content.range(of: #"\[IMAGE:(.+?)\]"#, options: .regularExpression) {
            let marker = String(note.content[range])
            let name = marker
                .replacingOccurrences(of: "[IMAGE:", with: "")
                .replacingOccurrences(of: "]", with: "")
            if let folder = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
                let url = folder.appendingPathComponent(name)
                if let img = UIImage(contentsOfFile: url.path) {
                    mapImageView.image = img
                    pickedImageFilename = name
                    mapContainerView.isHidden = false
                    mapContainerHeightConstraint.constant = 199
                    locationLabel.isHidden = false
                    closeMapButton.isHidden = false
                } else {
                    mapContainerView.isHidden = true
                    mapContainerHeightConstraint.constant = 0
                    locationLabel.isHidden = true
                    closeMapButton.isHidden = true
                }
            } else {
                mapContainerView.isHidden = true
                mapContainerHeightConstraint.constant = 0
                locationLabel.isHidden = true
                closeMapButton.isHidden = true
            }
        } else {
            mapContainerView.isHidden = true
            mapContainerHeightConstraint.constant = 0
            locationLabel.isHidden = true
            closeMapButton.isHidden = true
        }
        let body = note.content.replacingOccurrences(of: #"\[IMAGE:.+?\]\n?"#, with: "", options: .regularExpression)
        textView1.text = body
        updatePlaceholderVisibility()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, 'ngày' d 'thg' M"
        return formatter.string(from: date).capitalized
    }

    @IBAction func doneTapped(_ sender: UIButton) {
 
        guard var note = note else {
            return
        }
        
            let inputTitle = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
       
            if inputTitle.isEmpty {
                let tod = timeOfDay(for: Date())
                note.title = "Chuyến thăm buổi \(tod) đến Công Ty Luki VN"//
            } else {
                note.title = inputTitle
            }
            
            let now = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            note.dateISO = df.string(from: now)
            note.createdAt = now
        
            let cleaned = (textView1.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let fname = pickedImageFilename {
                note.content = "[IMAGE:\(fname)]\n" + cleaned
            } else {
                note.content = cleaned
            }
            
            onSave?(note)
            
            dismiss(animated: true)
        }

    private func timeOfDay(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "sáng"
        case 12..<18: return "chiều"
        default: return "tối"
        }
    }
}

extension EditNoteViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let first = results.first,
              first.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        first.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let img = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.mapImageView.image = img
                self?.mapContainerView.isHidden = false
                self?.mapContainerHeightConstraint.constant = 199
                self?.locationLabel.isHidden = false
                self?.closeMapButton.isHidden = false
                if let file = self?.saveImageToDocuments(img) {
                    self?.pickedImageFilename = file
                }
            }
        }
    }
    
    private func saveImageToDocuments(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let filename = "note_img_\(UUID().uuidString).jpg"
        let folder = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        guard let url = folder?.appendingPathComponent(filename) else { return nil }
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }
}

extension EditNoteViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    
    private func updatePlaceholderVisibility() {
        let titleEmpty = (self.textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyEmpty = (self.textView1.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        titlePlaceholderLabel.isHidden = !titleEmpty
        bodyPlaceholderLabel.isHidden = !bodyEmpty
    }
}
