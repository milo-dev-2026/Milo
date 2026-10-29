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

        pinIcon.image = UIImage(systemName: "mappin.circle.fill")
        pinIcon.tintColor = .systemRed
        pinIcon.contentMode = .center

        let infoBar = UIView()
        infoBar.backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: [pinIcon, nameLabel])
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
            make.height.equalTo(ScreenAdapter.scaleH(38))
        }
    }

    func configure(with message: Message, timeHeader: String? = nil, groupedAbove: Bool = false, groupedBelow: Bool = false) {
        let content = message.content
        if content.hasPrefix("[位置] ") {
            let parts = content.replacingOccurrences(of: "[位置] ", with: "").components(separatedBy: ",")
            if parts.count >= 3 {
                let name = parts[0]
                let lat = Double(parts[1]) ?? 0
                let lon = Double(parts[2]) ?? 0
                nameLabel.text = name
                locationCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                updateMapView(lat: lat, lon: lon)
            }
        } else {
            nameLabel.text = content
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
        mapView?.removeFromSuperview()
        let map = MAMapView()
        map.isUserInteractionEnabled = false
        map.showsUserLocation = false
        map.showsScale = false
        map.showsCompass = false
        map.logoCenter = CGPoint(x: -100, y: -100)
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
        guard locationCoord != nil else { return }
        let picker = LocationPickerViewController()
        vc.navigationController?.pushViewController(picker, animated: true)
    }
}
