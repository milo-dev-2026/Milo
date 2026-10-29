import UIKit
import SnapKit
import MAMapKit
import AMapSearchKit
import CoreLocation

class LocationMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let mapContainer = UIView()
    private let pinIcon = UIImageView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let tailView = ChatBubbleTailView()
    private var locationCoord: CLLocationCoordinate2D?
    private var mapView: MAMapView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = ThemeDimension.bubbleCornerRadius
        bubbleView.clipsToBounds = true
        bubbleView.backgroundColor = .systemGray6

        nameLabel.font = ScreenAdapter.font(13)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        addressLabel.font = ScreenAdapter.font(11)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 1

        pinIcon.image = UIImage(systemName: "mappin.circle.fill")
        pinIcon.tintColor = .systemRed
        pinIcon.contentMode = .center

        let infoBar = UIView()
        infoBar.backgroundColor = .systemBackground

        let textStack = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        let stack = UIStackView(arrangedSubviews: [pinIcon, textStack])
        stack.axis = .horizontal
        stack.spacing = ScreenAdapter.scaleW(6)
        stack.alignment = .center
        infoBar.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        pinIcon.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }

        bubbleView.addSubview(mapContainer)
        bubbleView.addSubview(infoBar)
        contentView.addSubviews(tailView, bubbleView)

        mapContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleW(140))
        }

        infoBar.snp.makeConstraints { make in
            make.top.equalTo(mapContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(52))
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        // 兼容三种位置内容格式：安卓 "name|lat,lng"、旧版 "name,lat,lng"、本地占位 "[位置] name"
        let content = message.content
        let raw = content.replacingOccurrences(of: "[位置] ", with: "")
        var name = raw
        var address = ""
        var coord: CLLocationCoordinate2D?
        if raw.contains("|") {
            let parts = raw.components(separatedBy: "|")
            name = parts.first ?? raw
            if parts.count >= 2 {
                let nums = parts[1].components(separatedBy: ",")
                if nums.count >= 2, let lat = Double(nums[0]), let lon = Double(nums[1]) {
                    coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            }
        } else if raw.components(separatedBy: ",").count >= 3 {
            let parts = raw.components(separatedBy: ",")
            name = parts[0]
            if let lat = Double(parts[1]), let lon = Double(parts[2]) {
                coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
        // 如果 name 中包含换行或地址分隔，尝试拆分 name 和 address
        if name.contains("\n") {
            let lines = name.components(separatedBy: "\n")
            name = lines.first ?? name
            if lines.count > 1 { address = lines[1] }
        } else if name.contains("|") {
            // 部分安卓格式：name|address
            let parts = name.components(separatedBy: "|")
            name = parts.first ?? name
            if parts.count > 1 { address = parts[1] }
        }
        nameLabel.text = name.isEmpty ? "位置" : name
        addressLabel.text = address
        addressLabel.isHidden = address.isEmpty
        if let c = coord {
            locationCoord = c
            updateMapView(lat: c.latitude, lon: c.longitude)
        }

        let isFromMe = message.isFromMe
        let fillColor: UIColor = isFromMe ? .themeBubbleSend : .themeBubbleReceive
        bubbleView.backgroundColor = fillColor
        ChatBubbleLayout.install(
            bubble: bubbleView,
            tail: tailView,
            isFromMe: isFromMe,
            width: ScreenAdapter.scaleW(200),
            timeHeader: timeHeader,
            groupedAbove: groupedAbove,
            groupedBelow: groupedBelow,
            fillColor: fillColor,
            avatar: message.chatAvatar,
            status: message.isFromMe ? message.status : nil
        )
    }

    private func updateMapView(lat: Double, lon: Double) {
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        // 复用同一个地图实例（首次创建较慢，避免每次 configure 重建导致气泡长时间空白）
        if let map = mapView {
            map.setCenter(coord, animated: false)
            map.zoomLevel = 16
            return
        }
        let map = MAMapView()
        map.isUserInteractionEnabled = false
        map.showsUserLocation = false
        map.showsScale = false
        map.showsCompass = false
        map.logoCenter = CGPoint(x: -100, y: -100)
        map.setCenter(coord, animated: false)
        map.zoomLevel = 16
        mapContainer.addSubview(map)
        map.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        mapView = map

        let pin = MAPointAnnotation()
        pin.coordinate = coord
        map.add(pin)
    }

    func openLocationMap(from vc: UIViewController) {
        guard let coord = locationCoord else { return }
        let detail = LocationDetailViewController(
            name: nameLabel.text ?? "",
            address: addressLabel.text ?? "",
            latitude: coord.latitude,
            longitude: coord.longitude
        )
        vc.navigationController?.pushViewController(detail, animated: true)
    }
}
