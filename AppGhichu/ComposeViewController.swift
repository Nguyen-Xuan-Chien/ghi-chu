import UIKit
import PhotosUI
import AVFoundation
import CoreLocation

class ComposeViewController: UIViewController, CLLocationManagerDelegate {
    
    var onNoteSaved: (() -> Void)?
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleBarView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    
    @IBOutlet weak var titleCharCountLabel: UILabel!
    @IBOutlet weak var bodyCharCountLabel: UILabel!
    private let keyboardToolbar = UIToolbar()
    
    @IBOutlet weak var titlePlaceholderLabel: UILabel!
    @IBOutlet weak var bodyPlaceholderLabel: UILabel!
    private let assetNames = ["image1", "image2", "image3", "img_icon"]
    private var selectedAssetName: String?
    private var selectedImages: [UIImage] = []
    private var imagesCollectionView: UICollectionView?
    private var gridColumns: Int = 2
    private var selectedColorHex: String?
    private var selectedTextColorHex: String?
    private var selectedEmoji: String?
    @IBOutlet weak var selectedEmojiLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    private var locationManager: CLLocationManager?
    private var currentLocationName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDateLabel()
        setupImagesCollectionView()
        setupTextViews()
        setupKeyboardToolbar()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
    }
    
    @objc private func onLocationTapped() {
        if let manager = locationManager {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                locationLabel.text = "Không có quyền truy cập vị trí"
            @unknown default:
                break
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            locationLabel.text = "Không có quyền truy cập vị trí"
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                var addressParts: [String] = []
                if let name = placemark.name { addressParts.append(name) }
                if let thoroughfare = placemark.thoroughfare { if !addressParts.contains(thoroughfare) { addressParts.append(thoroughfare) } }
                if let locality = placemark.locality { if !addressParts.contains(locality) { addressParts.append(locality) } }
                
                let address = addressParts.joined(separator: ", ")
                self?.currentLocationName = address
                self?.locationLabel.text = address
                self?.locationLabel.isHidden = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationLabel.text = "Không lấy được vị trí"
    }
    
    private func setupKeyboardToolbar() {
        keyboardToolbar.sizeToFit()
        let photoBtn = UIBarButtonItem(image: UIImage(systemName: "photo.on.rectangle"), style: .plain, target: self, action: #selector(onSystemPhotosTapped))
        let cameraBtn = UIBarButtonItem(image: UIImage(systemName: "camera"), style: .plain, target: self, action: #selector(onCameraTapped))
        let emojiBtn = UIBarButtonItem(image: UIImage(systemName: "face.smiling"), style: .plain, target: self, action: #selector(onEmojiToolbarTapped(_:)))
        let colorBtn = UIBarButtonItem(image: UIImage(systemName: "pencil.tip.crop.circle.badge.plus.fill"), style: .plain, target: self, action: #selector(onColorPencilToolbarTapped(_:)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Xong", style: .done, target: self, action: #selector(dismissKeyboard))
        
        let leadingSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        leadingSpace.width = 8
        let spaceBetween = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceBetween.width = 12
        
        let trailingSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        trailingSpace.width = 40
        
        keyboardToolbar.items = [photoBtn, flexSpace, cameraBtn, flexSpace, emojiBtn, flexSpace, colorBtn, flexSpace, doneBtn]
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
    
    private func setupDateLabel() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, 'ngày' d 'thg' M"
        dateLabel.text = formatter.string(from: Date()).capitalized
    }
    
    private func resized(_ image: UIImage?, to size: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
    
    private func setupImagesCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: previewImageView.topAnchor),
            cv.leadingAnchor.constraint(equalTo: previewImageView.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: previewImageView.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: previewImageView.bottomAnchor)
        ])
        imagesCollectionView = cv
        cv.isHidden = true
        
        previewImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onPreviewImageTapped))
        previewImageView.addGestureRecognizer(tap)
    }
    
    @objc private func onPreviewImageTapped() {
        if !selectedImages.isEmpty {
            let size = previewImageView.bounds.size
            if let collage = gridImage(from: selectedImages, columns: gridColumns, size: size) {
                openNewImageScreen(with: collage)
            }
        } else if let image = previewImageView.image {
            openNewImageScreen(with: image)
        }
    }
    
    private func openNewImageScreen(with image: UIImage) {
        let vc = NewImageViewController(nibName: "NewImageViewController", bundle: nil)
        vc.modalPresentationStyle = .fullScreen
        vc.inputImage = image
        vc.dateString = dateLabel.text
        present(vc, animated: true)
    }
    
    private func gridImage(from images: [UIImage], columns: Int, size: CGSize) -> UIImage? {
        guard !images.isEmpty else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.black.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            let count = images.count
            let cols = max(1, columns)
            let rows = Int(ceil(Double(count) / Double(cols)))
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)
            for i in 0..<count {
                let row = i / cols
                let col = i % cols
                let rect = CGRect(x: CGFloat(col) * cellW + 2,
                                  y: CGFloat(row) * cellH + 2,
                                  width: cellW - 4,
                                  height: cellH - 4)
                images[i].draw(in: rect)
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
    
    @objc private func onPickAssetTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Chọn ảnh có sẵn", message: nil, preferredStyle: .actionSheet)
        assetNames.forEach { name in
            let action = UIAlertAction(title: " ", style: .default) { _ in
                self.previewImageView.image = UIImage(named: name)
                self.selectedAssetName = name
                self.imagesCollectionView?.isHidden = true
                self.previewImageView.isHidden = false
            }
            let thumb = resized(UIImage(named: name), to: CGSize(width: 40, height: 40))?.withRenderingMode(.alwaysOriginal)
            action.setValue(thumb, forKey: "image")
            ac.addAction(action)
        }
        ac.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        if let pop = ac.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }
        present(ac, animated: true)
    }
    
    @objc private func onSystemPhotosTapped(_ sender: UIButton) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 4
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func onCameraTapped(_ sender: UIButton) {
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
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        let titleInput = (titleTextView?.text ?? "")
        let title = titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        var body = (bodyTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        if title.isEmpty && body.isEmpty {
            let alert = UIAlertController(title: "Chưa có nội dung",
                                          message: "Vui lòng nhập ghi chú trước khi lưu.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateISO = formatter.string(from: Date())
        
        if !selectedImages.isEmpty {
            let size = previewImageView.bounds.size
            if let collage = gridImage(from: selectedImages, columns: gridColumns, size: size),
               let filename = saveImageToDocuments(collage) {
                body = "[IMAGE:\(filename)]\n" + body
            }
        }

        DatabaseHelper.shared.insertNote(title: title, content: body, dateISO: dateISO, colorHex: selectedColorHex, textColorHex: selectedTextColorHex, emoji: selectedEmoji, location: currentLocationName)

        

        if let presentingVC = presentingViewController {
            if let newPostVC = presentingVC as? NewPostViewController,
               let mainVC = newPostVC.presentingViewController {
                dismiss(animated: true) {
                    mainVC.dismiss(animated: false)
                }
                return
            }
        }
        dismiss(animated: true)
    }
}

extension ComposeViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard !results.isEmpty else { return }
        selectedImages.removeAll()
        let group = DispatchGroup()
        for result in results.prefix(4) {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let img = object as? UIImage {
                        self.selectedImages.append(img)
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            self.updatePreview()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            self.selectedImages = [image]
            self.updatePreview()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func updatePreview() {
        self.view.layoutIfNeeded()
        let c = self.selectedImages.count
        if c == 4 { self.gridColumns = 2 }
        else if c >= 3 { self.gridColumns = 3 }
        else { self.gridColumns = max(1, c) }
        self.previewImageView.image = nil
        self.imagesCollectionView?.isHidden = false
        self.imagesCollectionView?.reloadData()
        self.previewImageView.isHidden = false
    }
}

extension ComposeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let iv = UIImageView(image: selectedImages[indexPath.item])
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            iv.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        cell.isUserInteractionEnabled = true
        return cell
    }
    
    @IBAction func removePreviewImage(_ sender: UIButton) {
        previewImageView.image = nil
        selectedImages.removeAll()
        imagesCollectionView?.isHidden = true
        previewImageView.isHidden = true
    }
    
    private func setupTextViews() {
        titleTextView.delegate = self
        bodyTextView.delegate = self
        titleTextView.textContainer.lineFragmentPadding = 0
        bodyTextView.textContainer.lineFragmentPadding = 0
        
        updatePlaceholderVisibility()
    }
    
    private func updatePlaceholderVisibility() {
        titlePlaceholderLabel.isHidden = !titleTextView.text.isEmpty
        bodyPlaceholderLabel.isHidden = !bodyTextView.text.isEmpty
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let insets = layout.sectionInset
        let spacing = layout.minimumInteritemSpacing
        let width = collectionView.bounds.width - insets.left - insets.right
        let totalSpacing = spacing * CGFloat(max(0, gridColumns - 1))
        let w = (width - totalSpacing)
        let itemW = floor(w / CGFloat(gridColumns))
        return CGSize(width: itemW, height: itemW)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onPreviewImageTapped()
    }
}

extension ComposeViewController: UITextViewDelegate {
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
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
}

extension ComposeViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
