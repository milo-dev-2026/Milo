import UIKit
import SnapKit

// MARK: - 录音遮罩视图
class VoiceRecorderOverlay: UIView {

    // MARK: - UI 组件
    private let centerContainer = UIView()
    private let waveformContainer = UIView()
    private var waveformBars: [UIView] = []
    private let timerLabel = UILabel()
    private let hintLabel = UILabel()
    private let hintIcon = UIImageView()

    // MARK: - 状态
    private var isInCancelZone = false
    private var waveformTimer: Timer?
    private var barBaseHeights: [CGFloat] = []

    // 波形条数量
    private let barCount = 8

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        isUserInteractionEnabled = false

        // 中心容器
        centerContainer.backgroundColor = .systemBackground
        centerContainer.layer.cornerRadius = 16
        centerContainer.layer.shadowColor = UIColor.black.cgColor
        centerContainer.layer.shadowOpacity = 0.15
        centerContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        centerContainer.layer.shadowRadius = 12
        addSubview(centerContainer)

        centerContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(200))
            make.height.equalTo(ScreenAdapter.scaleH(160))
        }

        // 波形容器
        waveformContainer.backgroundColor = .clear
        centerContainer.addSubview(waveformContainer)

        waveformContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(24))
            make.centerX.equalToSuperview()
            make.width.equalTo(ScreenAdapter.scaleW(120))
            make.height.equalTo(ScreenAdapter.scaleH(50))
        }

        // 波形条
        let barWidth: CGFloat = 4
        let barSpacing: CGFloat = 6
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing

        for i in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = .themePrimary
            bar.layer.cornerRadius = barWidth / 2
            waveformContainer.addSubview(bar)
            waveformBars.append(bar)

            let baseHeight = CGFloat.random(in: 16...36)
            barBaseHeights.append(baseHeight)

            bar.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(CGFloat(i) * (barWidth + barSpacing))
                make.centerY.equalToSuperview()
                make.width.equalTo(barWidth)
                make.height.equalTo(baseHeight)
            }
        }

        // 居中波形容器对齐
        waveformContainer.snp.updateConstraints { make in
            make.width.equalTo(totalWidth)
        }

        // 录音时间标签
        timerLabel.font = ScreenAdapter.mediumFont(22)
        timerLabel.textColor = .label
        timerLabel.textAlignment = .center
        timerLabel.text = "00:00"
        centerContainer.addSubview(timerLabel)

        timerLabel.snp.makeConstraints { make in
            make.top.equalTo(waveformContainer.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.centerX.equalToSuperview()
        }

        // 底部提示
        let hintStack = UIStackView(arrangedSubviews: [hintIcon, hintLabel])
        hintStack.axis = .horizontal
        hintStack.alignment = .center
        hintStack.spacing = 4

        hintIcon.image = UIImage(systemName: "arrow.up")
        hintIcon.tintColor = .secondaryLabel
        hintIcon.contentMode = .scaleAspectFit

        hintLabel.font = ScreenAdapter.font(14)
        hintLabel.textColor = .secondaryLabel
        hintLabel.text = "上滑取消"
        hintLabel.textAlignment = .center

        addSubview(hintStack)

        hintStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(60))
            make.centerX.equalToSuperview()
        }

        hintIcon.snp.makeConstraints { make in
            make.width.height.equalTo(14)
        }
    }

    // MARK: - 显示/隐藏

    func show(in view: UIView) {
        view.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 出现动画：从中心缩放弹出
        centerContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        centerContainer.alpha = 0
        self.alpha = 0

        UIView.animate(withDuration: AnimationDuration.normal,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseOut) {
            self.alpha = 1
            self.centerContainer.alpha = 1
            self.centerContainer.transform = .identity
        }

        startWaveformAnimation()
    }

    func hide(completion: (() -> Void)? = nil) {
        stopWaveformAnimation()

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: .curveEaseIn) {
            self.alpha = 0
            self.centerContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - 状态更新

    /// 更新录音时长
    func updateDuration(_ duration: TimeInterval) {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    /// 更新取消区域状态
    func updateCancelState(isInCancelZone: Bool) {
        guard self.isInCancelZone != isInCancelZone else { return }
        self.isInCancelZone = isInCancelZone

        if isInCancelZone {
            // 进入取消区域
            hintIcon.image = UIImage(systemName: "xmark.circle.fill")
            hintIcon.tintColor = .systemRed
            hintLabel.text = "松开取消发送"
            hintLabel.textColor = .systemRed

            // 波形条变红
            UIView.animate(withDuration: 0.15) {
                self.waveformBars.forEach { $0.backgroundColor = .systemRed }
            }

            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.impactSoft()
            }
        } else {
            // 离开取消区域
            hintIcon.image = UIImage(systemName: "arrow.up")
            hintIcon.tintColor = .secondaryLabel
            hintLabel.text = "上滑取消"
            hintLabel.textColor = .secondaryLabel

            // 波形条恢复主题色
            UIView.animate(withDuration: 0.15) {
                self.waveformBars.forEach { $0.backgroundColor = .themePrimary }
            }

            if AnimationIntegration.shared.config.enableHapticFeedback {
                HapticManager.shared.impactLight()
            }
        }
    }

    // MARK: - 波形动画

    private func startWaveformAnimation() {
        guard AnimationIntegration.shared.config.enableListEntranceAnimation else { return }

        waveformTimer?.invalidate()
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            for (index, bar) in self.waveformBars.enumerated() {
                let baseHeight = self.barBaseHeights[index]
                let randomFactor = CGFloat.random(in: 0.4...1.6)
                let newHeight = max(6, min(46, baseHeight * randomFactor))

                UIView.animate(withDuration: 0.1,
                               delay: 0,
                               options: [.curveEaseInOut, .allowUserInteraction]) {
                    bar.snp.updateConstraints { make in
                        make.height.equalTo(newHeight)
                    }
                    bar.superview?.layoutIfNeeded()
                }
            }
        }
        RunLoop.main.add(waveformTimer!, forMode: .common)
    }

    private func stopWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
    }
}
