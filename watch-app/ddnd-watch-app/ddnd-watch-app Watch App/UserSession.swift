//
//  UserSession.swift
//  ddnd-watch-app
//
//  Created by Karthikeyan Lakshminarayanan on 20/06/25.
//

import Foundation

struct UserSession {
    var shortUserId: String
    var driverId: String

    static let current = UserSession(
        shortUserId: "1234567890",                   // default short_user_id
        driverId: UUID().uuidString                 // default driver_id
    )
}
