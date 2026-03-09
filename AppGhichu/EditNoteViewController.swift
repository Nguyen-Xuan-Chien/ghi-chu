import UIKit

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
    
    @IBOutlet weak var textView: UITextView!

    var note: Note?

    // 🔥 callback gửi dữ liệu về màn trước
    var onSave: ((Note) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fillData()
    }

    private func setupUI() {
        mapContainerView.layer.cornerRadius = 12
        mapContainerView.clipsToBounds = true
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.minimumScaleFactor = 0.7
        dateLabel.numberOfLines = 1
        
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
    }

    private func fillData() {
        guard let note = note else { return }

        textView.text = note.title
        dateLabel.text = formatDate(note.createdAt)
        locationLabel.text = "Chuyến thăm"
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
       
//            if inputTitle.isEmpty {
//                let tod = timeOfDay(for: Date())
//                //note.title = "Chuyến thăm buổi \(tod) đến Công Ty Luki VN"//
//            } else {
                note.title = inputTitle
//            }
//            
            let now = Date()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            note.dateISO = df.string(from: now)
            note.createdAt = now
            
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
