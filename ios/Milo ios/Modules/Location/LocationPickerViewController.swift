import UIKit
import SnapKit
import MAMapKit
import AMapLocationKit
import AMapSearchKit
import CoreLocation

// MARK: - 地图选点页（对齐安卓 LocationPickerActivity：中心点选址+POI列表自动选中首条+逆地理兜底）
struct PickedLocation {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

class LocationPickerViewController: UIViewController {

    private var mapView: MAMapView!
    private var sendButton = UIButton(type: .system)
    private var locateButton = UIButton(type: .system)
    private var poiTableView = UITableView()
    private var pois: [AMapPOI] = []
    /// 当前选中的下标，-1 表示选中"我的位置"
    private var selectedIndex = 0
    private var myLocationTitle = "我的位置"
    private var myLocationAddress = ""
    private var currentCoord: CLLocationCoordinate2D?
    private var searchAPI: AMapSearchAPI?
    private var locationManager: AMapLocationManager?
    private var isProgrammaticMove = false
    /// 当前定位是否已取得过真实位置
    private var hasLocated = false

    var onLocationSelected: ((PickedLocation) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupUI()
        setupSearch()
        checkPermissionAndLocate()
    }

    deinit {
        locationManager?.stopUpdatingLocation()
    }

    private func setupMap() {
        mapView = MAMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.zoomLevel = 16
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 中心固定大头针（对齐安卓地图中心选址：图标固定在地图中心，拖动地图选点）
        let centerPin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        centerPin.tintColor = .systemRed
        centerPin.contentMode = .scaleAspectFit
        view.addSubview(centerPin)
        centerPin.snp.makeConstraints { make in
            make.centerX.equalTo(mapView)
            make.centerY.equalTo(mapView).offset(-ScreenAdapter.scaleH(17))
            make.width.height.equalTo(ScreenAdapter.scaleW(34))
        }
    }

    private func setupUI() {
        title = "发送位置"
        view.backgroundColor = .systemBackground

        // 底部面板：POI列表 + 发送按钮
        let panel = UIView()
        panel.backgroundColor = .systemBackground
        view.addSubview(panel)

        poiTableView.dataSource = self
        poiTableView.delegate = self
        poiTableView.register(LocationPOICell.self, forCellReuseIdentifier: "POICell")
        poiTableView.rowHeight = ScreenAdapter.scaleH(56)
        panel.addSubview(poiTableView)

        sendButton.setTitle("发送", for: .normal)
        sendButton.backgroundColor = .themePrimary
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        sendButton.layer.cornerRadius = ScreenAdapter.scaleW(8)
        sendButton.addTarget(self, action: #selector(sendLocation), for: .touchUpInside)
        panel.addSubview(sendButton)

        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(300) + ScreenAdapter.safeAreaBottom)
        }

        sendButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.safeAreaBottom - ScreenAdapter.scaleH(8))
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        poiTableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(sendButton.snp.top).offset(-ScreenAdapter.scaleH(8))
        }

        // 定位按钮（回到当前位置）
        locateButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locateButton.tintColor = .themePrimary
        locateButton.backgroundColor = .systemBackground
        locateButton.layer.cornerRadius = ScreenAdapter.scaleW(22)
        locateButton.layer.shadowColor = UIColor.black.cgColor
        locateButton.layer.shadowOpacity = 0.15
        locateButton.layer.shadowRadius = 4
        locateButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        locateButton.addTarget(self, action: #selector(relocate), for: .touchUpInside)
        view.addSubview(locateButton)
        locateButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalTo(panel.snp.top).offset(-ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }
    }

    private func setupSearch() {
        searchAPI = AMapSearchAPI()
        searchAPI?.delegate = self
    }

    // MARK: - 定位
    private func checkPermissionAndLocate() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            // 触发系统权限弹窗
            let mgr = CLLocationManager()
            mgr.requestWhenInUseAuthorization()
            startLocating()
        case .authorizedAlways, .authorizedWhenInUse:
            startLocating()
        default:
            AppUtility.showToast("定位权限被拒绝，无法获取当前位置")
        }
    }

    private func startLocating() {
        if locationManager == nil {
            locationManager = AMapLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.locationTimeout = 10
            locationManager?.reGeocodeTimeout = 10
        }
        // 带逆地理的单次定位，直接拿到地址
        locationManager?.requestLocation(withReGeocode: true) { [weak self] location, regeocode, error in
            guard let self = self else { return }
            if let location = location {
                self.handleLocated(location: location, regeocode: regeocode)
            } else {
                // 兜底：持续定位回调
                self.locationManager?.startUpdatingLocation()
            }
        }
    }

    @objc private func relocate() {
        startLocating()
    }

    private func handleLocated(location: CLLocation, regeocode: AMapLocationReGeocode?) {
        hasLocated = true
        let coord = location.coordinate
        currentCoord = coord
        if let regeocode = regeocode {
            let addr = regeocode.formattedAddress ?? ""
            myLocationAddress = addr
            let poiName = regeocode.poiName ?? ""
            myLocationTitle = poiName.isEmpty ? "我的位置" : poiName
        } else {
            myLocationTitle = "我的位置"
        }
        isProgrammaticMove = true
        mapView.setCenter(coord, animated: false)
        mapView.setZoomLevel(17, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isProgrammaticMove = false
        }
        selectedIndex = 0
        searchNearbyPOI(coord: coord)
    }

    // MARK: - POI 搜索
    private func searchNearbyPOI(coord: CLLocationCoordinate2D) {
        // 对齐安卓：空关键字 + 圆形范围搜索，types 覆盖常见类别确保 iOS 端必返回结果
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(withLatitude: coord.latitude, longitude: coord.longitude)
        request.keywords = ""
        request.types = "汽车服务|汽车销售|汽车维修|摩托车服务|餐饮服务|购物服务|生活服务|体育休闲服务|医疗保健服务|住宿服务|风景名胜|商务住宅|政府机构及社会团体|科教文化服务|交通设施服务|金融保险服务|公司企业|道路附属设施|地名地址信息|公共设施"
        request.radius = 3000
        request.offset = 30
        request.page = 1
        searchAPI?.aMapPOIAroundSearch(request)
    }

    private func reverseGeocode(coord: CLLocationCoordinate2D) {
        let request = AMapReGeocodeSearchRequest()
        request.location = AMapGeoPoint.location(withLatitude: coord.latitude, longitude: coord.longitude)
        request.radius = 200
        request.requireExtension = true
        searchAPI?.aMapReGoecodeSearch(request)
    }

    // MARK: - 发送
    @objc private func sendLocation() {
        var name = myLocationTitle
        var address = myLocationAddress
        var coord = currentCoord

        if selectedIndex > 0, pois.count > selectedIndex - 1 {
            let poi = pois[selectedIndex - 1]
            name = (poi.name?.isEmpty == false ? poi.name! : (poi.address ?? "所选位置"))
            address = poi.address ?? ""
            coord = CLLocationCoordinate2D(latitude: poi.location.latitude, longitude: poi.location.longitude)
        } else if selectedIndex == 0, pois.count > 0, hasLocated == false {
            // 无定位权限时首条即为列表第一项POI
            let poi = pois[0]
            name = (poi.name?.isEmpty == false ? poi.name! : (poi.address ?? "所选位置"))
            address = poi.address ?? ""
            coord = CLLocationCoordinate2D(latitude: poi.location.latitude, longitude: poi.location.longitude)
        }

        guard let finalCoord = coord, !(name.isEmpty && address.isEmpty) else {
            let alert = UIAlertController(title: "提示", message: "请选择一个位置", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        if name.isEmpty { name = "我的位置" }
        let picked = PickedLocation(name: name, address: address, latitude: finalCoord.latitude, longitude: finalCoord.longitude)
        onLocationSelected?(picked)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - MAMapViewDelegate
extension LocationPickerViewController: MAMapViewDelegate {

    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        // 用户拖动地图后：以新中心点搜索周边POI（程序性移动不触发）
        guard !isProgrammaticMove else { return }
        let center = mapView.centerCoordinate
        // 过滤无效的初始坐标(0,0)
        guard abs(center.latitude) > 0.01 || abs(center.longitude) > 0.01 else { return }
        currentCoord = center
        selectedIndex = 0
        reverseGeocode(coord: center)
        searchNearbyPOI(coord: center)
    }
}

// MARK: - AMapLocationManagerDelegate
extension LocationPickerViewController: AMapLocationManagerDelegate {

    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!, reGeocode: AMapLocationReGeocode!) {
        manager.stopUpdatingLocation()
        guard !hasLocated else { return }
        handleLocated(location: location, regeocode: reGeocode)
    }

    func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
        print("[LocationPicker] 定位失败: \(error.localizedDescription)")
    }

    func amapLocationManager(_ manager: AMapLocationManager!, doRequireLocationAuth locationManager: CLLocationManager!) {
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - AMapSearchDelegate
extension LocationPickerViewController: AMapSearchDelegate {

    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        let result = response.pois ?? []
        pois = result
        // 对齐安卓：搜索到结果后默认选中第一条（下标1，0为"我的位置"）
        if !result.isEmpty {
            selectedIndex = hasLocated ? 0 : 1
        }
        poiTableView.reloadData()
    }

    func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        if let addr = response.regeocode?.formattedAddress, !addr.isEmpty {
            myLocationAddress = addr
            if myLocationTitle == "我的位置" || myLocationTitle.isEmpty {
                let poiName = response.regeocode?.pois?.first?.name ?? ""
                myLocationTitle = poiName.isEmpty ? "我的位置" : poiName
            }
            poiTableView.reloadData()
        }
    }

    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        print("[LocationPicker] 搜索失败: \(error?.localizedDescription ?? "unknown")")
    }
}

// MARK: - UITableViewDataSource & Delegate
extension LocationPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pois.count + 1 // 第0行固定为"我的位置"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "POICell", for: indexPath) as! LocationPOICell
        if indexPath.row == 0 {
            cell.configure(name: myLocationTitle, address: myLocationAddress, selected: selectedIndex == 0)
        } else {
            let poi = pois[indexPath.row - 1]
            let name = (poi.name?.isEmpty == false ? poi.name! : "未知位置")
            cell.configure(name: name, address: poi.address ?? "", selected: selectedIndex == indexPath.row)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = indexPath.row
        tableView.reloadData()
        if indexPath.row > 0 {
            let poi = pois[indexPath.row - 1]
            let coord = CLLocationCoordinate2D(latitude: poi.location.latitude, longitude: poi.location.longitude)
            currentCoord = coord
            isProgrammaticMove = true
            mapView.setCenter(coord, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isProgrammaticMove = false
            }
        } else if let coord = currentCoord {
            isProgrammaticMove = true
            mapView.setCenter(coord, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isProgrammaticMove = false
            }
        }
    }
}

// MARK: - POI 列表单元格（名称+地址+选中勾，对齐安卓 item_poi_layout）
class LocationPOICell: UITableViewCell {

    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let checkIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        nameLabel.font = ScreenAdapter.font(15)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1

        addressLabel.font = ScreenAdapter.font(12)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 1

        checkIcon.image = UIImage(systemName: "checkmark.circle.fill")
        checkIcon.tintColor = .themePrimary
        checkIcon.contentMode = .scaleAspectFit

        contentView.addSubviews(nameLabel, addressLabel, checkIcon)

        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalTo(checkIcon.snp.leading).offset(-ScreenAdapter.scaleW(8))
            make.top.equalToSuperview().offset(ScreenAdapter.scaleH(8))
        }
        addressLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(ScreenAdapter.scaleH(4))
        }
        checkIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(20))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, address: String, selected: Bool) {
        nameLabel.text = name
        addressLabel.text = address
        addressLabel.isHidden = address.isEmpty
        checkIcon.isHidden = !selected
    }
}
