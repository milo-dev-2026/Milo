//
//  RobotManager.swift
//  Milo
//
//  机器人模块 - 管理器
//  单例管理：已添加机器人列表、添加/删除、本地持久化、模拟回复
//

import Foundation
import UIKit

// MARK: - 机器人管理器
final class RobotManager {

    // MARK: - 单例
    static let shared = RobotManager()
    private init() {
        loadAddedRobots()
    }

    // MARK: - 存储键
    private let addedRobotsKey = "robot_added_ids"

    // MARK: - 数据
    /// 所有机器人（包含模拟数据）
    private var allRobots: [Robot] = Robot.mockRobots

    /// 已添加的机器人ID列表
    private var addedRobotIDs: Set<String> = []

    // MARK: - 公共属性

    /// 获取所有机器人
    var robots: [Robot] {
        return allRobots.map { robot in
            var mutableRobot = robot
            mutableRobot.isAdded = addedRobotIDs.contains(robot.id)
            return mutableRobot
        }
    }

    /// 获取已添加的机器人
    var myRobots: [Robot] {
        return robots.filter { $0.isAdded }
    }

    // MARK: - 公共方法

    /// 添加机器人
    func addRobot(_ robotId: String) {
        addedRobotIDs.insert(robotId)
        saveAddedRobots()
    }

    /// 移除机器人
    func removeRobot(_ robotId: String) {
        addedRobotIDs.remove(robotId)
        saveAddedRobots()
    }

    /// 检查机器人是否已添加
    func isRobotAdded(_ robotId: String) -> Bool {
        return addedRobotIDs.contains(robotId)
    }

    /// 根据ID获取机器人
    func getRobot(by id: String) -> Robot? {
        guard let index = allRobots.firstIndex(where: { $0.id == id }) else { return nil }
        var robot = allRobots[index]
        robot.isAdded = addedRobotIDs.contains(robot.id)
        return robot
    }

    /// 搜索机器人
    func searchRobots(keyword: String) -> [Robot] {
        let lowerKeyword = keyword.lowercased()
        return robots.filter { robot in
            robot.name.lowercased().contains(lowerKeyword)
            || robot.description.lowercased().contains(lowerKeyword)
            || robot.category.lowercased().contains(lowerKeyword)
        }
    }

    // MARK: - 机器人回复模拟

    /// 根据机器人ID和用户消息生成回复
    func generateReply(for robotId: String, message: String) -> String {
        guard let robot = getRobot(by: robotId) else {
            return "抱歉，我暂时无法回复。"
        }

        let lowerMessage = message.lowercased()

        // 根据机器人类型生成不同回复
        switch robotId {
        case "robot_smart_assistant":
            return generateSmartAssistantReply(message: lowerMessage, originalMessage: message)
        case "robot_translator":
            return generateTranslatorReply(message: message)
        case "robot_weather":
            return generateWeatherReply(message: lowerMessage, originalMessage: message)
        case "robot_reminder":
            return generateReminderReply(message: lowerMessage, originalMessage: message)
        case "robot_accountant":
            return generateAccountantReply(message: lowerMessage, originalMessage: message)
        case "robot_joker":
            return generateJokeReply(message: lowerMessage)
        default:
            return generateDefaultReply(robotName: robot.name, message: message)
        }
    }

    // MARK: - 各机器人回复逻辑

    private func generateSmartAssistantReply(message: String, originalMessage: String) -> String {
        if message.contains("你好") || message.contains("hi") || message.contains("hello") {
            return "你好呀！我是智能助手，有什么可以帮你的吗？😊"
        }
        if message.contains("谢谢") || message.contains("感谢") {
            return "不客气，能帮到你我很开心～"
        }
        if message.contains("时间") || message.contains("几点") {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "现在是 \(formatter.string(from: Date())) 哦。"
        }
        if message.contains("日期") || message.contains("今天") {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日 EEEE"
            return "今天是 \(formatter.string(from: Date()))。"
        }
        // 默认智能回复
        let replies = [
            "关于「\(originalMessage)」这个问题，让我想想...嗯，我觉得可以从多个角度来思考。你能告诉我更多细节吗？",
            "好的，我理解你的意思了。关于「\(originalMessage)」，我可以给你一些建议，你想了解哪方面呢？",
            "这是个好问题！「\(originalMessage)」确实值得深入探讨。让我帮你分析一下～",
            "收到！关于「\(originalMessage)」，我正在为你整理相关信息，请稍等片刻...",
            "嗯嗯，我明白了。你说的「\(originalMessage)」很有意思，能再详细说说你的想法吗？"
        ]
        return replies.randomElement() ?? "我收到你的消息啦：\(originalMessage)"
    }

    private func generateTranslatorReply(message: String) -> String {
        // 简单模拟翻译
        if message.contains("翻译") || message.contains("英文") || message.contains("英语") {
            return "好的，请输入你想翻译的内容，我会帮你翻译成英文～"
        }
        if message.contains("日语") || message.contains("日文") {
            return "はい、日本語に翻訳しますよ～ 请输入内容吧！"
        }
        if message.contains("韩语") || message.contains("韩文") {
            return "네, 한국어로 번역해 드릴게요～ 请输入内容吧！"
        }
        // 模拟中英互译
        let isChinese = message.contains { $0.isCJK }
        if isChinese {
            let mockTranslations = [
                "这是翻译结果：This is the translated content.",
                "翻译结果如下：Here is the translation for you.",
                "英文翻译：The translated text is shown above."
            ]
            return mockTranslations.randomElement() ?? "翻译完成：\(message) (English)"
        } else {
            return "翻译结果：这是翻译成中文的内容。"
        }
    }

    private func generateWeatherReply(message: String, originalMessage: String) -> String {
        if message.contains("今天") || message.contains("天气") {
            return """
            📍 北京市 今日天气
            🌤️ 多云转晴
            🌡️ 温度：18°C ~ 26°C
            💨 风力：东南风 3级
            💧 湿度：45%
            👕 穿衣建议：薄外套即可
            """
        }
        if message.contains("明天") || message.contains("次日") {
            return """
            📍 北京市 明日天气预报
            ☀️ 晴
            🌡️ 温度：19°C ~ 27°C
            💨 风力：南风 2级
            🌞 紫外线：中等
            """
        }
        if message.contains("一周") || message.contains("7天") || message.contains("星期") {
            return """
            📅 未来7天天气预报：
            周一：多云 18~26°C
            周二：晴 19~27°C
            周三：晴转多云 20~28°C
            周四：小雨 17~23°C
            周五：阴 16~22°C
            周六：晴 18~25°C
            周日：晴 19~26°C
            """
        }
        if message.contains("空气") || message.contains("aqi") || message.contains("质量") {
            return """
            🌬️ 空气质量指数
            AQI：68（良）
            PM2.5：45 μg/m³
            PM10：72 μg/m³
            💡 空气质量不错，适合户外活动～
            """
        }
        return "想了解什么天气呢？可以问我「今天天气」「一周天气」「空气质量」哦～"
    }

    private func generateReminderReply(message: String, originalMessage: String) -> String {
        if message.contains("设置") || message.contains("新建") || message.contains("添加") {
            return "好的，你想设置什么提醒呢？比如：\n• \"明天下午3点开会\"\n• \"每天早上7点起床\"\n• \"下周三生日提醒\""
        }
        if message.contains("我的") || message.contains("列表") || message.contains("所有") {
            return """
            📋 你的提醒列表：
            1. 🔔 明天 09:00 - 团队周会
            2. 🔔 明天 14:30 - 项目评审
            3. 🔔 每天 07:00 - 早起打卡
            4. 🔔 每周一 10:00 - 周报提交
            """
        }
        if message.contains("今天") || message.contains("今日") {
            return """
            📅 今日提醒：
            • 09:00 - 团队周会
            • 14:30 - 项目评审
            • 18:00 - 健身锻炼
            今天共有 3 个提醒，加油！💪
            """
        }
        return "我是提醒小助手～ 你可以对我说：\n• \"设置提醒\"\n• \"我的提醒\"\n• \"今天的提醒\""
    }

    private func generateAccountantReply(message: String, originalMessage: String) -> String {
        if message.contains("记一笔") || message.contains("记账") || message.contains("支出") || message.contains("收入") {
            return "好的，请告诉我金额和类别，比如：\n• \"支出 30 午餐\"\n• \"收入 5000 工资\"\n• \"花费 100 打车\""
        }
        if message.contains("本月") || message.contains("这个月") || message.contains("账单") {
            return """
            📊 本月账单概览
            💰 总收入：¥8,500.00
            💸 总支出：¥3,280.00
            💵 结余：¥5,220.00

            📈 支出分类：
            • 餐饮：¥860 (26.2%)
            • 交通：¥320 (9.8%)
            • 购物：¥1,200 (36.6%)
            • 娱乐：¥450 (13.7%)
            • 其他：¥450 (13.7%)
            """
        }
        if message.contains("统计") || message.contains("分析") || message.contains("报表") {
            return """
            📈 收支分析报告
            ─────────────
            本月较上月：
            • 收入 ↑ 5.2%
            • 支出 ↓ 8.3%
            • 结余 ↑ 15.6%

            💡 省钱小贴士：
            本月餐饮支出较上月减少了12%，继续保持哦～
            """
        }
        return "我是记账助手～ 你可以对我说：\n• \"记一笔\"\n• \"本月账单\"\n• \"统计分析\""
    }

    private func generateJokeReply(message: String) -> String {
        if message.contains("笑话") || message.contains("讲个") || message.contains("来一个") {
            let jokes = [
                "为什么程序员总是分不清万圣节和圣诞节？因为 Oct 31 = Dec 25。🎃🎄",
                "一只蜗牛爬上了苹果树，苹果们很惊讶：你是谁？蜗牛说：我是来吃苹果的。苹果们笑了：你连壳都背不动，还吃苹果？蜗牛淡定地说：我分期付款。🐌🍎",
                "医生：你这病，治的话需要十万。病人：医生，我只有五万。医生：那好，我们各退一步，我给你治一半。病人：...",
                "我问我爸：爸，我是不是你亲生的？我爸：你再不好好学习，就不是了。😂",
                "程序员的老婆让他去买菜：\"去买一斤包子，如果有卖西瓜的，买一个西瓜回来。\" 程序员回来了，手里拎着一个包子。老婆问：怎么只买了一个包子？程序员说：因为看到卖西瓜的了。🍉",
                "老师：小明，你知道为什么闪电总是比雷声快吗？小明：因为眼睛长在耳朵前面！👀👂",
                "我女朋友让我去买口红，我问她要什么色号，她说：\"随便\"。然后我随便买了一支，她现在已经三天没跟我说话了。💄😅",
                "一只企鹅去北极找北极熊玩，走了十年才走到一半，突然想起家里门没关，又走了十年回去关门，然后又走了二十年到北极。企鹅敲门：北极熊北极熊，我来找你玩了！北极熊说：不玩。🐧🐻‍❄️"
            ]
            return jokes.randomElement() ?? "哈哈，让我再想想新段子～"
        }
        if message.contains("冷笑话") || message.contains("冷") {
            let coldJokes = [
                "为什么冰淇淋会唱歌？因为它有冰淇淋勺（歌）。🍦",
                "什么动物最容易被贴在墙上？海豹（海报）。🦭",
                "为什么蘑菇被邀请去所有派对？因为他是个 fun-gi（fungi 真菌）。🍄",
                "我以前觉得我一无所有，直到我连WiFi都断了... 才发现我真的一无所有。📶😢",
                "为什么数学书总是很忧郁？因为它有太多的问题。📕😔"
            ]
            return coldJokes.randomElement() ?? "嘿嘿，冷到了吧～"
        }
        if message.contains("脑筋急转弯") || message.contains("猜") {
            let riddles = [
                "问：什么东西越洗越脏？\n答：水！💧",
                "问：什么门永远关不上？\n答：球门！⚽",
                "问：什么路最窄？\n答：冤家路窄！😆",
                "问：什么东西有头无脚？\n答：砖头！🧱",
                "问：什么动物最容易摔倒？\n答：狐狸，因为它很狡猾（脚滑）！🦊"
            ]
            return riddles.randomElement() ?? "让我再想想新的脑筋急转弯～"
        }
        return "我是段子手，来逗你开心的！😄\n你可以对我说：\n• \"讲个笑话\"\n• \"冷笑话\"\n• \"脑筋急转弯\""
    }

    private func generateDefaultReply(robotName: String, message: String) -> String {
        let replies = [
            "你好！我是\(robotName)，很高兴为你服务～",
            "收到你的消息啦：「\(message)」",
            "嗯嗯，我正在思考怎么回复你...",
            "我是\(robotName)，有什么可以帮你的吗？",
            "好的好的，我知道啦～"
        ]
        return replies.randomElement() ?? "我是\(robotName)，收到你的消息了。"
    }

    // MARK: - 本地持久化

    private func saveAddedRobots() {
        let ids = Array(addedRobotIDs)
        UserDefaults.standard.set(ids, forKey: addedRobotsKey)
    }

    private func loadAddedRobots() {
        if let ids = UserDefaults.standard.array(forKey: addedRobotsKey) as? [String] {
            addedRobotIDs = Set(ids)
        } else {
            // 首次使用，默认添加一些机器人
            addedRobotIDs = ["robot_weather", "robot_joker"]
            saveAddedRobots()
        }
    }
}

// MARK: - Character 扩展（判断中日韩文字）
extension Character {
    var isCJK: Bool {
        guard let scalar = self.unicodeScalars.first else { return false }
        return (0x4E00...0x9FFF).contains(scalar.value) // 中文
            || (0x3040...0x30FF).contains(scalar.value) // 日文平假名片假名
            || (0xAC00...0xD7AF).contains(scalar.value) // 韩文
    }
}
