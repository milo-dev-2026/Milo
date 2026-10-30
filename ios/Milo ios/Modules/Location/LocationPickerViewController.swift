import UIKit
import SnapKit
import MAMapKit
import AMapLocationKit
import AMapSearchKit
import CoreLocation

// MARK: - 地图选点页（对齐安卓 utalk MapLocationActivity + 微信"发送位置"）
// 布局：导航栏「所在位置」+ 右侧「发送」；顶部搜索框（点击进入独立搜索页）；
// 地图中心固定大头针，拖动地图选点；底部 POI 列表（首行"我的位置"，其后周边 POI），点选行地图跟随
struct PickedLocation {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

class LocationPickerViewController: UIViewController {

    private var mapView: MAMapView!
    private var poiTableView = UITableView()
    private var locateButton = UIButton(type: .system)

    private var pois: [AMapPOI] = []
    /// 当前选中的列表下标，默认 0
    private var selectedIndex = 0
    private var myLocationTitle = "我的位置"
    private var myLocationAddress = ""
    private var currentCoord: CLLocationCoordinate2D?
    private var searchAPI: AMapSearchAPI?
    private var locationManager: AMapLocationManager?
    /// 当前定位是否已取得过真实位置
    private var hasLocated = false
    /// 拖动结束后防抖刷新 POI
    private var dragRefreshWorkItem: DispatchWorkItem?

    /// 从搜索页选中的地点：置顶为列表第 0 行并选中（拖动地图后恢复普通模式）
    private var searchedPOI: AMapPOI?
    /// 当前城市（用于限定关键词搜索范围，取自逆地理结果）
    private var currentCity = ""

    var onLocationSelected: ((PickedLocation) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupMap()
        setupUI()
        setupSearch()
        checkPermissionAndLocate()
    }

    deinit {
        locationManager?.stopUpdatingLocation()
    }

    // MARK: - 导航栏（对齐 utalk 顶栏：返回 + 「所在位置」+ 右侧「发送」）
    private func setupNavBar() {
        title = "所在位置"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .label
        let sendItem = UIBarButtonItem(
            title: "发送",
            style: .plain,
            target: self,
            action: #selector(sendLocation)
        )
        sendButtonStyle(sendItem)
        navigationItem.rightBarButtonItem = sendItem
    }

    private func sendButtonStyle(_ item: UIBarButtonItem) {
        item.tintColor = .themePrimary
        let attrs: [NSAttributedString.Key: Any] = [
            .font: ScreenAdapter.mediumFont(15),
            .foregroundColor: UIColor.themePrimary
        ]
        item.setTitleTextAttributes(attrs, for: .normal)
        item.setTitleTextAttributes(attrs, for: .highlighted)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - 地图
    private func setupMap() {
        mapView = MAMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.zoomLevel = 16
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 中心固定大头针（拖动地图选点）
        let centerPin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        centerPin.tintColor = .systemRed
        centerPin.contentMode = .scaleAspectFit
        view.addSubview(centerPin)
        centerPin.snp.makeConstraints { make in
            make.centerX.equalTo(mapView)
            make.centerY.equalTo(mapView).offset(-ScreenAdapter.scaleH(17))
            make.width.height.equalTo(ScreenAdapter.scaleW(34))
        }

        // 用手势识别用户拖地图（平移/缩放），替代计时器猜测程序性移动，行为与微信一致：
        // 拖动结束后以防抖方式按新中心点刷新 POI 列表并选中首行
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleMapGesture(_:)))
        pan.delegate = self
        pan.cancelsTouchesInView = false
        mapView.addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handleMapGesture(_:)))
        pinch.delegate = self
        pinch.cancelsTouchesInView = false
        mapView.addGestureRecognizer(pinch)
    }

    @objc private func handleMapGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            dragRefreshWorkItem?.cancel()
        case .ended, .cancelled:
            let work = DispatchWorkItem { [weak self] in
                self?.refreshPOIAtMapCenter()
            }
            dragRefreshWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
        default:
            break
        }
    }

    /// 拖动结束：以地图新中心刷新逆地理与周边 POI，恢复普通列表模式并选中首行
    private func refreshPOIAtMapCenter() {
        let center = mapView.centerCoordinate
        guard abs(center.latitude) > 0.01 || abs(center.longitude) > 0.01 else { return }
        currentCoord = center
        searchedPOI = nil
        selectedIndex = 0
        myLocationTitle = "我的位置"
        reverseGeocode(coord: center)
        searchNearbyPOI(coord: center)
    }

    // MARK: - 页面布局
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // 顶部搜索框（仿微信：圆角灰底，点击 push 独立搜索页，不在本页内嵌搜索）
        let searchField = makeSearchField()
        view.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ScreenAdapter.scaleH(8))
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(12))
            make.height.equalTo(ScreenAdapter.scaleH(36))
        }

        // 底部 POI 列表面板
        poiTableView.dataSource = self
        poiTableView.delegate = self
        poiTableView.register(LocationPOICell.self, forCellReuseIdentifier: "POICell")
        poiTableView.rowHeight = ScreenAdapter.scaleH(56)
        poiTableView.tableFooterView = UIView()
        view.addSubview(poiTableView)
        poiTableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(ScreenAdapter.scaleH(300))
        }

        // 地图区域限制在搜索框与列表之间，中心大头针始终指向列表上方地图中心
        mapView.snp.remakeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(ScreenAdapter.scaleH(8))
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(poiTableView.snp.top)
        }

        // 定位按钮（回到当前位置），浮在列表上方右侧
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
            make.bottom.equalTo(poiTableView.snp.top).offset(-ScreenAdapter.scaleH(12))
            make.width.height.equalTo(ScreenAdapter.scaleW(44))
        }
    }

    /// 构造只读搜索框（放大镜 + 占位文字），点击打开独立搜索页
    private func makeSearchField() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        container.layer.cornerRadius = ScreenAdapter.scaleW(8)
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .secondaryLabel
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = "搜索地点"
        label.font = ScreenAdapter.font(14)
        label.textColor = .secondaryLabel
        container.addSubviews(icon, label)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(12))
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ScreenAdapter.scaleW(16))
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(ScreenAdapter.scaleW(6))
            make.centerY.equalToSuperview()
        }
        container.isUserInteractionEnabled = true
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSearchPage)))
        return container
    }

    @objc private func openSearchPage() {
        let searchVC = LocationSearchViewController()
        searchVC.currentCity = currentCity
        if let coord = currentCoord {
            searchVC.nearCoordinate = coord
        }
        searchVC.onPick = { [weak self] poi in
            self?.applySearchedPOI(poi)
        }
        navigationController?.pushViewController(searchVC, animated: true)
    }

    /// 搜索页选点：地图移到该地点，该 POI 置顶为列表第 0 行并选中
    private func applySearchedPOI(_ poi: AMapPOI) {
        let coord = CLLocationCoordinate2D(latitude: poi.location.latitude, longitude: poi.location.longitude)
        searchedPOI = poi
        selectedIndex = 0
        currentCoord = coord
        mapView.setCenter(coord, animated: false)
        mapView.setZoomLevel(17, animated: false)
        reverseGeocode(coord: coord)
        searchNearbyPOI(coord: coord)
        poiTableView.reloadData()
    }

    private func setupSearch() {
        searchAPI = AMapSearchAPI()
        searchAPI?.delegate = self
    }

    // MARK: - 定位
    private func checkPermissionAndLocate() {
        startLocating()
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
            myLocationAddress = regeocode.formattedAddress ?? ""
            let poiName = regeocode.poiName ?? ""
            myLocationTitle = poiName.isEmpty ? "我的位置" : poiName
        } else {
            myLocationTitle = "我的位置"
        }
        searchedPOI = nil
        selectedIndex = 0
        mapView.setCenter(coord, animated: false)
        mapView.setZoomLevel(17, animated: false)
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

        if let searched = searchedPOI, selectedIndex == 0 {
            name = (searched.name?.isEmpty == false ? searched.name! : "所选位置")
            address = searched.address ?? ""
            coord = CLLocationCoordinate2D(latitude: searched.location.latitude, longitude: searched.location.longitude)
        } else {
            let poiIndex = selectedIndex - 1
            if selectedIndex > 0, pois.count > poiIndex, poiIndex >= 0 {
                let poi = pois[poiIndex]
                name = (poi.name?.isEmpty == false ? poi.name! : (poi.address ?? "所选位置"))
                address = poi.address ?? ""
                coord = CLLocationCoordinate2D(latitude: poi.location.latitude, longitude: poi.location.longitude)
            } else if selectedIndex == 0, !hasLocated, let first = pois.first {
                // 无定位权限时首条即为列表第一项POI
                name = (first.name?.isEmpty == false ? first.name! : (first.address ?? "所选位置"))
                address = first.address ?? ""
                coord = CLLocationCoordinate2D(latitude: first.location.latitude, longitude: first.location.longitude)
            }
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

// MARK: - UIGestureRecognizerDelegate（地图手势与系统手势共存）
extension LocationPickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - MAMapViewDelegate
extension LocationPickerViewController: MAMapViewDelegate {
    // 不再用 regionDidChangeAnimated 判定拖动（无法区分程序性移动），统一走手势识别
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
        pois = response.pois ?? []
        // 对齐安卓：默认选中首行（"我的位置"或搜索置顶项）
        if selectedIndex >= tableRowCount { selectedIndex = 0 }
        poiTableView.reloadData()
    }

    func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        // 城市取自逆地理的地址组件（AMapReGeocode 本身没有 city 字段），用于限定关键词搜索范围
        let city = response.regeocode?.addressComponent?.city ?? ""
        if !city.isEmpty {
            currentCity = city
        }
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

    /// 列表行数：第 0 行为"我的位置"或搜索置顶地点
    private var tableRowCount: Int { pois.count + 1 }
}

// MARK: - UITableViewDataSource & Delegate
extension LocationPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pois.count + 1 // 第0行固定为"我的位置"/搜索选中的地点
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "POICell", for: indexPath) as! LocationPOICell
        if indexPath.row == 0 {
            if let searched = searchedPOI {
                cell.configure(name: searched.name ?? "所选位置",
                               address: searched.address ?? "",
                               selected: selectedIndex == 0)
            } else {
                cell.configure(name: myLocationTitle, address: myLocationAddress, selected: selectedIndex == 0)
            }
        } else {
            guard indexPath.row - 1 < pois.count else { return cell }
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

        // 点选行：地图移到对应地点（程序性移动，不触发列表刷新）
        var target: CLLocationCoordinate2D?
        if indexPath.row == 0 {
            if let searched = searchedPOI {
                target = CLLocationCoordinate2D(latitude: searched.location.latitude, longitude: searched.location.longitude)
            } else {
                target = currentCoord
            }
        } else if indexPath.row - 1 < pois.count {
            let poi = pois[indexPath.row - 1]
            target = CLLocationCoordinate2D(latitude: poi.location.latitude, longitude: poi.location.longitude)
        }
        if let coord = target {
            currentCoord = coord
            mapView.setCenter(coord, animated: true)
        }
    }
}

// MARK: - 地址搜索页（对齐安卓 SearchLocationActivity + 微信：全屏搜索，自动弹键盘）
class LocationSearchViewController: UIViewController {

    /// 限定搜索城市（传空则全国）
    var currentCity = ""
    /// 附近坐标（排序参考）
    var nearCoordinate: CLLocationCoordinate2D?
    var onPick: ((AMapPOI) -> Void)?

    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let emptyLabel = UILabel()
    private var searchAPI: AMapSearchAPI?
    private var results: [AMapPOI] = []
    private var searchWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "搜索地点"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"), style: .plain,
            target: self, action: #selector(backTapped))
        navigationItem.leftBarButtonItem?.tintColor = .label

        searchBar.placeholder = "搜索地点"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LocationPOICell.self, forCellReuseIdentifier: "POICell")
        tableView.rowHeight = ScreenAdapter.scaleH(56)
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.text = "没有找到该地点，换个关键词试试"
        emptyLabel.font = ScreenAdapter.font(14)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(searchBar.snp.bottom).offset(ScreenAdapter.scaleH(60))
        }

        searchAPI = AMapSearchAPI()
        searchAPI?.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 进入即弹键盘（对齐微信搜索页）
        searchBar.becomeFirstResponder()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func search(_ keyword: String) {
        let kw = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !kw.isEmpty else {
            results = []
            emptyLabel.isHidden = true
            tableView.reloadData()
            return
        }
        let request = AMapPOIKeywordsSearchRequest()
        request.keywords = kw
        if !currentCity.isEmpty {
            request.city = currentCity
            request.cityLimit = true
        }
        request.offset = 30
        request.page = 1
        searchAPI?.aMapPOIKeywordsSearch(request)
    }
}

extension LocationSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 输入防抖 0.4 秒
        searchWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.search(searchText)
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchWorkItem?.cancel()
        search(searchBar.text ?? "")
    }
}

extension LocationSearchViewController: AMapSearchDelegate {
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        results = response.pois ?? []
        emptyLabel.isHidden = !results.isEmpty || (searchBar.text ?? "").isEmpty
        tableView.reloadData()
    }

    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        print("[LocationSearch] 搜索失败: \(error?.localizedDescription ?? "unknown")")
    }
}

extension LocationSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "POICell", for: indexPath) as! LocationPOICell
        guard indexPath.row < results.count else { return cell }
        let poi = results[indexPath.row]
        cell.configure(name: poi.name ?? "未知位置", address: poi.address ?? "", selected: false)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < results.count else { return }
        let poi = results[indexPath.row]
        searchBar.resignFirstResponder()
        navigationController?.popViewController(animated: true)
        onPick?(poi)
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
