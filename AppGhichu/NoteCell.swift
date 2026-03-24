import UIKit

class NoteCell: UITableViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var lblMonth: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var lblHeaderDate: UILabel!

    // Callback gửi ra MainViewController
    var onMoreTapped: (() -> Void)?
    
    private var mapTintView: UIView?

    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.layer.cornerRadius = 15
        cardView.clipsToBounds = true
        
        btnMore.addTarget(self, action: #selector(handleMoreTap), for: .touchUpInside)
        if #available(iOS 15.0, *) {
            if var cfg = btnMore.configuration {
                cfg.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            } else {
                var cfg = UIButton.Configuration.plain()
                cfg.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                btnMore.configuration = cfg
            }
        } else {
            btnMore.contentEdgeInsets = .zero
        }
        btnMore.contentHorizontalAlignment = .trailing
        btnMore.setContentHuggingPriority(.required, for: .horizontal)
        btnMore.setContentCompressionResistancePriority(.required, for: .horizontal)
        cardView.bringSubviewToFront(btnMore)
    }


    @objc private func handleMoreTap() {
        onMoreTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMoreTapped = nil
    }

    func configure(note: Note) {
        let rawTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawTitle.isEmpty {
            let firstLine = note.content
                .components(separatedBy: .newlines)
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            lblTitle.text = firstLine.isEmpty ? "Tiêu đề" : firstLine
        } else {
            lblTitle.text = rawTitle
        }
        lblTitle.numberOfLines = 2
        lblDate.isHidden = false
        lblDate.text = getFullDate(from: note.dateISO)
        lblHeaderDate.text = getHeaderDate(from: note.dateISO)
        
        
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
        lblDate.textColor = UIColor(white: 1.0, alpha: 0.75)
    }

    private func getFullDate(from iso: String) -> String {
        let inDf = DateFormatter()
        inDf.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = inDf.date(from: iso) else { return "" }
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let day = cal.component(.day, from: date)
        let month = cal.component(.month, from: date)
        let year = cal.component(.year, from: date)
        let weekdayText = (weekday == 1) ? "Chủ Nhật" : "Thứ \(weekday)"
        return "\(weekdayText), Ngày \(day) Thg \(month), \(year)"
    }
    
    private func getHeaderDate(from iso: String) -> String {
        let inDf = DateFormatter()
        inDf.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = inDf.date(from: iso) else { return "" }
        let out = DateFormatter()
        out.locale = Locale(identifier: "vi_VN")
        out.dateFormat = "EEEE d 'tháng' M"
        return out.string(from: date).capitalized
    }
}
