/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct VehicleStatus : Codable {
	let climate : Climate?
	let doorLock : Bool?
	let doorStatus : DoorStatus?
	let evStatus : EvStatus?
	let tirePressure : TirePressure?
	let dateTime : DateTime?
	let syncDate : SyncDate?
	let batteryStatus : BatteryStatus?
	let sleepMode : Bool?

	enum CodingKeys: String, CodingKey {
		case climate = "climate"
		case doorLock = "doorLock"
		case doorStatus = "doorStatus"
		case evStatus = "evStatus"
		case tirePressure = "tirePressure"
		case dateTime = "dateTime"
		case syncDate = "syncDate"
		case batteryStatus = "batteryStatus"
		case sleepMode = "sleepMode"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		climate = try values.decodeIfPresent(Climate.self, forKey: .climate)
		doorLock = try values.decodeIfPresent(Bool.self, forKey: .doorLock)
		doorStatus = try values.decodeIfPresent(DoorStatus.self, forKey: .doorStatus)
		evStatus = try values.decodeIfPresent(EvStatus.self, forKey: .evStatus)
		tirePressure = try values.decodeIfPresent(TirePressure.self, forKey: .tirePressure)
		dateTime = try values.decodeIfPresent(DateTime.self, forKey: .dateTime)
		syncDate = try values.decodeIfPresent(SyncDate.self, forKey: .syncDate)
		batteryStatus = try values.decodeIfPresent(BatteryStatus.self, forKey: .batteryStatus)
		sleepMode = try values.decodeIfPresent(Bool.self, forKey: .sleepMode)
	}

}
