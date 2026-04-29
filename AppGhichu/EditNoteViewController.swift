import UIKit
import PhotosUI
import AVFoundation
import CoreLocation

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
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    @IBOutlet weak var titleCharCountLabel: UILabel!
    @IBOutlet weak var bodyCharCountLabel: UILabel!
    
    private let keyboardToolbar = UIToolbar()
    
    private var pickedImageFilename: String?
    private var selectedColorHex: String?
    private var selectedTextColorHex: String?
    private var selectedEmoji: String?
    private var currentLocationName: String?
    
    @objc private func icn1() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func icn2() {
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
            let alert = UIAlertController(title: "Lỗi", message: "Thiết bị không hỗ trợ máy ảnh hoặc đang chạy trên máy ảo.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @IBAction func removeImageTapped(_ sender: UIButton) {
        mapContainerView?.isHidden = true
        mapContainerHeightConstraint?.constant = 0
        pickedImageFilename = nil
        closeMapButton?.isHidden = true
    }
    
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var locationLabel: UILabel!

    var note: Note?

    var onSave: ((Note) -> Void)?

    @IBOutlet weak var titlePlaceholderLabel: UILabel!
    @IBOutlet weak var bodyPlaceholderLabel: UILabel!
    @IBOutlet weak var selectedEmojiLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        fillData()
        setupKeyboardToolbar()
    }
    
    @objc private func onLocationTapped() {
        locationLabel.text = "Đang lấy vị trí..."
        locationLabel.isHidden = false
        
        LocationManager.shared.getCurrentLocation { [weak self] address in
            DispatchQueue.main.async {
                if let address = address {
                    self?.currentLocationName = address
                    self?.locationLabel.text = address
                } else {
                    self?.locationLabel.text = "Không lấy được vị trí"
                }
            }
        }
    }
    
    private func setupKeyboardToolbar() {
        keyboardToolbar.sizeToFit()
        let photoBtn = UIBarButtonItem(image: UIImage(systemName: "photo.on.rectangle"), style: .plain, target: self, action: #selector(icn1))
        let cameraBtn = UIBarButtonItem(image: UIImage(systemName: "camera"), style: .plain, target: self, action: #selector(icn2))
        let emojiBtn = UIBarButtonItem(image: UIImage(systemName: "face.smiling"), style: .plain, target: self, action: #selector(onEmojiToolbarTapped(_:)))
        let colorBtn = UIBarButtonItem(image: UIImage(systemName: "pencil.tip.crop.circle.badge.plus.fill"), style: .plain, target: self, action: #selector(onColorPencilToolbarTapped(_:)))
        let locationBtn = UIBarButtonItem(image: UIImage(systemName: "location.fill"), style: .plain, target: self, action: #selector(onLocationTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(dismissKeyboard))
        
        let leadingSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        leadingSpace.width = 8
        let spaceBetween = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceBetween.width = 12
        
        let trailingSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        trailingSpace.width = 40
        
        keyboardToolbar.items = [photoBtn, flexSpace, cameraBtn, flexSpace, emojiBtn, flexSpace, colorBtn, flexSpace, locationBtn, flexSpace, doneBtn]
        keyboardToolbar.tintColor = .systemBlue
        
        titleTextView.inputAccessoryView = keyboardToolbar
        bodyTextView.inputAccessoryView = keyboardToolbar
    }
    
    @objc private func onColorPencilToolbarTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Chọn màu", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Đổi màu nền", style: .default, handler: { _ in
            self.presentColorPickerFromToolbar(forBackground: true, from: sender)
        }))
        
        alert.addAction(UIAlertAction(title: "Đổi màu chữ", style: .default, handler: { _ in
            self.presentColorPickerFromToolbar(forBackground: false, from: sender)
        }))
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        
        if let pop = alert.popoverPresentationController {
            pop.barButtonItem = sender
        }
        
        present(alert, animated: true)
    }

    private func presentColorPickerFromToolbar(forBackground: Bool, from sender: UIBarButtonItem) {
        let picker = ColorPickerViewController()
        picker.onColorSelected = { [weak self, weak picker] color in
            guard let self = self else { return }
            
            if forBackground {
                self.selectedColorHex = color.toHexString()
                self.contentContainerView.backgroundColor = color
                self.titleTextView.backgroundColor = .clear
                self.bodyTextView.backgroundColor = .clear
            } else {
                self.selectedTextColorHex = color.toHexString()
                self.titleTextView.textColor = color
                self.bodyTextView.textColor = color
            }
            
            picker?.dismiss(animated: true) {
                self.bodyTextView.becomeFirstResponder()
            }
        }
        
        picker.modalPresentationStyle = .popover
        if let pop = picker.popoverPresentationController {
            pop.barButtonItem = sender
            pop.permittedArrowDirections = [.any]
            pop.delegate = self
        }
        
        present(picker, animated: true)
    }
    
    @objc private func onEmojiToolbarTapped(_ sender: UIBarButtonItem) {
        let picker = EmojiPickerViewController()
        picker.onEmojiSelected = { [weak self, weak picker] emoji in
            guard let self = self else { return }
            
            self.selectedEmoji = emoji
            self.selectedEmojiLabel.text = emoji
            self.updatePlaceholderVisibility()
            
            picker?.dismiss(animated: true) {
                self.bodyTextView.becomeFirstResponder()
            }
        }
        
        picker.modalPresentationStyle = .popover
        if let pop = picker.popoverPresentationController {
            pop.barButtonItem = sender
            pop.permittedArrowDirections = [.any]
            pop.delegate = self
        }
        
        present(picker, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    

    private func setupUI() {
        allmenu.layer.cornerRadius = 10
        allmenu.clipsToBounds = true
        allmenu.isHidden = false

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
        
        locationLabel.numberOfLines = 0
        locationLabel.lineBreakMode = .byWordWrapping
        
        showCurrentDate()
        
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
        let titleCount = note.title.count
        titleCharCountLabel.text = "\(titleCount)/50"
        titleCharCountLabel.textColor = titleCount >= 50 ? .systemRed : .lightGray
        
        dateLabel.text = formatDate(note.createdAt)
 
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
        selectedEmojiLabel.text = selectedEmoji ?? ""
        
        currentLocationName = note.location
        locationLabel.text = note.location ?? "Chưa có vị trí"
        locationLabel.isHidden = note.location == nil
        
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
        bodyCharCountLabel.text = "\(body.count)"
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
                note.title = "Chuyến thăm buổi \(tod) đến Công Ty Luki VN"
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
            note.location = currentLocationName
        
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
        
        if textView == titleTextView {
            let count = textView.text.count
            titleCharCountLabel.text = "\(count)/50"
            titleCharCountLabel.textColor = count >= 50 ? .systemRed : .lightGray
        } else if textView == bodyTextView {
            let count = textView.text.count
            bodyCharCountLabel.text = "\(count)"
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == titleTextView {
            let currentText = textView.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
            return updatedText.count <= 50 || text.isEmpty
        }
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    
    private func updatePlaceholderVisibility() {
        titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty
        bodyPlaceholderLabel.isHidden = !bodyTextView.text.isEmpty
    }
}

extension EditNoteViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
