//
//  UserModel.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/11.
//

struct User {
	let uid: String
	let uuid: String
	let email: String
	let roles: [String]
	let profile: UserProfile
	let invitationCode: String
}

struct UserProfile {
	let username: String
	let name: String
	let gender: String
	let avatar: String
}
