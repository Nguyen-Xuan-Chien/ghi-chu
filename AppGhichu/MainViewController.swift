import UIKit
var selectedNote: Note?

struct IconData {
    let img: String
    let title: String
}

class MainViewController: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noteTitleLabel: UILabel!
    @IBOutlet weak var noteBodyTextView: UITextView!

    @IBOutlet weak var emptyImageView: UIImageView!
    @IBOutlet weak var emptyTitleLabel: UILabel!
    @IBOutlet weak var emptySubtitleLabel: UILabel!

    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var lblNum1: UILabel!
    @IBOutlet weak var lblText1: UILabel!

    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var lblNum2: UILabel!
    @IBOutlet weak var lblText2: UILabel!

    @IBOutlet weak var btn3: UIButton!
    @IBOutlet weak var lblNum3: UILabel!
    @IBOutlet weak var lblText3: UILabel!

    @IBOutlet weak var tblv: UITableView!
    
    private let db = DatabaseHelper.shared
    private var notes: [Note] = []
    private var sections: [(title: String, items: [Note])] = []
    private let sectionPalette: [UIColor] = [
        UIColor(red: 0.29, green: 0.22, blue: 0.47, alpha: 1.0),
        UIColor(red: 0.18, green: 0.30, blue: 0.52, alpha: 1.0),
        UIColor(red: 0.33, green: 0.19, blue: 0.43, alpha: 1.0),
        UIColor(red: 0.17, green: 0.36, blue: 0.34, alpha: 1.0),
        UIColor(red: 0.40, green: 0.22, blue: 0.26, alpha: 1.0),
        UIColor(red: 0.36, green: 0.28, blue: 0.18, alpha: 1.0)
    ]
    private var headerDateLabel: UILabel?

    let icons: [IconData] = [
        IconData(img: "icon1", title: "bài viết năm nay"),
        IconData(img: "icon2", title: "từ"),
        IconData(img: "icon3", title: "ngày ghi nhật ký")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDateLabel()
        setupUI()
        hideLegacyHeader()
        liftTableView()
        setupIcons()
        loadNotesFromDatabase()
        updateIconData()
        updateEmptyState()

        tblv.delegate = self
        tblv.dataSource = self

        let nib = UINib(nibName: "NoteCell", bundle: nil)
        tblv.register(nib, forCellReuseIdentifier: "NoteCell")
        tblv.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "MonthHeader")
        
        tblv.backgroundColor = .black
        tblv.backgroundView = nil
        tblv.separatorStyle = .none
        tblv.showsVerticalScrollIndicator = false
        if #available(iOS 15.0, *) {
            tblv.sectionHeaderTopPadding = 0
        }
        tblv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        installTableDateHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotesFromDatabase()
        buildSections()
        updateIconData()
        tblv.reloadData()
        updateEmptyState()
        headerDateLabel?.text = formattedHeaderDate()
    }

    private func updateEmptyState() {
        tblv.isHidden = false
        
        if notes.isEmpty {
            emptyImageView.isHidden = false
            emptyTitleLabel.isHidden = false
            emptySubtitleLabel.isHidden = false
        } else {
            emptyImageView.isHidden = true
            emptyTitleLabel.isHidden = true
            emptySubtitleLabel.isHidden = true
        }
    }


    private func setupIcons() {

        btn1.setImage(UIImage(named: icons[0].img), for: .normal)
        lblText1.text = icons[0].title

        btn2.setImage(UIImage(named: icons[1].img), for: .normal)
        lblText2.text = icons[1].title

        btn3.setImage(UIImage(named: icons[2].img), for: .normal)
        lblText3.text = icons[2].title

        btn1.imageView?.contentMode = .scaleAspectFit
        btn2.imageView?.contentMode = .scaleAspectFit
        btn3.imageView?.contentMode = .scaleAspectFit
    }

    private func updateIconData() {
        notes = db.getAllNotes()

        let year = Calendar.current.component(.year, from: Date())
        let countThisYear = notes.filter {
            Calendar.current.component(.year, from: $0.createdAt) == year
        }.count
        lblNum1.text = "\(countThisYear)"

        let keywordCount = notes.filter {
            $0.title.lowercased().contains("từ") ||
            $0.content.lowercased().contains("từ")
        }.count
        lblNum2.text = "\(keywordCount)"

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let uniqueDays = Set(notes.map { formatter.string(from: $0.createdAt) })
        lblNum3.text = "\(uniqueDays.count)"
    }

    private func setupUI() {
        dateLabel?.textColor = .lightGray
        noteTitleLabel?.textColor = .white
        noteBodyTextView?.textColor = .lightGray
        noteBodyTextView?.isEditable = false
        noteBodyTextView?.backgroundColor = .clear

        noteTitleLabel?.backgroundColor = UIColor(white: 0.2, alpha: 1)
        noteTitleLabel?.layer.cornerRadius = 10
        noteTitleLabel?.clipsToBounds = true
        noteTitleLabel?.textAlignment = .left

        noteBodyTextView?.textColor = .lightGray
        noteBodyTextView?.isEditable = false
        noteBodyTextView?.backgroundColor = UIColor(white: 0.18, alpha: 1)
        noteBodyTextView?.layer.cornerRadius = 12
        noteBodyTextView?.clipsToBounds = true
    }
    private func hideLegacyHeader() {
        noteTitleLabel?.isHidden = true
        noteBodyTextView?.isHidden = true
        dateLabel?.isHidden = true
        func walk(_ v: UIView) {
            for s in v.subviews {
                if let l = s as? UILabel,
                   (l.text ?? "").lowercased().contains("tháng"),
                   !(l.isDescendant(of: tblv)) {
                    l.isHidden = true
                }
                walk(s)
            }
        }
        walk(view)
    }
    private func formattedHeaderDate() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "EEEE, d 'tháng' M"
        return f.string(from: Date()).capitalized
    }
    private func installTableDateHeader() {
        tblv.applyDateHeader()
        headerDateLabel = tblv.dateHeaderLabel
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tblv.refreshDateHeaderWidth()
    }
    private func liftTableView() {
        var removed: [NSLayoutConstraint] = []
        for c in view.constraints {
            if (c.firstItem as? UITableView) == tblv && c.firstAttribute == .top {
                removed.append(c)
            }
        }
        NSLayoutConstraint.deactivate(removed)
        let top = tblv.topAnchor.constraint(equalTo: lblText3.bottomAnchor, constant: 0)
        top.priority = .required
        top.isActive = true
        view.setNeedsLayout()
    }

    private func setupDateLabel() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, 'ngày' d 'thg' M"
        let text = formatter.string(from: Date()).capitalized
        dateLabel?.text = text
        headerDateLabel?.text = text
    }

    func loadNotesFromDatabase() {
        notes = db.getAllNotes()

        guard let latestNote = notes.first else {
            noteTitleLabel?.text = "Chưa có ghi chú"
            noteBodyTextView?.text = ""
            return
        }

        noteTitleLabel?.numberOfLines = 1
        noteTitleLabel?.text = "Tiêu đề: \(latestNote.title)"
        noteBodyTextView?.text = latestNote.content
    }
    private func buildSections() {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: notes) { (note) -> Date in
            let comps = cal.dateComponents([.year, .month], from: note.createdAt)
            return cal.date(from: comps) ?? note.createdAt
        }
        let sortedKeys = grouped.keys.sorted(by: { $0 > $1 })
        var result: [(title: String, items: [Note])] = []
        let titleFormatter = DateFormatter()
        titleFormatter.locale = Locale(identifier: "vi_VN")
        titleFormatter.dateFormat = "'tháng' M 'năm' yyyy"
        for key in sortedKeys {
            var items = grouped[key] ?? []
            items.sort(by: { $0.createdAt > $1.createdAt })
            let title = titleFormatter.string(from: key)
            result.append((title: title, items: items))
        }
        sections = result
    }
    private func timeOfDay(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "sáng"
        case 12..<18: return "chiều"
        default: return "tối"
        }
    }
    func openEdit(note: Note) {
        let editVC = EditNoteViewController(
            nibName: "EditNoteViewController",
            bundle: nil
        )

        editVC.modalPresentationStyle = .fullScreen
        editVC.note = note

        editVC.onSave = { [weak self] updatedNote in
            guard let self = self else { return }

            self.db.updateNote(updatedNote)

            self.loadNotesFromDatabase()
            self.tblv.reloadData()
        }

        present(editVC, animated: true)
    }



    @IBAction func addButtonTapped(_ sender: UIButton) {
        let newPostVC = NewPostViewController(nibName: "NewPostViewController", bundle: nil)
        newPostVC.modalPresentationStyle = .fullScreen
        present(newPostVC, animated: true)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "NoteCell",
            for: indexPath
        ) as! NoteCell

        let note = sections[indexPath.section].items[indexPath.row]
        let defaultColor = sectionPalette[indexPath.section % sectionPalette.count]
        cell.configure(note: note, defaultThemeColor: defaultColor)

        cell.onMoreTapped = { [weak self] in
            self?.showMoreMenu(for: note)
        }
        
        return cell
    }
    
    private func showMoreMenu(for note: Note) {

        let menuVC = MoreMenuViewController(
            nibName: "MoreMenuViewController",
            bundle: nil
        )
        menuVC.note = note
        menuVC.modalPresentationStyle = .overCurrentContext
        menuVC.modalTransitionStyle = .crossDissolve

        menuVC.onEdit = { [weak self] updatedNote in
            self?.openEdit(note: note)
        }

        menuVC.onDelete = { [weak self] noteToDelete in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Xác nhận xóa", message: "Bạn có chắc chắn muốn xóa ghi chú này không?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Xóa", style: .destructive, handler: { _ in
                self.db.deleteNote(id: noteToDelete.id)
                
                self.loadNotesFromDatabase()
                self.buildSections()
                self.updateIconData()
                self.tblv.reloadData()
                self.updateEmptyState()
            }))
            self.present(alert, animated: true)
        }

        present(menuVC, animated: true)
    }



    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 320
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}
