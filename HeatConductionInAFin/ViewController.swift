//
//  ViewController.swift
//  HeatConductionInAFin
//
//  Created by Allan Jones on 5/12/15.
//  Copyright (c) 2015 Allan Jones. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
                                                                               // Sample Input:
    @IBOutlet weak var sourceTemperatureTextField: UITextField!         // 400.0
    @IBOutlet weak var ambientTemperatureTextField: UITextField!        // 60.0
    @IBOutlet weak var heatTransferCoefficientTextField: UITextField!   // 10.0
    @IBOutlet weak var thermalConductivityTextField: UITextField!       // 190.0  (for copper)
    @IBOutlet weak var finHeightTextField: UITextField!                 // 1.0
    @IBOutlet weak var finThicknessTextField: UITextField!              // 0.010
    @IBOutlet weak var heatTransferRateTextField: UITextField!          // for output
    @IBOutlet weak var finEfficiencyTextField: UITextField!             // for output
    
    @IBOutlet weak var tableView: UITableView!
    
    let numberOfSegments = 91
    
    var segments:[Segment] = []
    
    var segment = Segment()
    
    var temperatures = [Double](count: 91, repeatedValue:0.0)
    
    var profileArray:[Dictionary<String, String>] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Build segments array
        
        for var i = 0;  i < numberOfSegments; ++i {
            self.segments.append(segment)
            segment.temperature = 0.0           // initial values for temperature property
            self.temperatures.append(segment.temperature)
        }
        
        // Build dictionaries for initial table entries
        
        for var j = 0; j < numberOfSegments; ++j {
            segments[j].temperature = temperatures[j]
            
            profileArray.append(["segmentNumber":"\(j)", "segmentTemp":"\(segments[j].temperature)"])
        }
        println("\(profileArray.count) segments in array")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //println(numberOfSegments)
        return numberOfSegments
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let profileDict:Dictionary = profileArray[indexPath.row]
        var cell: ProfileCell = tableView.dequeueReusableCellWithIdentifier("myCell") as ProfileCell
        //println(indexPath.row)
        cell.segmentNumber.text = profileDict["segmentNumber"]
        cell.segmentTemp.text = profileDict["segmentTemp"]
        return cell
    }
    
    // UITableViewDelegate
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45.0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Segment Number      Temperature, F"
    }

    // Enter data values and begin calculations

    @IBAction func didPressCalculateButton(sender: UIButton) {
        
        let hotTemperature = Double((sourceTemperatureTextField.text as NSString).doubleValue)
        let ambientTemperature = Double((ambientTemperatureTextField.text as NSString).doubleValue)
        let finCoefficient = Double((heatTransferCoefficientTextField.text as NSString).doubleValue)
        let heightOfFinIn = Double((finHeightTextField.text as NSString).doubleValue)
        let thicknessOfFinIn = Double((finThicknessTextField.text as NSString).doubleValue)
        let finConductivity = Double((thermalConductivityTextField.text as NSString).doubleValue)
        
        //convert fin height and thickness to feet
        let finHeight = heightOfFinIn / 12.0
        let finThickness = thicknessOfFinIn / 12.0
        
        let range = numberOfSegments - 1
        
        let deltaX = finHeight / Double(range)
        
        println("hot temperature = \(hotTemperature) F")
        println("ambient temperature = \(ambientTemperature) F")
        println("finCoefficient = \(finCoefficient) BTU/hr-ft2-F")
        println("finHeight = \(finHeight) ft")
        println("finThickness = \(finThickness) ft")
        println("finConductivity = \(finConductivity) BTU/hr-ft-F")
        
        // Set up equations for Thomas Algorithm:  cc(i) * T(i-1) + aa(i) * T(i) + bb(i) * T(i+1) = dd(i)
        
        var num = 2.0 * finCoefficient * deltaX * deltaX
        var denom = finThickness * finConductivity
        var phi = num / denom
        
        var aa = [Double](count:segments.count, repeatedValue: 0.0)
        var bb = [Double](count:segments.count, repeatedValue: 0.0)
        var cc = [Double](count:segments.count, repeatedValue: 0.0)
        var dd = [Double](count:segments.count, repeatedValue: 0.0)
        
        for var j = 1; j < numberOfSegments; j++ {
            if j == 1 {
                cc[j] = 0.0
                aa[j] = 3.0 + phi
                bb[j] = -1.0
                dd[j] = 2.0 * hotTemperature + phi * ambientTemperature
            }
            else if j == range {
                cc[j] = -1.0
                aa[j] = 1.0 + 2.0 * phi //+ finCoefficient * deltaX / finConductivity
                bb[j] = 0.0
                dd[j] = ambientTemperature * (2.0 * phi) // + finCoefficient * deltaX / finConductivity)
            }
            else {
                cc[j] = -1.0
                aa[j] = 2.0 + phi
                bb[j] = -1.0
                dd[j] = phi * ambientTemperature
            }
        }
        
        temperatures = thomasAlgorithm(range, aa: aa, bb: bb, cc: cc, dd: dd)
        
        var heatIn = 2.0 * finThickness * finConductivity * (hotTemperature - temperatures[1]) / deltaX
        var heatOut = 0.0
        for var i = 1; i < numberOfSegments; ++i {
            heatOut = heatOut + 2.0 * finCoefficient * deltaX * (temperatures[i] - ambientTemperature)
        }
        println("Heat In = \(heatIn), BTU/hr-ft")
        println("Heat Out = \(heatOut), BTU/hr-ft")
        
        let avgHeat = (heatIn + heatOut) / 2.0
        let yy = Double(round(100 * avgHeat) / 100)
        println("Avg Heat = \(yy), BTU/hr-ft")
        
        let finEfficiency = 100.0 * avgHeat / (2.0 * finCoefficient * finHeight * (hotTemperature - ambientTemperature))
        let zz = Double(round(100 * finEfficiency) / 100)
        println("Fin Efficiency = \(zz) %")
        
        self.heatTransferRateTextField.text = "\(yy)"
        self.finEfficiencyTextField.text = "\(zz)"
        
        // Update table
        
        profileArray = []
        
        for var j = 0; j < numberOfSegments; ++j {
            if j == 0 {
                segments[j].temperature = hotTemperature
            }
            else {
                segments[j].temperature = temperatures[j]
            }
            
            var y = Double(round(100 * segments[j].temperature) / 100)
            println("j = \(j), temperature = \(segments[j].temperature)")
            profileArray.append(["segmentNumber":"\(j)", "segmentTemp":"\(y)"])
        }
        println("\(profileArray.count) segments in array")

        self.tableView.reloadData()
    }
            
    // Thomas Algorithm for solving simultaneous linear equations in a tridiagonal matrix
    
        //The equations to be solved are of the form: cc(i) * x(i-1) + aa(i) * x(i) + bb(i) * x(i+1) = dd(i)
            // where x(i) are the values of the unknown array x.
    
    func thomasAlgorithm(range: Int, aa:[Double], bb:[Double], cc:[Double], dd:[Double]) -> [Double] {
        
        var xx = [Double](count:range + 1, repeatedValue: 0.0)
        var qq = [Double](count:range + 1, repeatedValue: 0.0)
        var ww = [Double](count:range + 1, repeatedValue: 0.0)
        var gg = [Double](count:range + 1, repeatedValue: 0.0)
        
        for var j = 1; j < range + 1; ++j {
            if j == 1 {
                ww[j] = aa[j]
                gg[j] = dd[j] / ww[j]
            }
            else {
                qq[j - 1] = bb[j - 1] / ww[j - 1]
                ww[j] = aa[j] - cc[j] * qq[j - 1]
                gg[j] = (dd[j] - cc[j] * gg[j - 1]) / ww[j]
            }
        }
        xx[range] = gg[range]
        
        for var i = range - 1; i > 0; i-- {
            xx[i] = gg[i] - qq[i] * xx[i + 1]
        }
        return xx
    }
    
}

