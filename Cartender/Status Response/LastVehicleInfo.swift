/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct LastVehicleInfo : Codable {
	let vehicleNickName : String?
	let preferredDealer : String?
	let customerType : Int?
	let enrollment : Enrollment?
	let activeDTC : ActiveDTC?
	let vehicleStatusRpt : VehicleStatusRpt?
	let location : Location?
	let financed : Bool?
	let financeRegistered : Bool?
	let linkStatus : Int?

	enum CodingKeys: String, CodingKey {

		case vehicleNickName = "vehicleNickName"
		case preferredDealer = "preferredDealer"
		case customerType = "customerType"
		case enrollment = "enrollment"
		case activeDTC = "activeDTC"
		case vehicleStatusRpt = "vehicleStatusRpt"
		case location = "location"
		case financed = "financed"
		case financeRegistered = "financeRegistered"
		case linkStatus = "linkStatus"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		vehicleNickName = try values.decodeIfPresent(String.self, forKey: .vehicleNickName)
		preferredDealer = try values.decodeIfPresent(String.self, forKey: .preferredDealer)
		customerType = try values.decodeIfPresent(Int.self, forKey: .customerType)
		enrollment = try values.decodeIfPresent(Enrollment.self, forKey: .enrollment)
		activeDTC = try values.decodeIfPresent(ActiveDTC.self, forKey: .activeDTC)
		vehicleStatusRpt = try values.decodeIfPresent(VehicleStatusRpt.self, forKey: .vehicleStatusRpt)
		location = try values.decodeIfPresent(Location.self, forKey: .location)
		financed = try values.decodeIfPresent(Bool.self, forKey: .financed)
		financeRegistered = try values.decodeIfPresent(Bool.self, forKey: .financeRegistered)
		linkStatus = try values.decodeIfPresent(Int.self, forKey: .linkStatus)
	}

}