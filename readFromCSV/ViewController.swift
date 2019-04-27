//
//  ViewController.swift
//  readFromCSV
//
//  Created by Lydia Kara on 25/04/2019.
//  Copyright © 2019 Lydia Kara. All rights reserved.
//

import UIKit
import CSV
import SQLite

class ViewController: UIViewController {

    let stream = InputStream(fileAtPath: "/Users/Lydia/Documents/year3/Final Project/zipa_final02/women-bra.csv")!
    var size = "string"
    
    //database connection
    var db: Connection!
    //table
    let braTable = Table("bra")
    //columns
    let cup = Expression<String>("cup")
    let bra = Expression<String>("bra")
    let bust = Expression<Int>("bust")
    let underbust = Expression<Int>("underbust")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do{
            //create file to store database on users device
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            //create file URL to store database
            //file name: Users, stored locally on users device with extension 'sqlite3'
            let fileUrl = documentDirectory.appendingPathComponent("garments").appendingPathExtension("sqlite3")
            
            //make a connection and create a database
            let database = try Connection(fileUrl.path)
            
            //connect this 'database' to Global database
            self.db = database
        } catch {
            print("Error creating Database")
        }
        
        testingCSV()
        createTable()
        printInConsole()
    }

    func createTable() {
        let createBraTable = braTable.create { (table) in
            table.column(self.cup)
            table.column(self.bra)
            table.column(self.bust)
            table.column(self.underbust)
            
        }
        
        do{
            try self.db.run(createBraTable)
            print("created bra table successfully")
        } catch {
            print("Error creating bra table")
        }
    }
    
    func testingCSV() {
        let csv = try! CSVReader(stream: stream, hasHeaderRow: true)

        while csv.next() != nil {
            do{
                try self.db.run(braTable.insert(self.cup <- csv["cup"]!, self.bra <- csv["bra"]!, self.bust <- Int(csv["bust"]!)!, self.underbust <- Int(csv["underbust"]!)!))
            } catch {
                print("error populating bra table")
            }
        }
        
    }
    
    func printInConsole() {
        do{
            let printBra = try db.prepare(self.braTable)
            for braTable in printBra {
                print("Cup : \(braTable[self.cup]), Bra: \(braTable[self.bra]), Bust (cm): \(braTable[self.bust]), Underbust (cm): \(braTable[self.underbust])")
            }
        } catch {
            print("error printing bra table")
        }
    }
    
    
    @IBOutlet weak var bustTextField: UITextField!
    @IBOutlet weak var underBustTextField: UITextField!
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var displaySize: UILabel!
    
    var tempBra = "test"
    var tempCup = "test"
    
    @IBAction func generateBra(_ sender: Any) {
        let userbust = bustTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let userUnderbust = underBustTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let tempBust = Int(userbust!)!
        let tempUnderbust = Int(userUnderbust!)!
        
        let braSize = queryBraTable(bustParam: tempBust, underBustParam: tempUnderbust)
        displaySize.text = braSize
    }
    
    
    
    
    func queryBraTable(bustParam: Int, underBustParam: Int) -> String {
        var returnInfo = "size not found"
        do{
            let braQuery = braTable.select(bra).where(underbust <= underBustParam).order(underbust.desc).limit(1)
            let cupQuery = braTable.select(cup).where(bust <= bustParam).order(bust.desc).limit(1)
    
            for braTable in try db.prepare(braQuery){
                tempBra = braTable[bra]
            }
            
            for braTable in try db.prepare(cupQuery){
                tempCup = braTable[cup]
            }
            returnInfo = "Your Bra Size is: \(tempBra) \(tempCup)"
        } catch {
            print("could not return bra")
        }
    
        return returnInfo
    }
    

}

