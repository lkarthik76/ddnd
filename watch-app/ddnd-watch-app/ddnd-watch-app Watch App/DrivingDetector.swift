//
//  DrivingDetector.swift
//  ddnd-watch-app
//
//  Created by Karthikeyan Lakshminarayanan on 09/06/25.
//

import Foundation
import CoreMotion
import CoreLocation

class DrivingDetector : NSObject , ObservableObject , CLLocationManagerDelegate {
    private let motionActivityManager: CMMotionActivityManager = CMMotionActivityManager()
    private let locationManager: CLLocationManager = CLLocationManager()
    @Published var isDriving: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.activityType = .automotiveNavigation
        locationManager.startUpdatingLocation()
    }
    
    private func startMotionUpdates() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        motionActivityManager.startActivityUpdates(to: .main){ activity in
            guard let activity = activity else { return }
            if activity.automotive && !activity.stationary{
                DispatchQueue.main.async {
                    self.isDriving = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isDriving = false
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let speed = locations.last?.speed else { return }
        if speed > 2.77 {
            self.isDriving = true
        } else {
            self.isDriving = false
        }
    }
    
}
