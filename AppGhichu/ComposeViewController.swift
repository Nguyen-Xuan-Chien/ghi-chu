import UIKit
import PhotosUI

class ComposeViewController: UIViewController {
    
    var onNoteSaved: (() -> Void)?
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bton1: UIButton!  
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    private let titlePlaceholderLabel = UILabel()
    private let bodyPlaceholderLabel = UILabel()
    private let assetNames = ["image1", "image2", "image3", "img_icon"]
    private var selectedAssetName: String?
    private var selectedImages: [UIImage] = []
    private var imagesCollectionView: UICollectionView?
    private var gridColumns: Int = 2
    
    @IBOutlet weak var bton2: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDateLabel()
        bton1.addTarget(self, action: #selector(onSystemPhotosTapped), for: .touchUpInside)
        bton2.addTarget(self, action: #selector(onSystemPhotosTapped), for: .touchUpInside)
        setupImagesCollectionView()
//        titleTextView?.textContainer.lineFragmentPadding = 0
//        titleTextView?.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 70)
        deleteButton?.isHidden = true
        setupTextViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTitleRightInsetToAvoidIcons()
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
        
        
        let formatter = ISO8601DateFormatter()
        let dateISO = formatter.string(from: Date())
        
        if !selectedImages.isEmpty {
            let size = previewImageView.bounds.size
            if let collage = gridImage(from: selectedImages, columns: gridColumns, size: size),
               let filename = saveImageToDocuments(collage) {
                body = "[IMAGE:\(filename)]\n" + body
            }
        }

        DatabaseHelper.shared.insertNote(title: title, content: body, dateISO: dateISO)

        

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

extension ComposeViewController: PHPickerViewControllerDelegate {
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
            self.updateTitleRightInsetToAvoidIcons()
        }
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
}

extension ComposeViewController: UITextViewDelegate {
    private func updateTitleRightInsetToAvoidIcons() {
        guard let tv = titleTextView,
              let b1 = bton1,
              let b2 = bton2 else { return }
        let spacing: CGFloat = 8
        let trailingMargin: CGFloat = 16
        let w1 = b1.bounds.width > 0 ? b1.bounds.width : 35
        let w2 = b2.bounds.width > 0 ? b2.bounds.width : 35
        let requiredRightInset = max(16, w1 + spacing + w2 + trailingMargin)
        var inset = tv.textContainerInset
        if abs(inset.right - requiredRightInset) > 0.5 {
            inset.right = requiredRightInset
            tv.textContainerInset = inset
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateTitleRightInsetToAvoidIcons()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateTitleRightInsetToAvoidIcons()
    }
}
