import UIKit
import PhotosUI
import AVFoundation

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
    @IBOutlet weak var mapContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var emojiButton: UIButton!
    @IBOutlet weak var colorPencilButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    
    private var pickedImageFilename: String?
    private var selectedColorHex: String?
    private var selectedTextColorHex: String?
    private var selectedEmoji: String?
    
    @IBAction func icn1(_ sender: Any) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @IBAction func icn2(_ sender: Any) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            self.showCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.showCamera()
                    }
                }
            }
        case .denied, .restricted:
            let alert = UIAlertController(title: "Quyền truy cập", message: "Vui lòng cấp quyền truy cập máy ảnh trong Cài đặt để sử dụng tính năng này.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
            alert.addAction(UIAlertAction(title: "Cài đặt", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            present(alert, animated: true)
        @unknown default:
            break
        }
    }
    
    private func showCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let alert = UIAlertController(title: "Lỗi", message: "Thiết開 không hỗ trợ máy ảnh hoặc đang chạy trên máy ảo.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @IBAction func removeImageTapped(_ sender: UIButton) {
        mapContainerView.isHidden = true
        mapContainerHeightConstraint.constant = 0
        pickedImageFilename = nil
        closeMapButton.isHidden = true
    }
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var icnStack: UIStackView!

    var note: Note?

    // 🔥 callback gửi dữ liệu về màn trước
    var onSave: ((Note) -> Void)?

    private let titlePlaceholderLabel = UILabel()
    private let bodyPlaceholderLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupEmojiMenu()
        setupColorMenu()
        fillData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTitleRightInsetToAvoidIcons()
    }
    
    private func setupEmojiMenu() {
        guard let button = emojiButton else { return }
        button.addTarget(self, action: #selector(onEmojiButtonTapped), for: .touchUpInside)
    }
    
    @objc private func onEmojiButtonTapped(_ sender: UIButton) {
        let picker = EmojiPickerViewController()
        picker.onEmojiSelected = { [weak self] emoji in
            // Lưu emoji để hiển thị trên thanh tiêu đề màn main
            self?.selectedEmoji = emoji
            
            self?.updatePlaceholderVisibility()
            self?.dismiss(animated: true)
        }
        
        picker.modalPresentationStyle = .popover
        if let pop = picker.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.any]
            pop.delegate = self
        }
        
        present(picker, animated: true)
    }
    
    private func setupColorMenu() {
        guard let button = colorPencilButton else { return }
        button.addTarget(self, action: #selector(onColorPencilButtonTapped), for: .touchUpInside)
    }
    
    @objc private func onColorPencilButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Chọn màu", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Đổi màu nền", style: .default, handler: { _ in
            self.presentColorPicker(forBackground: true, from: sender)
        }))
        
        alert.addAction(UIAlertAction(title: "Đổi màu chữ", style: .default, handler: { _ in
            self.presentColorPicker(forBackground: false, from: sender)
        }))
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        
        if let pop = alert.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func presentColorPicker(forBackground: Bool, from sender: UIButton) {
        let picker = ColorPickerViewController()
        picker.onColorSelected = { [weak self] color in
            if forBackground {
                // Lưu màu nền
                self?.selectedColorHex = color.toHexString()
                self?.contentContainerView?.backgroundColor = color
                self?.titleTextView?.backgroundColor = .clear
                self?.bodyTextView?.backgroundColor = .clear
            } else {
                // Lưu màu chữ
                self?.selectedTextColorHex = color.toHexString()
                self?.titleTextView?.textColor = color
                self?.bodyTextView?.textColor = color
            }
            
            self?.bodyTextView.becomeFirstResponder()
            self?.dismiss(animated: true)
        }
        
        picker.modalPresentationStyle = .popover
        if let pop = picker.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
            pop.permittedArrowDirections = [.any]
            pop.delegate = self
        }
        
        present(picker, animated: true)
    }
    

    private func setupUI() {
        mapImageView.contentMode = .scaleAspectFill
        mapImageView.clipsToBounds = true
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.minimumScaleFactor = 0.7
        dateLabel.numberOfLines = 1
        titleTextView.delegate = self
        bodyTextView.delegate = self   
        bodyTextView.textContainer.lineFragmentPadding = 0
        titleTextView.textContainer.lineFragmentPadding = 0
        
        titlePlaceholderLabel.text = "Tiêu đề"
        titlePlaceholderLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titlePlaceholderLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        titleTextView.addSubview(titlePlaceholderLabel)
        NSLayoutConstraint.activate([
            titlePlaceholderLabel.topAnchor.constraint(equalTo: titleTextView.topAnchor, constant: 8),
            titlePlaceholderLabel.leadingAnchor.constraint(equalTo: titleTextView.leadingAnchor, constant: 0),
            titlePlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: titleTextView.trailingAnchor, constant: -8)
        ])
        
        bodyPlaceholderLabel.text = "Bắt đầu viết"
        bodyPlaceholderLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        bodyPlaceholderLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
        bodyPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyTextView.addSubview(bodyPlaceholderLabel)
        NSLayoutConstraint.activate([
            bodyPlaceholderLabel.topAnchor.constraint(equalTo: bodyTextView.topAnchor, constant: 8),
            bodyPlaceholderLabel.leadingAnchor.constraint(equalTo: bodyTextView.leadingAnchor, constant: 0),
            bodyPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: bodyTextView.trailingAnchor, constant: -8)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        mapImageView.addGestureRecognizer(tapGesture)
        mapImageView.isUserInteractionEnabled = true

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

        titleTextView.text = note.title
        dateLabel.text = formatDate(note.createdAt)
        
        // 🔥 Hiển thị màu sắc đã lưu
        if let hex = note.colorHex, let color = UIColor(hex: hex) {
            selectedColorHex = hex
            contentContainerView.backgroundColor = color
            titleTextView.backgroundColor = .clear
            bodyTextView.backgroundColor = .clear
        }
        
        if let tHex = note.textColorHex, let tColor = UIColor(hex: tHex) {
            selectedTextColorHex = tHex
            titleTextView.textColor = tColor
            bodyTextView.textColor = tColor
        } else {
            titleTextView.textColor = .white
            bodyTextView.textColor = .white
        }
        
        selectedEmoji = note.emoji
        
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
                    closeMapButton.isHidden = false
                } else {
                    mapContainerView.isHidden = true
                    mapContainerHeightConstraint.constant = 0
                    closeMapButton.isHidden = true
                }
            } else {
                mapContainerView.isHidden = true
                mapContainerHeightConstraint.constant = 0
                closeMapButton.isHidden = true
            }
        } else {
            mapContainerView.isHidden = true
            mapContainerHeightConstraint.constant = 0
            closeMapButton.isHidden = true
        }
        let body = note.content.replacingOccurrences(of: #"\[IMAGE:.+?\]\n?"#, with: "", options: .regularExpression)
        bodyTextView.text = body
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
        
            let inputTitle = titleTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
       
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
            note.colorHex = selectedColorHex
            note.textColorHex = selectedTextColorHex
            note.emoji = selectedEmoji
        
            let cleaned = (bodyTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    @objc func imageTapped() {
        guard let image = mapImageView.image else { return }
        
        let vc = NewImageViewController(nibName: "NewImageViewController", bundle: nil)
        vc.modalPresentationStyle = .fullScreen
        vc.inputImage = image
        vc.dateString = dateLabel.text 
        present(vc, animated: true)
    }
}

extension EditNoteViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let first = results.first,
              first.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        
        first.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            guard let img = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.mapImageView.image = img
                self?.mapContainerView.isHidden = false
                self?.mapContainerHeightConstraint.constant = 199
                self?.closeMapButton.isHidden = false
                if let file = self?.saveImageToDocuments(img) {
                    self?.pickedImageFilename = file
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let img = info[.originalImage] as? UIImage {
            self.mapImageView.image = img
            self.mapContainerView.isHidden = false
            self.mapContainerHeightConstraint.constant = 199
            self.closeMapButton.isHidden = false
            if let file = self.saveImageToDocuments(img) {
                self.pickedImageFilename = file
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
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
        updateTitleRightInsetToAvoidIcons()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateTitleRightInsetToAvoidIcons()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    
    private func updateTitleRightInsetToAvoidIcons() {
        guard let tv = titleTextView,
              let stack = icnStack else { return }
        
        let spacing: CGFloat = 8
        let trailingMargin: CGFloat = 16
        let stackWidth = stack.bounds.width > 0 ? stack.bounds.width : 120
        let requiredRightInset = max(16, stackWidth + trailingMargin)
        
        var inset = tv.textContainerInset
        if abs(inset.right - requiredRightInset) > 0.5 {
            inset.right = requiredRightInset
            tv.textContainerInset = inset
        }
    }
    
    private func updatePlaceholderVisibility() {
        let titleEmpty = (self.titleTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyEmpty = (self.bodyTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        titlePlaceholderLabel.isHidden = !titleEmpty
        bodyPlaceholderLabel.isHidden = !bodyEmpty
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension EditNoteViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
