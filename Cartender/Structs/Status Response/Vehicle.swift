/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Vehicle : Codable {
	let vin : String?
	let trim : Trim?
	let telematics : Int?
	let mileage : String?
	let mileageSyncDate : String?
	let exteriorColor : String?
	let exteriorColorCode : String?
	let fuelType : Int?
	let invDealerCode : String?
	let testVehicle : String?
	let supportedApps : [SupportedApps]?
	let activationType : Int?

	enum CodingKeys: String, CodingKey {

		case vin = "vin"
		case trim = "trim"
		case telematics = "telematics"
		case mileage = "mileage"
		case mileageSyncDate = "mileageSyncDate"
		case exteriorColor = "exteriorColor"
		case exteriorColorCode = "exteriorColorCode"
		case fuelType = "fuelType"
		case invDealerCode = "invDealerCode"
		case testVehicle = "testVehicle"
		case supportedApps = "supportedApps"
		case activationType = "activationType"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		vin = try values.decodeIfPresent(String.self, forKey: .vin)
		trim = try values.decodeIfPresent(Trim.self, forKey: .trim)
		telematics = try values.decodeIfPresent(Int.self, forKey: .telematics)
		mileage = try values.decodeIfPresent(String.self, forKey: .mileage)
		mileageSyncDate = try values.decodeIfPresent(String.self, forKey: .mileageSyncDate)
		exteriorColor = try values.decodeIfPresent(String.self, forKey: .exteriorColor)
		exteriorColorCode = try values.decodeIfPresent(String.self, forKey: .exteriorColorCode)
		fuelType = try values.decodeIfPresent(Int.self, forKey: .fuelType)
		invDealerCode = try values.decodeIfPresent(String.self, forKey: .invDealerCode)
		testVehicle = try values.decodeIfPresent(String.self, forKey: .testVehicle)
		supportedApps = try values.decodeIfPresent([SupportedApps].self, forKey: .supportedApps)
		activationType = try values.decodeIfPresent(Int.self, forKey: .activationType)
	}

}