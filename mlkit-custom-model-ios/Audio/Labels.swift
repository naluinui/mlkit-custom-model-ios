import Foundation

class Labels {
    
    private let data: [Int: String]
    
    init(url: URL = Bundle.main.url(forResource: "yamnet_class_map", withExtension: "csv")!) {

        let raw = try! String(contentsOf: url)
        let rows = raw.components(separatedBy: "\n")
        
        data = Dictionary(uniqueKeysWithValues: rows[1...]
            .map { $0.parse() }
            .compactMap { $0 })
    }
    
    func get(index i: Int) -> String? {
        return data[i]
    }
}


fileprivate let pattern = #"(?<id>[0-9]+),[^,]*,(?:"(?<t1>(?:[^"])*)"|(?<t2>[^,"\r]*))"#
fileprivate let regex = try! NSRegularExpression(pattern: pattern, options: [])

fileprivate extension String {
    func parse() -> (Int, String)? {
        if let match = regex.firstMatch(in: self),
            let idStr = match.string(withName: "id", in: self),
            let id = Int(idStr),
            let text = match.string(withName: "t1", in: self) ?? match.string(withName: "t2", in: self) {
            return (id, text)
        }
        return nil
    }
}

fileprivate extension NSTextCheckingResult {
    func string(withName name: String, in entireString: String) -> String? {
        if let r = Range(range(withName: name), in: entireString) {
            return String(entireString[r])
        }
        return nil
    }
}

fileprivate extension NSRegularExpression {
    func firstMatch(in s: String) -> NSTextCheckingResult? {
        let r = NSRange(s.startIndex..<s.endIndex, in: s)
        return firstMatch(in: s, options: [], range: r)
    }
}
