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

        contentView.backgroundColor = .black
        backgroundColor = .black

        cardView.backgroundColor = UIColor(red: 46/255, green: 50/255, blue: 62/255, alpha: 1)
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = false
        cardView.layer.masksToBounds = false

        imgIcon.contentMode = .scaleAspectFill
        imgIcon.clipsToBounds = true
        imgIcon.layer.cornerRadius = 16
        
        let tint = UIView()
        tint.isUserInteractionEnabled = false
        tint.backgroundColor = UIColor(red: 0.12, green: 0.30, blue: 0.55, alpha: 0.30)
        tint.translatesAutoresizingMaskIntoConstraints = false
        imgIcon.addSubview(tint)
        NSLayoutConstraint.activate([
            tint.leadingAnchor.constraint(equalTo: imgIcon.leadingAnchor),
            tint.trailingAnchor.constraint(equalTo: imgIcon.trailingAnchor),
            tint.topAnchor.constraint(equalTo: imgIcon.topAnchor),
            tint.bottomAnchor.constraint(equalTo: imgIcon.bottomAnchor)
        ])
        mapTintView = tint
        

        lblMonth.textColor = .white
        lblMonth.backgroundColor = .clear
        lblTitle.textColor = .white
        lblTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        lblTitle.setContentCompressionResistancePriority(.required, for: .vertical)
        lblTitle.setContentHuggingPriority(.defaultHigh, for: .vertical)
        lblHeaderDate.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        lblHeaderDate.textColor = UIColor(white: 1.0, alpha: 0.95)
        lblHeaderDate.textAlignment = .left
        lblHeaderDate.isHidden = false
        lblHeaderDate.superview?.bringSubviewToFront(lblHeaderDate)
        cardView.bringSubviewToFront(lblTitle)
        cardView.bringSubviewToFront(lblDate)
        cardView.bringSubviewToFront(btnMore)
        
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.35
        cardView.layer.shadowRadius = 12
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        lblDate.textColor = UIColor(white: 1.0, alpha: 0.8)
        lblDate.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        lblDate.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        lblDate.setContentHuggingPriority(.defaultLow, for: .vertical)


        
        btnMore.addTarget(self, action: #selector(handleMoreTap), for: .touchUpInside)
     
        for c in cardView.constraints {
            if c.firstAttribute == .trailing,
               c.secondItem as? UIView === btnMore,
               c.secondAttribute == .trailing {
                c.constant = 0
            }
        }
        if #available(iOS 15.0, *) {
            if var cfg = btnMore.configuration {
                cfg.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                btnMore.configuration = cfg
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
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: imgIcon.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: 16, height: 16))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        imgIcon.layer.mask = mask
    }

    @objc private func handleMoreTap() {
        onMoreTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMoreTapped = nil
    }

    func configure(note: Note) {
        lblMonth.text = ""
        lblMonth.isHidden = true
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

        imgIcon.image = UIImage(named: "img_icon") ?? UIImage(systemName: "photo")
    }
    
    func applyTheme(baseColor: UIColor) {
        cardView.backgroundColor = baseColor.withAlphaComponent(0.35)
        cardView.layer.borderWidth = 0
        lblTitle.textColor = .white
        lblDate.textColor = UIColor(white: 1.0, alpha: 0.75)
    }

    private func getMonth(from iso: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = df.date(from: iso) {
            let cal = Calendar.current
            let month = cal.component(.month, from: date)
            let year = cal.component(.year, from: date)
            return "tháng \(month) năm \(year)"
        }
        return ""
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
