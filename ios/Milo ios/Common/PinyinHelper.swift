import Foundation

// MARK: - 拼音首字母（带缓存，避免每次重建分组都做 CFStringTransform 造成卡顿）
enum PinyinHelper {

    private static let cache = NSCache<NSString, NSString>()
    private static let lock = NSLock()

    /// 取名称首字母（英文直接大写，中文转拼音取首字母，其他归入 #）
    static func firstLetter(of name: String) -> String {
        guard let first = name.first else { return "#" }
        if first.isASCII, first.isLetter {
            return String(first).uppercased()
        }
        let key = String(first) as NSString
        lock.lock()
        if let cached = cache.object(forKey: key) {
            lock.unlock()
            return cached as String
        }
        lock.unlock()

        var result = "#"
        let mutable = NSMutableString(string: String(first)) as CFMutableString
        if CFStringTransform(mutable, nil, kCFStringTransformToLatin, false),
           CFStringTransform(mutable, nil, kCFStringTransformStripDiacritics, false),
           let ch = (mutable as String).first, ch.isASCII, ch.isLetter {
            result = String(ch).uppercased()
        }

        cache.setObject(result as NSString, forKey: key)
        return result
    }

    /// 按首字母分组并排序（英文按字母，其余归 # 末尾）
    static func sections<T>(_ items: [T], name: (T) -> String) -> [(letter: String, items: [T])] {
        var buckets: [String: [T]] = [:]
        buckets.reserveCapacity(30)
        for item in items {
            buckets[firstLetter(of: name(item)), default: []].append(item)
        }
        return buckets.keys.sorted { lhs, rhs in
            if lhs == "#" { return false }
            if rhs == "#" { return true }
            return lhs < rhs
        }.map { letter in
            (letter: letter, items: buckets[letter]?.sorted { name($0) < name($1) } ?? [])
        }
    }
}
