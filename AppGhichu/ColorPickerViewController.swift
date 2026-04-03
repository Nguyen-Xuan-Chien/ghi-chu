import UIKit

class ColorPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var onColorSelected: ((UIColor) -> Void)?
    
    private let colors: [UIColor] = [
        .white, .lightGray, .gray, .darkGray, .black,
        .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal,
        .systemBlue, .systemIndigo, .systemPurple, .systemPink, .systemBrown,
        UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0),
        UIColor(red: 0.1, green: 0.9, blue: 0.1, alpha: 1.0),
        UIColor(red: 0.1, green: 0.1, blue: 0.9, alpha: 1.0),
        UIColor(red: 0.9, green: 0.9, blue: 0.1, alpha: 1.0),
        UIColor(red: 0.1, green: 0.9, blue: 0.9, alpha: 1.0),
        UIColor(red: 0.9, green: 0.1, blue: 0.9, alpha: 1.0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        preferredContentSize = CGSize(width: 250, height: 250)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ColorCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cv)
        
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath)
        cell.backgroundColor = colors[indexPath.item]
        cell.layer.cornerRadius = 5
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onColorSelected?(colors[indexPath.item])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 40)
    }
}
