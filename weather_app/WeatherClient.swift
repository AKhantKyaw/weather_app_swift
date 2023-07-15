//
//  WeatherClient.swift
//  weather_application
//
//  Created by Aung Khant Kyaw on 02/07/2023.
//

import Foundation
import CoreLocation
import SwiftUI

final class WeatherClient : NSObject ,ObservableObject, CLLocationManagerDelegate{
   @Published var currentWeather : Weather?
    
  private  let locationMananger =  CLLocationManager()
  private  let dateFormatter = ISO8601DateFormatter()
    
    override init() {
            super.init()
            locationMananger.delegate = self
            requestLocation()
        }
    
    func fetchWeather ()async{
        guard let location = locationMananger.location else{
        requestLocation()
       return
        }
        guard let url = URL(string: "https://api.tomorrow.io/v4/timelines?location=\(location.coordinate.latitude),\(location.coordinate.longitude)&fields=temperature&fields=weatherCode&units=metric&timesteps=1h&startTime=\(dateFormatter.string(from: Date()))&endTime=\(dateFormatter.string(from: Date().addingTimeInterval(60 * 60)))&apikey=5Ey6ScGwuJ7V6VqqsWq3AVHZhPBU8q35") else {
            return
        }
        do {
                let (data, _) = try await URLSession.shared.data(from: url)
            if let weatherResponse = try? JSONDecoder().decode(WeatherModel.self, from: data),
               let weatherValue = weatherResponse.data.timelines.first?.intervals.first?.values,
               let weatherCode = WeatherCode(rawValue: "\(weatherValue.weatherCode)") {
                DispatchQueue.main.async { [weak self] in
                    self?.currentWeather = Weather(temperature: Int(weatherValue.temperature),
                                                   weatherCode: weatherCode)
                }
            }
        }catch {
                    // handle the error
}
    }
    
   private func requestLocation(){
        locationMananger.requestWhenInUseAuthorization()
        locationMananger.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) async{
            Task { await fetchWeather() }
        }
    
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            // handle the error
        }
}
