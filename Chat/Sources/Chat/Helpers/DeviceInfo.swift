//
//  DeviceInfo.swift
//  Chat
//
//  Created by Andres Raigoza on 29/04/26.
//

import Foundation

struct DeviceInfo {
  static var language: String {
    let code = Locale.current.language.languageCode?.identifier ?? "en"
    return ["en", "es"].contains(code) ? code : "en"
  }
}
