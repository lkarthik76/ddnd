//
//  RiskService.swift
//  ddnd-watch-app
//
//  Created by Karthikeyan Lakshminarayanan on 20/06/25.
//

import Foundation

class RiskService {
    let baseURL = "https://x3lurwrtk3.execute-api.us-east-1.amazonaws.com/prod"

    func fetchLatestRisk(completion: @escaping (String?, Error?) -> Void) {
        let user = UserSession.current
        var urlString = "\(baseURL)/getRisk?short_user_id=\(user.shortUserId)"
        print("Raw url string is:", urlString)
        if let driverId = user.driverId.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) {
            urlString += "&driver_id=\(driverId)"
        }

        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "InvalidURL", code: 0))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            print("💡 Raw response data: \(String(data: data!, encoding: .utf8) ?? "nil")")

            if let error = error {
                completion(nil, error)
                return
            }

            guard let data = data else {
                completion(nil, NSError(domain: "NoData", code: 0))
                return
            }

            do {
                if let result = try JSONSerialization.jsonObject(with: data)
                    as? [String: Any],
                    let risk = result["risk"] as? String
                {
                    completion(risk, nil)
                } else {
                    completion(nil, NSError(domain: "ParseError", code: 0))
                }
            } catch {
                completion(nil, error)
            }
        }.resume()
    }

}
