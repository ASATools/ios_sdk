//
//  ASATools+retentionRate.swift
//  ASATools
//
//  Created by Vladislav Dugnist on 9/20/22.
//

import Foundation

extension ASATools {
    private struct RetentionReport: Codable {
        var d1Opened: Bool = false
        var d1Synced: Bool = false
        var d7Opened: Bool = false
        var d7Synced: Bool = false
    }
    
    func syncRetentionRate() {
        var report = self.updatedRetentionReport()

        guard let parameters = self.retentionParameters(for: report) else {
            return
        }

        var request = URLRequest(url: URL(string: "https://asa.tools/api/rr")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.queue.async {
                guard let data = data,
                      let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
                      let status = responseJSON["status"] as? String,
                      status == "ok" else {
                          return
                      }
                
                if (parameters["day"] as! Int) == 1 {
                    report.d1Synced = true
                    self.saveRetentionReport(report: report)
                } else if (parameters["day"] as! Int) == 7 {
                    report.d7Synced = true
                    self.saveRetentionReport(report: report)
                }
            }
        }.resume()
    }
    
    private func retentionParameters(for report: RetentionReport) -> [String: AnyHashable]? {
        guard let token = self.apiToken else {
            return nil
        }
        
        guard let day: Int = {
            if report.d1Opened && !report.d1Synced {
                return 1
            } else if report.d7Opened && !report.d7Synced {
                return 7
            } else {
                return nil
            }
        }() else {
            return nil
        }
        
        return [
            "application_token": token,
            "user_id": self.userID,
            "day": day
        ]
    }
    
    private func updatedRetentionReport() -> RetentionReport {
        var report = self.storedRetentionReport()
        let days = Calendar.current.dateComponents([.day],
                                                   from: Date(timeIntervalSince1970: self.installDate),
                                                   to: Date()).day!

        if days == 1 && !report.d1Opened {
            report.d1Opened = true
            self.saveRetentionReport(report: report)
        } else if days == 7 && !report.d7Opened {
            report.d7Opened = true
            self.saveRetentionReport(report: report)
        }
        
        return report
    }
    
    private func storedRetentionReport() -> RetentionReport {
        if let data = UserDefaults.standard.data(forKey: ASATools.retentionRate),
           let report = try? JSONDecoder().decode(RetentionReport.self, from: data) {
            return report
        }
        
        let report = RetentionReport()
        self.saveRetentionReport(report: report)
        return report
    }
    
    private func saveRetentionReport(report: RetentionReport) {
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: ASATools.retentionRate)
        }
    }
}
