/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct VehicleSummary : Codable {
	let vin : String?
	let vehicleIdentifier : String?
	let modelName : String?
	let modelYear : String?
	let nickName : String?
	let generation : Int?
	let extColorCode : String?
	let trim : String?
	let enrollmentStatus : Int?
	let fatcAvailable : Int?
    let imagePath : ImagePath?
	let telematicsUnit : Int?
	let fuelType : Int?
	let colorName : String?
	let activationType : Int?
	let mileage : String?
	let dealerCode : String?
	let supportAdditionalDriver : Int?
	let customerType : Int?
	let linkStatus : Int?
	let projectCode : String?
	let headUnitDesc : String?
	let provStatus : String?
	let enrollmentSuppressionType : Int?
	let vehicleKey : String?

	enum CodingKeys: String, CodingKey {
        case imagePath = "imagePath"
		case vin = "vin"
		case vehicleIdentifier = "vehicleIdentifier"
		case modelName = "modelName"
		case modelYear = "modelYear"
		case nickName = "nickName"
		case generation = "generation"
		case extColorCode = "extColorCode"
		case trim = "trim"
		case enrollmentStatus = "enrollmentStatus"
		case fatcAvailable = "fatcAvailable"
		case telematicsUnit = "telematicsUnit"
		case fuelType = "fuelType"
		case colorName = "colorName"
		case activationType = "activationType"
		case mileage = "mileage"
		case dealerCode = "dealerCode"
		case supportAdditionalDriver = "supportAdditionalDriver"
		case customerType = "customerType"
		case linkStatus = "linkStatus"
		case projectCode = "projectCode"
		case headUnitDesc = "headUnitDesc"
		case provStatus = "provStatus"
		case enrollmentSuppressionType = "enrollmentSuppressionType"
		case vehicleKey = "vehicleKey"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		vin = try values.decodeIfPresent(String.self, forKey: .vin)
		vehicleIdentifier = try values.decodeIfPresent(String.self, forKey: .vehicleIdentifier)
		modelName = try values.decodeIfPresent(String.self, forKey: .modelName)
		modelYear = try values.decodeIfPresent(String.self, forKey: .modelYear)
		nickName = try values.decodeIfPresent(String.self, forKey: .nickName)
		generation = try values.decodeIfPresent(Int.self, forKey: .generation)
		extColorCode = try values.decodeIfPresent(String.self, forKey: .extColorCode)
		trim = try values.decodeIfPresent(String.self, forKey: .trim)
		enrollmentStatus = try values.decodeIfPresent(Int.self, forKey: .enrollmentStatus)
		fatcAvailable = try values.decodeIfPresent(Int.self, forKey: .fatcAvailable)
		telematicsUnit = try values.decodeIfPresent(Int.self, forKey: .telematicsUnit)
		fuelType = try values.decodeIfPresent(Int.self, forKey: .fuelType)
		colorName = try values.decodeIfPresent(String.self, forKey: .colorName)
		activationType = try values.decodeIfPresent(Int.self, forKey: .activationType)
		mileage = try values.decodeIfPresent(String.self, forKey: .mileage)
		dealerCode = try values.decodeIfPresent(String.self, forKey: .dealerCode)
		supportAdditionalDriver = try values.decodeIfPresent(Int.self, forKey: .supportAdditionalDriver)
		customerType = try values.decodeIfPresent(Int.self, forKey: .customerType)
		linkStatus = try values.decodeIfPresent(Int.self, forKey: .linkStatus)
		projectCode = try values.decodeIfPresent(String.self, forKey: .projectCode)
		headUnitDesc = try values.decodeIfPresent(String.self, forKey: .headUnitDesc)
		provStatus = try values.decodeIfPresent(String.self, forKey: .provStatus)
		enrollmentSuppressionType = try values.decodeIfPresent(Int.self, forKey: .enrollmentSuppressionType)
		vehicleKey = try values.decodeIfPresent(String.self, forKey: .vehicleKey)
        imagePath = try values.decodeIfPresent(ImagePath.self, forKey: .imagePath)
	}

}
