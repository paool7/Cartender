import Foundation

struct ActionError : Codable {
	let status : Status?

	enum CodingKeys: String, CodingKey {
		case status = "status"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		status = try values.decodeIfPresent(Status.self, forKey: .status)
	}

}
