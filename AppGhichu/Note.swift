import UIKit

struct Note {
    var id: Int64
    var title: String
    var content: String
    var dateISO: String
    var createdAt: Date
    var colorHex: String?
    var textColorHex: String?
    var emoji: String?
    var location: String?

    init(id: Int64 = 0, title: String, content: String, date: Date = Date(), colorHex: String? = nil, textColorHex: String? = nil, emoji: String? = nil, location: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = date
        self.colorHex = colorHex
        self.textColorHex = textColorHex
        self.emoji = emoji
        self.location = location

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.dateISO = fmt.string(from: date)
    }

    init(id: Int64, title: String, content: String, dateISO: String, colorHex: String? = nil, textColorHex: String? = nil, emoji: String? = nil, location: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.dateISO = dateISO
        self.colorHex = colorHex
        self.textColorHex = textColorHex
        self.emoji = emoji
        self.location = location

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.createdAt = fmt.date(from: dateISO) ?? Date()
    }

    var date: Date {
        return createdAt
    }

    var displayDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEEE, 'ngày' d 'thg' M"
        return f.string(from: createdAt).capitalized
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count != 6 {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

        return String(format: "#%06x", rgb)
    }
}
