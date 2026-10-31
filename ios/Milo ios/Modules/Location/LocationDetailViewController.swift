import UIKit
import SnapKit
import MapKit
import CoreLocation

// MARK: - 位置详情页（对齐安卓 LocationDetailActivity）
class LocationDetailViewController: UIViewController {

    private let locationName: String
    private let address: String
    private let latitude: Double
    private let longitude: Double

    private var mapView: MKMapView!

    init(name: String, address: String, latitude: Double, longitude: Double) {
        self.locationName = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupMap()
        setupTopBar()
        setupBottomPanel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - 地图（系统 MapKit，不依赖高德 key/配额）
    private func setupMap() {
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = false
        mapView.pointOfInterestFilter = .excludingAll
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if latitude != 0 && longitude != 0 {
            let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            mapView.setRegion(MKCoordinateRegion(center: coord, latitudinalMeters: 300, longitudinalMeters: 300), animated: false)
            let pin = MKPointAnnotation()
            pin.coordinate = coord
            pin.title = locationName
            mapView.addAnnotation(pin)
        }
    }

    // MARK: - 顶部栏（返回 + 居中"地点" + 分享）
    private func setupTopBar() {
        let topBar = UIView()
        topBar.backgroundColor = .white
        view.addSubview(topBar)
        topBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.safeAreaTop + ScreenAdapter.scaleH(48))
        }

        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor = UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 1)
        backBtn.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        topBar.addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(4))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.scaleH(4))
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }

        let titleLabel = UILabel()
        titleLabel.text = "地点"
        titleLabel.font = ScreenAdapter.boldFont(18)
        titleLabel.textColor = UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 1)
        topBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backBtn)
        }

        let shareBtn = UIButton(type: .system)
        shareBtn.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareBtn.tintColor = UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 1)
        shareBtn.addTarget(self, action: #selector(onShare), for: .touchUpInside)
        topBar.addSubview(shareBtn)
        shareBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(4))
            make.centerY.equalTo(backBtn)
            make.width.height.equalTo(ScreenAdapter.scaleW(40))
        }
    }

    // MARK: - 底部信息面板（名称 + 地址 + 导航按钮）
    private func setupBottomPanel() {
        let panel = UIView()
        panel.backgroundColor = .white
        panel.layer.cornerRadius = ScreenAdapter.scaleW(12)
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panel.layer.shadowColor = UIColor.black.cgColor
        panel.layer.shadowOpacity = 0.1
        panel.layer.shadowOffset = CGSize(width: 0, height: -2)
        panel.layer.shadowRadius = 8
        view.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        let nameLabel = UILabel()
        nameLabel.text = locationName.isEmpty ? "位置" : locationName
        nameLabel.font = ScreenAdapter.boldFont(17)
        nameLabel.textColor = UIColor(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0, alpha: 1)
        nameLabel.numberOfLines = 1

        let addressLabel = UILabel()
        addressLabel.text = address
        addressLabel.font = ScreenAdapter.font(13)
        addressLabel.textColor = UIColor(red: 0x99/255.0, green: 0x99/255.0, blue: 0x99/255.0, alpha: 1)
        addressLabel.numberOfLines = 2
        addressLabel.isHidden = address.isEmpty

        let textStack = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        textStack.axis = .vertical
        textStack.spacing = ScreenAdapter.scaleH(4)
        panel.addSubview(textStack)

        let navBtn = UIButton(type: .system)
        navBtn.setImage(UIImage(systemName: "location.fill"), for: .normal)
        navBtn.tintColor = .white
        navBtn.backgroundColor = .themePrimary
        navBtn.layer.cornerRadius = ScreenAdapter.scaleW(22)
        navBtn.addTarget(self, action: #selector(onNavigate), for: .touchUpInside)
        panel.addSubview(navBtn)
        navBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalTo(textStack)
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalTo(navBtn.snp.leading).offset(-ScreenAdapter.scaleW(12))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.safeAreaBottom - ScreenAdapter.scaleH(16))
        }
    }

    // MARK: - 动作
    @objc private func onBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onShare() {
        let vc = ChooseChatViewController()
        vc.onSelectedWithType = { [weak self] channelId, channelType, _ in
            guard let self = self else { return }
            IMManager.shared.sendLocationMessage(
                channelId: channelId,
                name: self.locationName,
                address: self.address,
                latitude: self.latitude,
                longitude: self.longitude,
                channelType: channelType
            )
            AppUtility.showToast("已发送")
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onNavigate() {
        guard latitude != 0 && longitude != 0 else { return }
        let poiName = locationName.isEmpty ? "目的地" : locationName
        let encoded = poiName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? poiName
        // 优先打开高德 App，其次高德网页导航，最后苹果地图
        if let amapURL = URL(string: "iosamap://navi?sourceApplication=chat&poiname=\(encoded)&lat=\(latitude)&lon=\(longitude)&dev=0&style=2"),
           UIApplication.shared.canOpenURL(amapURL) {
            UIApplication.shared.open(amapURL)
            return
        }
        if let webURL = URL(string: "https://uri.amap.com/navigation?to=\(longitude),\(latitude),\(encoded)&mode=car&src=chat") {
            UIApplication.shared.open(webURL)
            return
        }
        if let appleURL = URL(string: "http://maps.apple.com/?daddr=\(latitude),\(longitude)") {
            UIApplication.shared.open(appleURL)
        }
    }
}

// MARK: - MKMapViewDelegate（自定义红色大头针）
extension LocationDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        let reuseId = "locationPin"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        view.markerTintColor = .systemRed
        view.animatesWhenAdded = false
        return view
    }
}
