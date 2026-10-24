//
//  FontSizeSettingViewController.swift
//  Milo
//
//  字体大小设置 - 滑块调节并实时预览
//

import UIKit
import SnapKit

class FontSizeSettingViewController: UIViewController {

    // MARK: - 常量
    private let minScale: Float = 0.8
    private let maxScale: Float = 1.4
    private let step: Float = 0.1
    private let baseFontSize: CGFloat = 17

    // MARK: - UI
    private let previewLabel = UILabel()
    private let slider = UISlider()
    private let minLabel = UILabel()
    private let maxLabel = UILabel()
    private let scaleLabel = UILabel()
    private let saveButton = UIButton(type: .system)

    private var currentScale: Float = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        currentScale = UserDefaults.standard.object(forKey: "app_font_scale") as? Float ?? 1.0
        setupUI()
        updatePreview()
    }

    // MARK: - 布局
    private func setupUI() {
        title = "字体大小"
        view.backgroundColor = .themeBackground

        // 预览标签
        previewLabel.text = "预览文字"
        previewLabel.textColor = .themeTextPrimary
        previewLabel.textAlignment = .center
        previewLabel.numberOfLines = 0
        view.addSubview(previewLabel)
        previewLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-ScreenAdapter.scaleH(80))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(32))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(32))
        }

        // 当前比例
        scaleLabel.textColor = .themeTextSecondary
        scaleLabel.font = ThemeFont.caption(13)
        scaleLabel.textAlignment = .center
        view.addSubview(scaleLabel)
        scaleLabel.snp.makeConstraints { make in
            make.top.equalTo(previewLabel.snp.bottom).offset(ScreenAdapter.scaleH(20))
            make.centerX.equalToSuperview()
        }

        // 滑块
        slider.minimumValue = minScale
        slider.maximumValue = maxScale
        slider.value = currentScale
        slider.tintColor = .themeColorPrimary
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        view.addSubview(slider)
        slider.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(48))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(48))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(120))
            make.height.equalTo(ScreenAdapter.scaleH(40))
        }

        // 最小值标签
        minLabel.text = "A"
        minLabel.font = ThemeFont.body(14)
        minLabel.textColor = .themeTextSecondary
        minLabel.textAlignment = .center
        view.addSubview(minLabel)
        minLabel.snp.makeConstraints { make in
            make.trailing.equalTo(slider.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalTo(slider)
            make.width.equalTo(ScreenAdapter.scaleW(24))
        }

        // 最大值标签
        maxLabel.text = "A"
        maxLabel.font = ThemeFont.body(22)
        maxLabel.textColor = .themeTextSecondary
        maxLabel.textAlignment = .center
        view.addSubview(maxLabel)
        maxLabel.snp.makeConstraints { make in
            make.leading.equalTo(slider.snp.trailing).offset(ScreenAdapter.scaleW(8))
            make.centerY.equalTo(slider)
            make.width.equalTo(ScreenAdapter.scaleW(24))
        }

        // 保存按钮
        saveButton.setTitle("保存", for: .normal)
        saveButton.titleLabel?.font = ThemeFont.buttonLarge(16)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .themeColorPrimary
        saveButton.layer.cornerRadius = ScreenAdapter.scaleW(10)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(20))
            make.height.equalTo(ScreenAdapter.scaleH(48))
        }
    }

    // MARK: - 滑块事件
    @objc private func sliderChanged(_ sender: UISlider) {
        let stepped = (sender.value / step).rounded() * step
        sender.value = stepped
        currentScale = stepped
        updatePreview()
    }

    private func updatePreview() {
        previewLabel.font = ScreenAdapter.font(baseFontSize * CGFloat(currentScale))
        scaleLabel.text = String(format: "%.0f%%", currentScale * 100)
    }

    // MARK: - 保存
    @objc private func saveTapped() {
        UserDefaults.standard.set(currentScale, forKey: "app_font_scale")
        NotificationCenter.default.post(name: Notification.Name("FontSizeChanged"), object: nil)
        AppUtility.showToast("已保存")
        navigationController?.popViewController(animated: true)
    }
}
