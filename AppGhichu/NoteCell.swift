import UIKit

class NoteCell: UITableViewCell {
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var lblMonth: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var imgIconHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var lblHeaderDate: UILabel!
    @IBOutlet weak var lblHeaderEmoji: UILabel!
    @IBOutlet weak var locationIconView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    
    var onMoreTapped: (() -> Void)?
    
    private var mapTintView: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 15
        cardView.clipsToBounds = true
        
        locationLabel.numberOfLines = 0
        locationLabel.lineBreakMode = .byWordWrapping
    }
    
    @IBAction func handleMoreTap() {
        onMoreTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onMoreTapped = nil
    }
    
    func configure(note: Note, defaultThemeColor: UIColor? = nil, showDateHeader: Bool = true) {
        let rawTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawTitle.isEmpty {
            lblTitle.text = "Tiêu đề"
        } else {
            lblTitle.text = rawTitle
        }
        
        let cleanedContent = note.content.replacingOccurrences(of: #"\[IMAGE:.+?\]\n?"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        lblContent.text = cleanedContent.isEmpty ? "Bắt đầu viết" : cleanedContent
        
        lblTitle.numberOfLines = 0
        lblContent.numberOfLines = 0
        
        lblHeaderDate.isHidden = !showDateHeader
        lblHeaderEmoji.isHidden = !showDateHeader
        lblHeaderDate.text = note.displayDate
        lblHeaderEmoji.text = note.emoji ?? ""
        
        // Cập nhật constraint cho cardView nếu ẩn header
        for constraint in contentView.constraints {
            if constraint.firstAttribute == .top && constraint.firstItem as? UIView == cardView {
                constraint.constant = showDateHeader ? 40 : 10
            }
        }
        
        if let hex = note.colorHex, let color = UIColor(hex: hex) {
            cardView.backgroundColor = color
            lblTitle.textColor = .white
            lblContent.textColor = .white.withAlphaComponent(0.8)
            lblHeaderDate.textColor = .white 
        } else if let defaultColor = defaultThemeColor {
            applyTheme(baseColor: defaultColor)
        }
        
        if let tHex = note.textColorHex, let tColor = UIColor(hex: tHex) {
            lblTitle.textColor = tColor
            lblContent.textColor = tColor.withAlphaComponent(0.8)
            lblHeaderDate.textColor = .white
            locationLabel.textColor = tColor.withAlphaComponent(0.6)
        } else if note.colorHex != nil {
            locationLabel.textColor = .lightGray
            lblHeaderDate.textColor = .white
        }
        
        if let range = note.content.range(of: #"\[IMAGE:(.+?)\]"#, options: .regularExpression) {
            let marker = String(note.content[range])
            let name = marker
                .replacingOccurrences(of: "[IMAGE:", with: "")
                .replacingOccurrences(of: "]", with: "")
            if let folder = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
                let url = folder.appendingPathComponent(name)
                if let img = UIImage(contentsOfFile: url.path) {
                    imgIcon.image = img
                    imgIcon.isHidden = false
                    imgIconHeightConstraint?.constant = 153
                } else {
                    imgIcon.isHidden = true
                    imgIconHeightConstraint?.constant = 0
                }
            } else {
                imgIcon.isHidden = true
                imgIconHeightConstraint?.constant = 0
            }
        } else {
            imgIcon.isHidden = true
            imgIconHeightConstraint?.constant = 0
        }
        
        if let loc = note.location, !loc.isEmpty {
            locationIconView.isHidden = false
            locationLabel.isHidden = false
            locationLabel.text = loc
        } else {
            locationIconView.isHidden = true
            locationLabel.isHidden = true
        }
        
        func applyTheme(baseColor: UIColor) {
            cardView.backgroundColor = baseColor.withAlphaComponent(0.35)
            cardView.layer.borderWidth = 0
            lblTitle.textColor = .white
            lblContent.textColor = UIColor(white: 1.0, alpha: 0.7)
            lblHeaderDate.textColor = .white
            locationLabel.textColor = .lightGray
        }
    }
}
