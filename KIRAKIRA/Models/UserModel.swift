//
//  UserModel.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/11.
//

import Foundation

struct UserProfile: Codable {
    let username: String
    let name: String
    let bio: String?
    let birthday: Date?
    let avatarID: String?
    let bannerID: String?
}
