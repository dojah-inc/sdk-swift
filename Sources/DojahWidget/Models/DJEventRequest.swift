//
//  DJEventRequest.swift
//
//
//  Created by Isaac Iniongun on 07/12/2023.
//

import Foundation

struct DJEventRequest: Codable {
    let name: DJEventName
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case name = "event_name"
        case value = "event_value"
    }
}
