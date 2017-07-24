/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import UIKit

import MapKit
import CoreLocation
import GooglePlaces
import AVKit

class ViewController: UIViewController {
  
  fileprivate let locationManager = CLLocationManager()
  fileprivate var places = [Place]()
  
  @IBOutlet weak var mapView: MKMapView!
  
  fileprivate var arViewController: ARViewController!
  
  var placesClient: GMSPlacesClient!
  var likelyPlaces: [GMSPlace] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.startUpdatingLocation()
    locationManager.requestWhenInUseAuthorization()
    
    placesClient = GMSPlacesClient.shared()
    listLikelyPlaces()
  }
  
  func listLikelyPlaces() {
    likelyPlaces.removeAll()
    
    placesClient.currentPlace(callback: { (placeLikelihoods, error) -> Void in
      if let error = error {
        // TODO: Handle the error.
        print("Current Place error: \(error.localizedDescription)")
        return
      }
      
      // Get likely places and add to the list.
      if let likelihoodList = placeLikelihoods {
        for likelihood in likelihoodList.likelihoods {
          let place = Place(location: CLLocation(latitude: likelihood.place.coordinate.latitude, longitude: likelihood.place.coordinate.longitude), reference: "reference", name: likelihood.place.name, address: likelihood.place.formattedAddress ?? "address")
          if let phoneNumber = likelihood.place.phoneNumber {
            place.phoneNumber = phoneNumber
          }
          if let website = likelihood.place.website {
            place.website = String(describing: website)
          }
          self.places.append(place)
          let annotation = PlaceAnnotation(location: likelihood.place.coordinate, title: likelihood.place.name)
          DispatchQueue.main.async{
            self.mapView.addAnnotation(annotation)
          }
        }
      }
    })
  }
  
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //1
    if locations.count > 0 {
      let location = locations.last!
      print("Accuracy: \(location.horizontalAccuracy)")
      
      //2
      if location.horizontalAccuracy < 100 {
        //3
        manager.stopUpdatingLocation()
        let span = MKCoordinateSpan(latitudeDelta: 0.014, longitudeDelta: 0.014)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.region = region
        
        listLikelyPlaces()
      }
    }
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @IBAction func showARController(_ sender: Any) {
    
    print("wciesnieto Camera")
    arViewController = ARViewController()
    arViewController.dataSource = self
    arViewController.presenter.maxVisibleAnnotations = 30
    arViewController.setAnnotations(places)
    
    if let error = ARViewController.isAllHardwareAvailable() {
      let message = error.userInfo["description"] as? String
      print(message!)
      
    }
    self.present(arViewController, animated: true, completion: nil)
    
  }
  
  func showInfoView(forPlace place: Place) {
    
    let alert = UIAlertController(title: place.placeName , message: place.infoText, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    arViewController.present(alert, animated: true, completion: nil)
  }
  
  
  
}
extension ViewController: ARDataSource {
  func ar(_ arViewController: ARViewController, viewForAnnotation: ARAnnotation) -> ARAnnotationView {
    let annotationView = AnnotationView()
    annotationView.annotation = viewForAnnotation
    annotationView.delegate = self
    annotationView.frame = CGRect(x: 0, y: 0, width: 150, height: 50)
    
    return annotationView
  }
}

extension ViewController: AnnotationViewDelegate {
  func didTouch(annotationView: AnnotationView) {
    if let annotation = annotationView.annotation as? Place {
      self.showInfoView(forPlace: annotation)
    }
  }
}

extension ViewController: CLLocationManagerDelegate {
}

