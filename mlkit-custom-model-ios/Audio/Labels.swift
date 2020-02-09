import Foundation

class Labels {
    
    private let data: [Label]
    
    init(url: URL = Bundle.main.url(forResource: "yamnet_class_map", withExtension: "csv")!) {
        
        let raw = try! String(contentsOf: url)

        var result: [Label] = []
        let rows = raw.components(separatedBy: "\n")
        for row in rows[1...] {
            let columns = row.components(separatedBy: ",")
            if columns.count == 3 {
                result.append(Label(index: Int(columns[0])!, text: columns[2]))
            }
        }
        data = result
    }
    
    func get(index: Int) -> Label? {
        return data.filter { $0.index == index }.first
    }
    
}

struct Label {
    let index: Int
    let text: String
}
