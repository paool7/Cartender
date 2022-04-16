/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Device : Codable {
	let launchType : String?
	let swVersion : String?
	let telematics : Telematics?
	let versionNum : String?
	let headUnitType : String?
	let hdRadio : String?
	let ampType : String?
	let modem : Modem?
	let headUnitName : String?
	let bluetoothRef : String?
	let headUnitDesc : String?

	enum CodingKeys: String, CodingKey {

		case launchType = "launchType"
		case swVersion = "swVersion"
		case telematics = "telematics"
		case versionNum = "versionNum"
		case headUnitType = "headUnitType"
		case hdRadio = "hdRadio"
		case ampType = "ampType"
		case modem = "modem"
		case headUnitName = "headUnitName"
		case bluetoothRef = "bluetoothRef"
		case headUnitDesc = "headUnitDesc"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		launchType = try values.decodeIfPresent(String.self, forKey: .launchType)
		swVersion = try values.decodeIfPresent(String.self, forKey: .swVersion)
		telematics = try values.decodeIfPresent(Telematics.self, forKey: .telematics)
		versionNum = try values.decodeIfPresent(String.self, forKey: .versionNum)
		headUnitType = try values.decodeIfPresent(String.self, forKey: .headUnitType)
		hdRadio = try values.decodeIfPresent(String.self, forKey: .hdRadio)
		ampType = try values.decodeIfPresent(String.self, forKey: .ampType)
		modem = try values.decodeIfPresent(Modem.self, forKey: .modem)
		headUnitName = try values.decodeIfPresent(String.self, forKey: .headUnitName)
		bluetoothRef = try values.decodeIfPresent(String.self, forKey: .bluetoothRef)
		headUnitDesc = try values.decodeIfPresent(String.self, forKey: .headUnitDesc)
	}

}