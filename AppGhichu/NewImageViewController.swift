import UIKit

class NewImageViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    var inputImage: UIImage?
    var dateString: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Đổi sang scaleAspectFill để ảnh lấp đầy khung hình (vừa khít khung)
        imageView.contentMode = .scaleAspectFill
        imageView.image = inputImage
        
        // Hiển thị ngày tháng
        if let dateStr = dateString {
            dateLabel.text = "lúc " + dateStr
        }
        
        // Bo góc cho ảnh (giảm xuống 10 để đồng bộ)
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        
        // Thêm viền mỏng nếu cần để làm nổi bật khối ảnh trên nền tối
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        
        // Add tap gesture to dismiss as well
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissVC))
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismissVC()
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let image = imageView.image else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    @objc func dismissVC() {
        dismiss(animated: true)
    }
}
