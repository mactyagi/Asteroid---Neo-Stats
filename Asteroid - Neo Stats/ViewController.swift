//
//  ViewController.swift
//  Asteroid - Neo Stats
//
//  Created by manukant tyagi on 25/10/21.
//

import UIKit
import Charts

class ViewController: UIViewController, ChartViewDelegate {

    @IBOutlet weak var lineCharView: LineChartView!
    @IBOutlet weak var endDate: UIDatePicker!
    @IBOutlet weak var startDate: UIDatePicker!
    @IBOutlet weak var fastestAstroidLabel: UILabel!
    @IBOutlet weak var closestAstroidLabel: UILabel!
    @IBOutlet weak var averageSizeLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    var startDateString = ""
    var endDateString = ""
    var fastestAstroid: (id: String, speed: String) = ("",""){
        didSet{
            fastestAstroidLabel.text = "Fastest Astroid is \(fastestAstroid.id) with speed is \(fastestAstroid.speed)Km/h"
        }
    }
    var closestAstroid: (id: String, distance: String) = ("","") {
        didSet{
            closestAstroidLabel.text = "Closest Astroid is \(closestAstroid.id) with distance \(closestAstroid.distance)Km"
        }
    }
    var averageSizeOfAstroid = "1"{
        didSet{
            averageSizeLabel.text =  "Average Size Of Astroid is \(averageSizeOfAstroid)Km"
        }
    }
    var astroidDict: [String : (speed:String, distance:String, averageSize: String)] = [:]
    var astroidDistanceFromEarthDict: [String: String] = [:]
    
    var data: Welcome?
    var set : [ChartDataEntry] = []
    
    
    let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)

    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))

    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.layer.cornerRadius = 10
        submitButton.layer.borderWidth = 1
        submitButton.layer.borderColor = UIColor.systemBlue.cgColor
        lineCharView.rightAxis.enabled = false
        lineCharView.xAxis.labelPosition = .bottom
        startDate.maximumDate = Date()
        startDate.maximumDate = Date()
        endDate.minimumDate = startDate.date
        endDate.maximumDate = Date() > Calendar.current.date(byAdding: .day, value: 6, to: startDate.date)! ? Calendar.current.date(byAdding: .day, value: 6, to: startDate.date) : Date()
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating()

        alert.view.addSubview(loadingIndicator)
//
    }
    func callingAPI(urlString: String, completionHandler: @escaping(Bool) -> Void){
        
        //present loading view
        present(alert, animated: true, completion: nil)
        
        // change String to URL
        
        let url = URL(string: urlString)
        guard let url = url else {
            return
        }
        
        //request the method
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        //assign the task to the session
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error)
            }
            if let data = data{
                
                //parse the data
                do {
                    self.data = try JSONDecoder().decode(Welcome.self, from: data)
                    print(self.data)
                    
                    completionHandler(true)
                    
                } catch {
                    print("Error took place\(error.localizedDescription).")
                    completionHandler(false)
                }

            }
            completionHandler(false)
        }
        
        //resume the task
        task.resume()
    }
    
    
    
    // MARK: set the data to the chart
    func setData() {
        set = []
        
        //fetch the data set from the response of API
        if let data = data{
            for (i, Object) in data.nearEarthObjects.enumerated(){
                self.set.append(ChartDataEntry(x: Double(i), y: Double(Object.value.count)))
            }
        }
        
        // assign the data Set to the chart
        DispatchQueue.main.async {
            let set1 = LineChartDataSet(entries: self.set, label: "\(self.startDateString)  to  \(self.endDateString)")
            let data = LineChartData(dataSet: set1)
            self.lineCharView.data = data
        }
        
       
    }
    
    
    
    
    //MARK: convert the date format to the api suitable format
    func convertDateString(dateString : Date, fromFormat sourceFormat : String!, toFormat desFormat : String!) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = sourceFormat
        let date = dateFormatter.date(from: dateFormatter.string(from: dateString))
        dateFormatter.dateFormat = desFormat
        return dateFormatter.string(from: date!)
    }
    
    
    
    
    //MARK: Start choosing startDate
    @IBAction func startDatePicker(_ sender: Any) {
        endDate.minimumDate = startDate.date
        endDate.maximumDate = Date() > Calendar.current.date(byAdding: .day, value: 6, to: startDate.date)! ? Calendar.current.date(byAdding: .day, value: 6, to: startDate.date) : Date()
    }
 
 
    
    //MARK: submit button pressed
    @IBAction func submitButtonPressed(_ sender: Any) {
        //get the startDate in suitale format
       startDateString = convertDateString(dateString: startDate.date, fromFormat: "YYYY-MM-DD HH:mm:ss Z", toFormat: "YYYY-MM-dd")
        
        //get the endDate in the suitable format
        endDateString = convertDateString(dateString: endDate.date, fromFormat: "YYYY-MM-DD hh:mm:ss ZZZZ", toFormat: "YYYY-MM-dd")
       
        //set the url
        let url = "https://api.nasa.gov/neo/rest/v1/feed?start_date=\(startDateString)&end_date=\(endDateString)&api_key=DEMO_KEY"
        
        //MARK: Call the API
        callingAPI(urlString: url, completionHandler: { (success) in
            if success{
                
                //dismiss the loading view
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
                
                
                //set date for lineChart
                self.setData()
                
                
                if let objects = self.data?.nearEarthObjects{
                    
                    for object in objects{
                        
                        object.value.forEach { (a) in
                        
                            //get the speed , distance, size of the astroid
                            self.astroidDict[a.id] = (a.closeApproachData.map({ datum in
                                datum.relativeVelocity.kilometersPerHour
                            }).max() ?? "1", a.closeApproachData.map({ datum in
                                datum.missDistance.kilometers
                            }).max() ?? "1", String(Double(a.estimatedDiameter.kilometers.estimatedDiameterMax) + Double(a.estimatedDiameter.kilometers.estimatedDiameterMin) / 2))
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    //fetch fastest astroid from the dictionary
                    let a = self.astroidDict.max { (a, b) in
                        return Double(a.value.speed) ?? 0 < Double(b.value.speed) ?? 0
                    }
                    self.fastestAstroid = (id : a?.key ?? "", speed : a?.value.speed ?? "")
                    
                    
                    //fetch closest astroid from the dictionary
                    let b = self.astroidDict.max(by: { (a, b) in
                        return Double(a.value.distance) ?? 0 > Double(b.value.distance) ?? 0
                    })
                    self.closestAstroid = (id:b?.key ?? "", distance:b?.value.distance ?? "")
                    var sum: Double = 0
                    
                    
                    //fetch average size of astroid in the dictionary
                    for i in self.astroidDict{
                        sum += Double(i.value.averageSize) ?? 0
                    }
                    self.averageSizeOfAstroid = String(sum / Double(self.astroidDict.count))
                }
                
                
            }
            
        })
    }
    
}

