import UIKit
import ObjectiveC

private var DateHeaderLabelKey: UInt8 = 0

extension UITableView {
    var dateHeaderLabel: UILabel? {
        get { objc_getAssociatedObject(self, &DateHeaderLabelKey) as? UILabel }
        set { objc_setAssociatedObject(self, &DateHeaderLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func applyDateHeader(date: Date = Date(),
                         locale: Locale = Locale(identifier: "vi_VN"),
                         font: UIFont = .systemFont(ofSize: 17, weight: .bold),
                         textColor: UIColor = UIColor(white: 1.0, alpha: 0.95),
                         height: CGFloat = 44,
                         padding: CGFloat = 16) {
        let df = DateFormatter()
        df.locale = locale
        df.dateFormat = "EEEE, d 'tháng' M"
        let text = df.string(from: date).capitalized
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: height))
        container.backgroundColor = .clear
        let label = UILabel(frame: CGRect(x: padding, y: 8, width: bounds.width - padding*2, height: height - 16))
        label.font = font
        label.textColor = textColor
        label.text = text
        container.addSubview(label)
        tableHeaderView = container
        dateHeaderLabel = label
    }
    
    func updateDateHeader(date: Date = Date(), locale: Locale = Locale(identifier: "vi_VN")) {
        guard let label = dateHeaderLabel else { return }
        let df = DateFormatter()
        df.locale = locale
        df.dateFormat = "EEEE, d 'tháng' M"
        label.text = df.string(from: date).capitalized
    }
    
    func refreshDateHeaderWidth() {
        guard let header = tableHeaderView else { return }
        var f = header.frame
        f.size.width = bounds.width
        header.frame = f
        tableHeaderView = header
        if let label = dateHeaderLabel {
            label.frame.size.width = bounds.width - label.frame.origin.x * 2
        }
    }
}
