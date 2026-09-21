import UIKit
import SnapKit
import Kingfisher
import Photos
import UniformTypeIdentifiers

// MARK: - 笔记编辑页
class NoteEditViewController: UIViewController {
    
    private var note: NoteEntity?
    var onSave: ((NoteEntity) -> Void)?
    var onDelete: ((String) -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let toolbarView = UIView()
    private var autoSaveTimer: Timer?
    
    // 工具栏按钮
    private let titleBtn = UIButton(type: .system)
    private let textBtn = UIButton(type: .system)
    private let imageBtn = UIButton(type: .system)
    private let videoBtn = UIButton(type: .system)
    private let locationBtn = UIButton(type: .system)
    
    private var blocks: [NoteBlock] = []
    
    init(note: NoteEntity? = nil) {
        self.note = note
        self.blocks = note?.blocks ?? []
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupToolbar()
        renderBlocks()
        startAutoSave()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autoSaveTimer?.invalidate()
        autoSave()
    }
    
    private func setupUI() {
        title = note == nil ? "新建笔记" : "编辑笔记"
        view.backgroundColor = .themeBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(saveAndDismiss)
        )
        
        if note != nil {
            let deleteBtn = UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(deleteNote)
            )
            navigationItem.leftBarButtonItem = deleteBtn
        }
        
        // 滚动区域
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(50))
        }
        
        // 内容栈
        contentStack.axis = .vertical
        contentStack.spacing = ScreenAdapter.scaleH(8)
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
            make.width.equalTo(scrollView.snp.width).offset(-32)
        }
        
        // 底部工具栏
        toolbarView.backgroundColor = .systemBackground
        toolbarView.layer.shadowColor = UIColor.black.cgColor
        toolbarView.layer.shadowOffset = CGSize(width: 0, height: -1)
        toolbarView.layer.shadowOpacity = 0.05
        toolbarView.layer.shadowRadius = 2
        view.addSubview(toolbarView)
        toolbarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ScreenAdapter.scaleH(50))
        }
    }
    
    private func setupToolbar() {
        let items: [(icon: String, title: String, btn: UIButton, action: Selector)] = [
            ("textformat.size", "标题", titleBtn, #selector(addTitleBlock)),
            ("text.alignleft", "文字", textBtn, #selector(addTextBlock)),
            ("photo", "图片", imageBtn, #selector(addImageBlock)),
            ("video", "视频", videoBtn, #selector(addVideoBlock)),
            ("location", "位置", locationBtn, #selector(addLocationBlock))
        ]
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        toolbarView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        for item in items {
            let btn = item.btn
            btn.setImage(UIImage(systemName: item.icon), for: .normal)
            btn.tintColor = .themePrimary
            btn.setTitle(item.title, for: .normal)
            btn.titleLabel?.font = ScreenAdapter.font(10)
            btn.titleEdgeInsets = UIEdgeInsets(top: 22, left: -20, bottom: 0, right: 0)
            btn.imageEdgeInsets = UIEdgeInsets(top: -8, left: 10, bottom: 10, right: -10)
            btn.addTarget(self, action: item.action, for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }
    }
    
    // MARK: - 渲染内容块
    private func renderBlocks() {
        // 清除现有内容
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, block) in blocks.enumerated() {
            let blockView = createBlockView(for: block, at: index)
            contentStack.addArrangedSubview(blockView)
        }
    }
    
    private func createBlockView(for block: NoteBlock, at index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = ScreenAdapter.scaleW(8)
        container.tag = index
        
        switch block.type {
        case .title:
            let textField = UITextField()
            textField.text = block.content
            textField.placeholder = "输入标题"
            textField.font = ScreenAdapter.boldFont(20)
            textField.tag = index
            textField.addTarget(self, action: #selector(blockTextChanged(_:)), for: .editingChanged)
            container.addSubview(textField)
            textField.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14))
            }
            
        case .text:
            let textView = UITextView()
            textView.text = block.content
            textView.font = ScreenAdapter.font(15)
            textView.isScrollEnabled = false
            textView.delegate = self
            textView.tag = index
            textView.backgroundColor = .clear
            container.addSubview(textView)
            textView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
                make.height.greaterThanOrEqualTo(ScreenAdapter.scaleH(60))
            }
            
        case .image:
            let imgView = UIImageView()
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true
            imgView.layer.cornerRadius = ScreenAdapter.scaleW(8)
            imgView.backgroundColor = .systemGray6
            imgView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageBlockTapped(_:)))
            imgView.addGestureRecognizer(tap)
            imgView.tag = index
            
            if let urlStr = block.imageURL, !urlStr.isEmpty {
                let url: URL?
                if urlStr.hasPrefix("http") {
                    url = URL(string: urlStr)
                } else if urlStr.hasPrefix("/") {
                    url = URL(string: APIConfig.apiBaseURL + urlStr)
                } else {
                    url = URL(string: APIConfig.apiBaseURL + "/" + urlStr)
                }
                if let url = url {
                    imgView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
                }
            } else {
                imgView.image = UIImage(systemName: "photo")
                imgView.tintColor = .systemGray3
            }
            
            container.addSubview(imgView)
            imgView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
                make.height.equalTo(ScreenAdapter.scaleH(200))
            }
            
        case .video:
            let videoContainer = UIView()
            videoContainer.backgroundColor = .black
            videoContainer.layer.cornerRadius = ScreenAdapter.scaleW(8)
            videoContainer.clipsToBounds = true
            
            let playIcon = UIImageView()
            playIcon.image = UIImage(systemName: "play.circle.fill")
            playIcon.tintColor = .white
            playIcon.contentMode = .scaleAspectFit
            videoContainer.addSubview(playIcon)
            playIcon.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(ScreenAdapter.scaleW(48))
            }
            
            let videoLabel = UILabel()
            videoLabel.text = "视频内容"
            videoLabel.textColor = .white
            videoLabel.font = ScreenAdapter.font(14)
            videoLabel.textAlignment = .center
            videoContainer.addSubview(videoLabel)
            videoLabel.snp.makeConstraints { make in
                make.top.equalTo(playIcon.snp.bottom).offset(ScreenAdapter.scaleH(8))
                make.centerX.equalToSuperview()
            }
            
            container.addSubview(videoContainer)
            videoContainer.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
                make.height.equalTo(ScreenAdapter.scaleH(160))
            }
            
        case .location:
            let locView = UIView()
            locView.backgroundColor = .systemGray6
            locView.layer.cornerRadius = ScreenAdapter.scaleW(8)
            
            let locIcon = UIImageView()
            locIcon.image = UIImage(systemName: "mappin.circle.fill")
            locIcon.tintColor = .themePrimary
            locIcon.contentMode = .scaleAspectFit
            locView.addSubview(locIcon)
            locIcon.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
                make.centerY.equalToSuperview()
                make.width.height.equalTo(ScreenAdapter.scaleW(28))
            }
            
            let addrLabel = UILabel()
            addrLabel.text = block.location?.address ?? "位置信息"
            addrLabel.font = ScreenAdapter.font(14)
            addrLabel.numberOfLines = 2
            locView.addSubview(addrLabel)
            addrLabel.snp.makeConstraints { make in
                make.leading.equalTo(locIcon.snp.trailing).offset(ScreenAdapter.scaleW(10))
                make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
                make.centerY.equalToSuperview()
            }
            
            container.addSubview(locView)
            locView.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
                make.height.equalTo(ScreenAdapter.scaleH(60))
            }
        }
        
        // 删除按钮
        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteBtn.tintColor = .systemGray3
        deleteBtn.tag = index
        deleteBtn.addTarget(self, action: #selector(deleteBlock(_:)), for: .touchUpInside)
        container.addSubview(deleteBtn)
        deleteBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(4))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.width.height.equalTo(ScreenAdapter.scaleW(24))
        }
        
        return container
    }
    
    // MARK: - 添加内容块
    @objc private func addTitleBlock() {
        blocks.append(NoteBlock(type: .title))
        renderBlocks()
        scrollToBottom()
    }
    
    @objc private func addTextBlock() {
        blocks.append(NoteBlock(type: .text))
        renderBlocks()
        scrollToBottom()
    }
    
    @objc private func addImageBlock() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            presentImagePicker()
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.presentImagePicker()
                    } else {
                        AppUtility.showToast("请在设置中允许访问相册")
                    }
                }
            }
        }
    }
    
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.image.identifier]
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func addVideoBlock() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func addLocationBlock() {
        let locVC = LocationPickerViewController()
        locVC.onLocationSelected = { [weak self] location in
            let noteLoc = NoteLocation(
                latitude: location.latitude,
                longitude: location.longitude,
                address: location.name
            )
            self?.blocks.append(NoteBlock(type: .location, location: noteLoc))
            self?.renderBlocks()
            self?.scrollToBottom()
        }
        navigationController?.pushViewController(locVC, animated: true)
    }
    
    @objc private func deleteBlock(_ sender: UIButton) {
        let index = sender.tag
        guard index < blocks.count else { return }
        blocks.remove(at: index)
        renderBlocks()
    }
    
    @objc private func blockTextChanged(_ sender: UITextField) {
        let index = sender.tag
        guard index < blocks.count else { return }
        blocks[index].content = sender.text ?? ""
    }
    
    @objc private func imageBlockTapped(_ gesture: UITapGestureRecognizer) {
        guard let imgView = gesture.view as? UIImageView else { return }
        // 预览图片
        let previewVC = ImagePreviewViewController(image: imgView.image)
        previewVC.modalPresentationStyle = .fullScreen
        present(previewVC, animated: true)
    }
    
    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
            if bottomOffset.y > 0 {
                self.scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }
    
    // MARK: - 自动保存
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.autoSave()
        }
    }
    
    private func autoSave() {
        guard !blocks.isEmpty || !(note?.title.isEmpty ?? true) else { return }
        saveNote(silent: true)
    }
    
    private func saveNote(silent: Bool = false) {
        // 提取标题
        var noteTitle = ""
        for block in blocks {
            if block.type == .title, !block.content.isEmpty {
                noteTitle = block.content
                break
            }
        }
        if noteTitle.isEmpty, let firstText = blocks.first(where: { $0.type == .text })?.content {
            noteTitle = String(firstText.prefix(20))
        }
        
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let savedNote = NoteEntity(
            id: note?.id ?? UUID().uuidString,
            title: noteTitle,
            blocks: blocks,
            createTime: note?.createTime ?? now,
            updateTime: now,
            isSticky: note?.isSticky ?? false,
            remark: note?.remark ?? "",
            group: note?.group ?? "普通笔记"
        )
        
        if note == nil {
            NoteStorageManager.shared.addNote(savedNote)
            note = savedNote
        } else {
            NoteStorageManager.shared.updateNote(savedNote)
            note = savedNote
        }
        
        if !silent {
            onSave?(savedNote)
        }
    }
    
    @objc private func saveAndDismiss() {
        saveNote()
        AppUtility.showToast("已保存")
        dismiss(animated: true)
    }
    
    @objc private func deleteNote() {
        guard let id = note?.id else {
            dismiss(animated: true)
            return
        }
        let alert = UIAlertController(title: "删除笔记", message: "确定删除该笔记？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            NoteStorageManager.shared.deleteNote(id: id)
            self?.onDelete?(id)
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension NoteEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let index = textView.tag
        guard index < blocks.count else { return }
        blocks[index].content = textView.text
        
        // 动态调整高度
        let size = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        if size.height != textView.frame.height {
            textView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(max(size.height, ScreenAdapter.scaleH(60)))
            }
            view.layoutIfNeeded()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension NoteEditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let mediaType = info[.mediaType] as? String {
            if mediaType == UTType.image.identifier {
                if let image = info[.originalImage] as? UIImage,
                   let data = image.jpegData(compressionQuality: 0.6) {
                    Task {
                        do {
                            let fileName = "note_img_\(Int(Date().timeIntervalSince1970)).jpg"
                            let path = try await APIClient.shared.upload(data: data, fileName: fileName)
                            DispatchQueue.main.async { [weak self] in
                                self?.blocks.append(NoteBlock(type: .image, imageURL: path))
                                self?.renderBlocks()
                                self?.scrollToBottom()
                            }
                        } catch {
                            DispatchQueue.main.async {
                                AppUtility.showToast("图片上传失败")
                            }
                        }
                    }
                }
            } else if mediaType == UTType.movie.identifier {
                if let videoURL = info[.mediaURL] as? URL {
                    Task {
                        do {
                            guard let data = try? Data(contentsOf: videoURL) else {
                                AppUtility.showToast("视频读取失败")
                                return
                            }
                            let fileName = "note_video_\(Int(Date().timeIntervalSince1970)).mp4"
                            let path = try await APIClient.shared.upload(data: data, fileName: fileName)
                            DispatchQueue.main.async { [weak self] in
                                self?.blocks.append(NoteBlock(type: .video, videoURL: path))
                                self?.renderBlocks()
                                self?.scrollToBottom()
                            }
                        } catch {
                            DispatchQueue.main.async {
                                AppUtility.showToast("视频上传失败")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
