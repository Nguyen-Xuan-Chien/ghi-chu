import UIKit

class NoteCell: UITableViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var lblMonth: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblContent: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var lblHeaderDate: UILabel!
    @IBOutlet weak var lblHeaderEmoji: UILabel!

    var onMoreTapped: (() -> Void)?
    
    private var mapTintView: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 15
        cardView.clipsToBounds = true
        
    }
    
    @IBAction func handleMoreTap() {
        onMoreTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMoreTapped = nil
    }

    func configure(note: Note, defaultThemeColor: UIColor? = nil) {
        let rawTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawTitle.isEmpty {
            lblTitle.text = "Tiêu đề"
        } else {
            lblTitle.text = rawTitle
        }
        
        let cleanedContent = note.content.replacingOccurrences(of: #"\[IMAGE:.+?\]\n?"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        lblContent.text = cleanedContent.isEmpty ? "Bắt đầu viết" : cleanedContent
        
        lblTitle.numberOfLines = 1
        lblContent.numberOfLines = 2
        
        lblDate.isHidden = false
        lblDate.text = note.displayDate
        lblHeaderDate.text = note.displayDate
        lblHeaderEmoji.text = note.emoji ?? ""
        
        // Xử lý màu sắc
        if let hex = note.colorHex, let color = UIColor(hex: hex) {
            cardView.backgroundColor = color
            lblTitle.textColor = .white
            lblContent.textColor = .white.withAlphaComponent(0.8)
            lblDate.textColor = .white.withAlphaComponent(0.7)
            lblHeaderDate.textColor = .white.withAlphaComponent(0.7)
        } else if let defaultColor = defaultThemeColor {
            applyTheme(baseColor: defaultColor)
        }

        if let tHex = note.textColorHex, let tColor = UIColor(hex: tHex) {
            lblTitle.textColor = tColor
            lblContent.textColor = tColor.withAlphaComponent(0.8)
            lblDate.textColor = tColor.withAlphaComponent(0.7)
            lblHeaderDate.textColor = tColor.withAlphaComponent(0.7)
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
                } else {
                    imgIcon.image = UIImage(named: "img_icon") ?? UIImage(systemName: "photo")
                }
            } else {
                imgIcon.image = UIImage(named: "img_icon") ?? UIImage(systemName: "photo")
            }
        } else {
            imgIcon.image = UIImage(named: "img_icon") ?? UIImage(systemName: "photo")
        }
    }
    
    func applyTheme(baseColor: UIColor) {
        cardView.backgroundColor = baseColor.withAlphaComponent(0.35)
        cardView.layer.borderWidth = 0
        lblTitle.textColor = .white
        lblContent.textColor = UIColor(white: 1.0, alpha: 0.7)
        lblDate.textColor = UIColor(white: 1.0, alpha: 0.85)
        lblDate.font = UIFont.systemFont(ofSize: 11, weight: .medium)
    }
}
