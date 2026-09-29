//
//  RobotModels.swift
//  Milo
//
//  机器人模块 - 数据模型
//

import Foundation
import UIKit

// MARK: - 机器人指令模型
struct RobotCommand: Codable {
    let name: String
    let desc: String
    let icon: String
}

// MARK: - 机器人模型
struct Robot: Codable {
    let id: String
    let name: String
    let avatar: String
    let description: String
    let category: String
    var isAdded: Bool
    let commands: [RobotCommand]

    enum CodingKeys: String, CodingKey {
        case id, name, avatar, description, category, isAdded, commands
    }
}

// MARK: - 机器人消息模型（聊天用）
struct RobotMessage {
    let messageID: String
    let content: String
    let isFromMe: Bool
    let timestamp: TimeInterval

    init(messageID: String = UUID().uuidString, content: String, isFromMe: Bool, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.messageID = messageID
        self.content = content
        self.isFromMe = isFromMe
        self.timestamp = timestamp
    }

    var timeString: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 机器人分类
enum RobotCategory: String, Codable {
    case utility = "工具"
    case life = "生活"
    case entertainment = "娱乐"
    case study = "学习"
}

// MARK: - 模拟数据
extension Robot {
    /// 模拟机器人列表数据
    static let mockRobots: [Robot] = [
        Robot(
            id: "robot_smart_assistant",
            name: "智能助手",
            avatar: "🤖",
            description: "你的全能智能助手，解答各种问题",
            category: RobotCategory.utility.rawValue,
            isAdded: false,
            commands: [
                RobotCommand(name: "问问题", desc: "有什么不懂的都可以问我", icon: "message.fill"),
                RobotCommand(name: "查资料", desc: "帮你搜索各种资料", icon: "magnifyingglass"),
                RobotCommand(name: "写文案", desc: "帮你生成各种文案", icon: "pencil.line")
            ]
        ),
        Robot(
            id: "robot_translator",
            name: "翻译官",
            avatar: "🌐",
            description: "支持中英日韩等多语言互译",
            category: RobotCategory.utility.rawValue,
            isAdded: false,
            commands: [
                RobotCommand(name: "翻译", desc: "输入文字即可翻译", icon: "character.bubble"),
                RobotCommand(name: "中英互译", desc: "中文英文互译", icon: "globe"),
                RobotCommand(name: "日韩翻译", desc: "日语韩语翻译", icon: "translate")
            ]
        ),
        Robot(
            id: "robot_weather",
            name: "天气小助手",
            avatar: "🌤️",
            description: "实时天气查询，7天天气预报",
            category: RobotCategory.life.rawValue,
            isAdded: true,
            commands: [
                RobotCommand(name: "今天天气", desc: "查询今日天气", icon: "sun.max.fill"),
                RobotCommand(name: "一周天气", desc: "查看7天天气预报", icon: "calendar"),
                RobotCommand(name: "空气质量", desc: "查询空气质量指数", icon: "wind")
            ]
        ),
        Robot(
            id: "robot_reminder",
            name: "提醒小助手",
            avatar: "⏰",
            description: "帮你管理日程，准时提醒",
            category: RobotCategory.life.rawValue,
            isAdded: false,
            commands: [
                RobotCommand(name: "设置提醒", desc: "创建新的提醒事项", icon: "bell.fill"),
                RobotCommand(name: "我的提醒", desc: "查看所有提醒", icon: "list.bullet"),
                RobotCommand(name: "每日计划", desc: "查看今日计划", icon: "checklist")
            ]
        ),
        Robot(
            id: "robot_accountant",
            name: "记账助手",
            avatar: "💰",
            description: "轻松记账，智能分析收支",
            category: RobotCategory.life.rawValue,
            isAdded: false,
            commands: [
                RobotCommand(name: "记一笔", desc: "快速记录一笔收支", icon: "plus.circle.fill"),
                RobotCommand(name: "本月账单", desc: "查看本月收支明细", icon: "chart.pie.fill"),
                RobotCommand(name: "统计分析", desc: "收支统计与分析", icon: "chart.bar.fill")
            ]
        ),
        Robot(
            id: "robot_joker",
            name: "段子手",
            avatar: "🎭",
            description: "每天给你讲笑话，开心每一天",
            category: RobotCategory.entertainment.rawValue,
            isAdded: true,
            commands: [
                RobotCommand(name: "讲个笑话", desc: "来一个笑话", icon: "face.smiling"),
                RobotCommand(name: "冷笑话", desc: "来一个冷笑话", icon: "snowflake"),
                RobotCommand(name: "脑筋急转弯", desc: "猜一个脑筋急转弯", icon: "lightbulb")
            ]
        )
    ]
}
