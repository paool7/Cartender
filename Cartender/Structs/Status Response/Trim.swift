/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Trim : Codable {
	let modelYear : String?
	let salesModelCode : String?
	let optionGroupCode : String?
	let modelName : String?
	let factoryCode : String?
	let projectCode : String?
	let trimName : String?
	let driveType : String?
	let transmissionType : String?
	let ivrCategory : String?
	let btSeriesCode : String?

	enum CodingKeys: String, CodingKey {

		case modelYear = "modelYear"
		case salesModelCode = "salesModelCode"
		case optionGroupCode = "optionGroupCode"
		case modelName = "modelName"
		case factoryCode = "factoryCode"
		case projectCode = "projectCode"
		case trimName = "trimName"
		case driveType = "driveType"
		case transmissionType = "transmissionType"
		case ivrCategory = "ivrCategory"
		case btSeriesCode = "btSeriesCode"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		modelYear = try values.decodeIfPresent(String.self, forKey: .modelYear)
		salesModelCode = try values.decodeIfPresent(String.self, forKey: .salesModelCode)
		optionGroupCode = try values.decodeIfPresent(String.self, forKey: .optionGroupCode)
		modelName = try values.decodeIfPresent(String.self, forKey: .modelName)
		factoryCode = try values.decodeIfPresent(String.self, forKey: .factoryCode)
		projectCode = try values.decodeIfPresent(String.self, forKey: .projectCode)
		trimName = try values.decodeIfPresent(String.self, forKey: .trimName)
		driveType = try values.decodeIfPresent(String.self, forKey: .driveType)
		transmissionType = try values.decodeIfPresent(String.self, forKey: .transmissionType)
		ivrCategory = try values.decodeIfPresent(String.self, forKey: .ivrCategory)
		btSeriesCode = try values.decodeIfPresent(String.self, forKey: .btSeriesCode)
	}

}