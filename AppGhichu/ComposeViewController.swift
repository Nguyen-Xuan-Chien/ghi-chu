import UIKit
import PhotosUI
import AVFoundation

class ComposeViewController: UIViewController {
    
    var onNoteSaved: (() -> Void)?
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bton1: UIButton!  
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var emojiButton: UIButton!
    @IBOutlet weak var colorPencilButton: UIButton!
    @IBOutlet weak var selectedEmojiLabel: UILabel!
    @IBOutlet weak var titleBarView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    
    private let titleCharCountLabel = UILabel()
    private let bodyCharCountLabel = UILabel()
    private let keyboardToolbar = UIToolbar()
    
    private let titlePlaceholderLabel = UILabel()
    private let bodyPlaceholderLabel = UILabel()
    private let assetNames = ["image1", "image2", "image3", "img_icon"]
    private var selectedAssetName: String?
    private var selectedImages: [UIImage] = []
    private var imagesCollectionView: UICollectionView?
    private var gridColumns: Int = 2
    private var selectedColorHex: String?
    private var selectedTextColorHex: String?
    private var selectedEmoji: String?
    
    @IBOutlet weak var bton2: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDateLabel()
        setupEmojiMenu()
        setupColorMenu()
        setupImagesCollectionView()
        deleteButton?.isHidden = true
        setupTextViews()
        setupCharCountLabels()
        setupKeyboardToolbar()

        bton1.isHidden = true
        bton2.isHidden = true
        emojiButton.isHidden = true
        colorPencilButton.isHidden = true
    }
    
    private func setupCharCountLabels() {
        titleCharCountLabel.font = .systemFont(ofSize: 12)
        titleCharCountLabel.textColor = .lightGray
        titleCharCountLabel.text = "0/50"
        view.addSubview(titleCharCountLabel)
        titleCharCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bodyCharCountLabel.font = .systemFont(ofSize: 12)
        bodyCharCountLabel.textColor = .lightGray
        bodyCharCountLabel.text = "0 ký tự"
        view.addSubview(bodyCharCountLabel)
        bodyCharCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleCharCountLabel.topAnchor.constraint(equalTo: titleTextView.bottomAnchor, constant: 2),
            titleCharCountLabel.trailingAnchor.constraint(equalTo: titleTextView.trailingAnchor, constant: -5),
            
            bodyCharCountLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            bodyCharCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
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
        
        keyboardToolbar.items = [leadingSpace, photoBtn, spaceBetween, cameraBtn, spaceBetween, emojiBtn, spaceBetween, colorBtn, flexSpace, doneBtn, trailingSpace]
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
            
            // Cập nhật UI ngay lập tức trước khi dismiss
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
            
            // Chỉ đóng màn hình chọn màu (picker)
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
            
            // Cập nhật UI ngay lập tức
            self.selectedEmoji = emoji
            self.selectedEmojiLabel.text = emoji
            self.updatePlaceholderVisibility()
            
            // Chỉ đóng duy nhất màn hình chọn emoji (picker)
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
        updateTextViewInsets()
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
                self.deleteButton?.isHidden = false
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
    
    private func setupEmojiMenu() {
        guard let button = emojiButton else { return }
  
        button.menu = nil
        button.showsMenuAsPrimaryAction = false
        button.addTarget(self, action: #selector(onEmojiButtonTapped), for: .touchUpInside)
    }
    
    @objc private func onEmojiButtonTapped(_ sender: UIButton) {
        let picker = EmojiPickerViewController()
        picker.onEmojiSelected = { [weak self] emoji in
            self?.selectedEmoji = emoji
            
            self?.selectedEmojiLabel.text = emoji
            
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
        picker.onColorSelected = { [weak self, weak picker] color in
            guard let self = self else { return }
            
            // Cập nhật UI ngay lập tức
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
            
            // Chỉ đóng màn hình chọn màu (picker)
                picker?.dismiss(animated: true) {
                self.bodyTextView.becomeFirstResponder()
            }
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
        let titleInput = (titleTextView?.text ?? titleTextField.text ?? "")
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

        DatabaseHelper.shared.insertNote(title: title, content: body, dateISO: dateISO, colorHex: selectedColorHex, textColorHex: selectedTextColorHex, emoji: selectedEmoji)

        

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
        self.deleteButton?.isHidden = self.selectedImages.isEmpty
        self.updateTextViewInsets()
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
        deleteButton?.isHidden = true
        previewImageView.isHidden = true
    }
    
    private func setupTextViews() {
        titleTextView?.delegate = self
        bodyTextView?.delegate = self
        titleTextView?.textContainer.lineFragmentPadding = 0
        bodyTextView?.textContainer.lineFragmentPadding = 0
        if let tv = titleTextView {
            titlePlaceholderLabel.text = "Tiêu đề"
            titlePlaceholderLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
            titlePlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
            tv.addSubview(titlePlaceholderLabel)
            NSLayoutConstraint.activate([
                titlePlaceholderLabel.topAnchor.constraint(equalTo: tv.topAnchor, constant: 8),
                titlePlaceholderLabel.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 8),
                titlePlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: tv.trailingAnchor, constant: -8)
            ])
        }
        if let bv = bodyTextView {
            bodyPlaceholderLabel.text = "Bắt đầu viết"
            bodyPlaceholderLabel.textColor = UIColor(white: 1.0, alpha: 0.6)
            bodyPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
            bv.addSubview(bodyPlaceholderLabel)
            NSLayoutConstraint.activate([
                bodyPlaceholderLabel.topAnchor.constraint(equalTo: bv.topAnchor, constant: 8),
                bodyPlaceholderLabel.leadingAnchor.constraint(equalTo: bv.leadingAnchor, constant: 8),
                bodyPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: bv.trailingAnchor, constant: -8)
            ])
        }
        updatePlaceholderVisibility()
    }
    
    private func updatePlaceholderVisibility() {
        let titleEmpty = (titleTextView?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let bodyEmpty = (bodyTextView?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        titlePlaceholderLabel.isHidden = !titleEmpty
        bodyPlaceholderLabel.isHidden = !bodyEmpty
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
    private func updateTextViewInsets() {
        guard let titleTv = titleTextView,
              let bodyTv = bodyTextView,
              let b1 = bton1,
              let b2 = bton2,
              let b3 = emojiButton else { return }
        
        let spacing: CGFloat = 8
        let trailingMargin: CGFloat = 16
        
        let w1 = b1.bounds.width > 0 ? b1.bounds.width : 35
        let w2 = b2.bounds.width > 0 ? b2.bounds.width : 35
        let w3 = b3.bounds.width > 0 ? b3.bounds.width : 35
        
        let totalIconsWidth = w1 + w2 + w3 + (spacing * 2)
        let requiredRightInset = max(16, totalIconsWidth + trailingMargin)
        
        var titleInset = titleTv.textContainerInset
        if abs(titleInset.right - requiredRightInset) > 0.5 {
            titleInset.right = requiredRightInset
            titleTv.textContainerInset = titleInset
        }
        
        var bodyInset = bodyTv.textContainerInset
        if abs(bodyInset.right - requiredRightInset) > 0.5 {
            bodyInset.right = requiredRightInset
            bodyTv.textContainerInset = bodyInset
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateTextViewInsets()
        
        if textView == titleTextView {
            let count = textView.text.count
            titleCharCountLabel.text = "\(count)/50"
            titleCharCountLabel.textColor = count > 50 ? .systemRed : .lightGray
        } else if textView == bodyTextView {
            bodyCharCountLabel.text = "\(textView.text.count) ký tự"
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == titleTextView {
            let currentText = textView.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
            return updatedText.count <= 50 || text.isEmpty // Allow deletion even if over limit
        }
        return true
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateTextViewInsets()
    }
}

extension ComposeViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
