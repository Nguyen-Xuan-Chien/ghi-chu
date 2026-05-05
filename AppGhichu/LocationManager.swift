import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private var completion: ((String?) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func getCurrentLocation(completion: @escaping (String?) -> Void) {
        self.completion = completion
        
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            completion("Không có quyền truy cập vị trí")
        @unknown default:
            completion(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        // Dừng cập nhật sau khi lấy được vị trí
        manager.stopUpdatingLocation()
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                var addressParts: [String] = []
                
                // Ưu tiên các thông tin chi tiết
                if let name = placemark.name { addressParts.append(name) }
                if let subLocality = placemark.subLocality {
                    if !addressParts.contains(subLocality) { addressParts.append(subLocality) }
                }
                if let locality = placemark.locality { 
                    if !addressParts.contains(locality) { addressParts.append(locality) } 
                }
                if let administrativeArea = placemark.administrativeArea {
                    if !addressParts.contains(administrativeArea) { addressParts.append(administrativeArea) }
                }
                
                let address = addressParts.isEmpty ? "Vị trí không xác định" : addressParts.joined(separator: ", ")
                self?.completion?(address)
            } else {
                // Fallback nếu không reverse geocode được
                let coords = String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
                self?.completion?("Vị trí: \(coords)")
            }
            self?.completion = nil 
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        // Chỉ gọi completion nếu chưa có kết quả
        if completion != nil {
            completion?("Không lấy được vị trí: \(error.localizedDescription)")
            completion = nil
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
