import UIKit
import SnapKit

class LockScreenVerifyViewController: UIViewController {

    enum Mode {
        case setPassword
        case verify
    }

    private let mode: Mode
    private var inputPassword = ""
    private var firstInput = ""
    private var errorCount = 0
    private let maxAttempts = 5
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dotsView = UIStackView()
    private var dots: [UIView] = []
    private var keypadButtons: [UIButton] = []

    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if mode == .verify, !LocalStore.shared.isAppLockEnabled {
            dismiss(animated: true)
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.isHidden = true

        titleLabel.font = ScreenAdapter.boldFont(22)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.text = mode == .setPassword ? "设置应用锁密码" : "请输入密码"

        subtitleLabel.font = ScreenAdapter.font(14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.text = mode == .setPassword ? "请输入6位数字密码" : ""

        dotsView.axis = .horizontal
        dotsView.spacing = ScreenAdapter.scaleW(16)
        dotsView.distribution = .fillEqually

        for _ in 0..<6 {
            let dot = UIView()
            dot.layer.cornerRadius = ScreenAdapter.scaleW(8)
            dot.layer.borderWidth = 1.5
            dot.layer.borderColor = UIColor.systemGray3.cgColor
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(ScreenAdapter.scaleW(16))
            }
            dotsView.addArrangedSubview(dot)
            dots.append(dot)
        }

        let keypad = createKeypad()

        view.addSubviews(titleLabel, subtitleLabel, dotsView, keypad)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(ScreenAdapter.scaleH(80))
            make.centerX.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(ScreenAdapter.scaleH(12))
            make.centerX.equalToSuperview()
        }

        dotsView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(ScreenAdapter.scaleH(40))
            make.centerX.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleW(16))
        }

        keypad.snp.makeConstraints { make in
            make.top.equalTo(dotsView.snp.bottom).offset(ScreenAdapter.scaleH(60))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(40))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(40))
            make.height.equalTo(ScreenAdapter.scaleH(280))
        }
    }

    private func createKeypad() -> UIView {
        let container = UIView()

        for i in 0..<12 {
            let btn = UIButton(type: .system)
            btn.titleLabel?.font = ScreenAdapter.font(28)
            btn.setTitleColor(.label, for: .normal)
            btn.layer.cornerRadius = ScreenAdapter.scaleW(40)
            btn.backgroundColor = .systemGray6
            btn.tag = i

            switch i {
            case 0...8:
                btn.setTitle("\(i + 1)", for: .normal)
            case 9:
                btn.setTitle("", for: .normal)
                btn.isEnabled = false
                btn.backgroundColor = .clear
            case 10:
                btn.setTitle("0", for: .normal)
            case 11:
                btn.setImage(UIImage(systemName: "delete.left"), for: .normal)
                btn.tintColor = .label
                btn.titleLabel?.font = ScreenAdapter.font(20)
                btn.backgroundColor = .clear
            default:
                break
            }

            btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            container.addSubview(btn)
            keypadButtons.append(btn)

            let row = i / 3
            let col = i % 3
            btn.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(CGFloat(row) * (ScreenAdapter.scaleH(60) + ScreenAdapter.scaleH(16)))
                make.leading.equalToSuperview().offset(CGFloat(col) * (ScreenAdapter.scaleW(60) + ScreenAdapter.scaleW(40)))
                make.width.equalTo(ScreenAdapter.scaleW(60))
                make.height.equalTo(ScreenAdapter.scaleH(60))
            }
        }
        return container
    }

    @objc private func keyTapped(_ sender: UIButton) {
        let tag = sender.tag

        if tag == 11 {
            if !inputPassword.isEmpty {
                inputPassword.removeLast()
                updateDots()
            }
        } else if tag == 9 {
            return
        } else {
            let digit = sender.title(for: .normal) ?? ""
            guard !digit.isEmpty, inputPassword.count < 6 else { return }
            inputPassword += digit
            updateDots()
            if inputPassword.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.verifyPassword()
                }
            }
        }
    }

    private func updateDots() {
        for (i, dot) in dots.enumerated() {
            if i < inputPassword.count {
                dot.backgroundColor = .themePrimary
                dot.layer.borderColor = UIColor.themePrimary.cgColor
            } else {
                dot.backgroundColor = .clear
                dot.layer.borderColor = UIColor.systemGray3.cgColor
            }
        }
    }

    private func shakeDots() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: dotsView.center.x - 10, y: dotsView.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: dotsView.center.x + 10, y: dotsView.center.y))
        dotsView.layer.add(animation, forKey: "shake")
    }

    private func verifyPassword() {
        switch mode {
        case .setPassword:
            if firstInput.isEmpty {
                firstInput = inputPassword
                inputPassword = ""
                updateDots()
                subtitleLabel.text = "请再次输入密码"
            } else {
                if firstInput == inputPassword {
                    LocalStore.shared.lockPassword = inputPassword
                    LocalStore.shared.isAppLockEnabled = true
                    AppUtility.showToast("应用锁已开启")
                    navigationController?.popViewController(animated: true)
                } else {
                    AppUtility.showToast("两次密码不一致")
                    shakeDots()
                    inputPassword = ""
                    firstInput = ""
                    updateDots()
                    subtitleLabel.text = "请输入6位数字密码"
                }
            }
        case .verify:
            if inputPassword == LocalStore.shared.lockPassword {
                dismiss(animated: true)
            } else {
                errorCount += 1
                let remaining = maxAttempts - errorCount
                if remaining > 0 {
                    AppUtility.showToast("密码错误，还可尝试\(remaining)次")
                    shakeDots()
                } else {
                    AppUtility.showToast("密码错误次数过多，请稍后再试")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        self?.dismiss(animated: true)
                    }
                }
                inputPassword = ""
                updateDots()
            }
        }
    }
}
