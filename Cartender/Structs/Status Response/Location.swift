/* 
Copyright (c) 2021 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
struct Location : Codable {
	let coord : Coord?
	let head : Int?
	let speed : Speed?
	let accuracy : Accuracy?
	let syncDate : SyncDate?

	enum CodingKeys: String, CodingKey {

		case coord = "coord"
		case head = "head"
		case speed = "speed"
		case accuracy = "accuracy"
		case syncDate = "syncDate"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		coord = try values.decodeIfPresent(Coord.self, forKey: .coord)
		head = try values.decodeIfPresent(Int.self, forKey: .head)
		speed = try values.decodeIfPresent(Speed.self, forKey: .speed)
		accuracy = try values.decodeIfPresent(Accuracy.self, forKey: .accuracy)
		syncDate = try values.decodeIfPresent(SyncDate.self, forKey: .syncDate)
	}

}