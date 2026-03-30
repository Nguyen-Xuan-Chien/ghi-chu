import UIKit


class MoreMenuViewController: UIViewController {
    var note: Note?
    var onEdit: ((Note) -> Void)?
    var onDelete: ((Note) -> Void)?

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var printButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
    }

    @IBAction func editTapped(_ sender: UIButton) {
        guard let note = note else {
            dismiss(animated: true)
            return
        }
        dismiss(animated: true) { [weak self] in
            self?.onEdit?(note)
        }
    }
    

    @IBAction func bookmarkTapped(_ sender: UIButton) {
        dismiss(animated: true)
        print("Dấu trang")
    }

    @IBAction func printTapped(_ sender: UIButton) {
        dismiss(animated: true)
        print("In")
    }

    @IBAction func deleteTapped(_ sender: UIButton) {
        guard let note = note else {
            dismiss(animated: true)
            return
        }
        dismiss(animated: true) { [weak self] in
            self?.onDelete?(note)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismiss(animated: true)
    }
}
