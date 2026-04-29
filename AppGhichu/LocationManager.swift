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
            manager.requestLocation()
        case .denied, .restricted:
            completion("Không có quyền truy cập vị trí")
        @unknown default:
            completion(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            completion?(nil)
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                var addressParts: [String] = []
                if let name = placemark.name { addressParts.append(name) }
                if let thoroughfare = placemark.thoroughfare { 
                    if !addressParts.contains(thoroughfare) { addressParts.append(thoroughfare) } 
                }
                if let locality = placemark.locality { 
                    if !addressParts.contains(locality) { addressParts.append(locality) } 
                }
                
                let address = addressParts.joined(separator: ", ")
                self?.completion?(address)
            } else {
                self?.completion?(nil)
            }
            self?.completion = nil 
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        completion?("Không lấy được vị trí")
        completion = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
