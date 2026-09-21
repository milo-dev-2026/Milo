import UIKit
import SnapKit
import AMap3DMap
import AMapSearchKit

class LocationMessageCell: UITableViewCell {

    private let bubbleView = UIView()
    private let mapContainer = UIView()
    private let pinIcon = UIImageView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let avatarView = UIImageView()
    private var isFromMe = false
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

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)

        timeLabel.font = ScreenAdapter.font(11)
        timeLabel.textColor = .tertiaryLabel

        bubbleView.layer.cornerRadius = ScreenAdapter.scaleW(8)
        bubbleView.clipsToBounds = true
        bubbleView.backgroundColor = .systemGray6

        avatarView.layer.cornerRadius = ScreenAdapter.scaleW(4)
        avatarView.clipsToBounds = true
        avatarView.contentMode = .scaleAspectFill
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = .systemGray5

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
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(8))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(8))
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }

        pinIcon.snp.makeConstraints { make in
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }

        bubbleView.addSubview(mapContainer)
        bubbleView.addSubview(infoBar)

        mapContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleW(140))
        }

        infoBar.snp.makeConstraints { make in
            make.top.equalTo(mapContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(36))
        }

        contentView.addSubviews(avatarView, bubbleView, timeLabel)

        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(vPad)
            make.width.height.equalTo(avatarSize)
        }
    }

    func configure(with message: Message) {
        isFromMe = message.isFromMe
        timeLabel.text = message.timeString

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

        let avatarSize = ScreenAdapter.scaleW(36)
        let hPad = ScreenAdapter.scaleW(12)
        let vPad = ScreenAdapter.scaleH(12)
        let bubbleGap = ScreenAdapter.scaleW(8)
        let timeGap = ScreenAdapter.scaleH(4)
        let mapSize = ScreenAdapter.scaleW(180)

        if isFromMe {
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().offset(-hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(mapSize)
            }
            timeLabel.snp.remakeConstraints { make in
                make.trailing.equalTo(bubbleView.snp.trailing)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        } else {
            avatarView.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(hPad)
                make.top.equalToSuperview().offset(vPad)
                make.width.height.equalTo(avatarSize)
            }
            bubbleView.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(bubbleGap)
                make.top.equalTo(avatarView)
                make.width.equalTo(mapSize)
            }
            timeLabel.snp.remakeConstraints { make in
                make.leading.equalTo(bubbleView.snp.leading)
                make.top.equalTo(bubbleView.snp.bottom).offset(timeGap)
                make.bottom.equalToSuperview().offset(-vPad)
            }
        }
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
        guard let coord = locationCoord else { return }
        let picker = LocationPickerViewController()
        vc.navigationController?.pushViewController(picker, animated: true)
    }
}
