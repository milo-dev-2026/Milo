import UIKit
import SnapKit
import MAMapKit
import AMapLocationKit
import AMapSearchKit

// MARK: - 地图选点页
struct PickedLocation {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

class LocationPickerViewController: UIViewController {

    private var mapView: MAMapView!
    private var searchButton = UIButton(type: .system)
    private var poiListView = UIView()
    private var poiTableView = UITableView()
    private var pois: [AMapPOI] = []
    private var selectedPOI: AMapPOI?
    private var searchAPI: AMapSearchAPI?
    private var locationManager: AMapLocationManager?

    var onLocationSelected: ((PickedLocation) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupUI()
        setupLocation()
        setupSearch()
    }

    private func setupMap() {
        mapView = MAMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupUI() {
        title = "发送位置"

        let panel = UIView()
        panel.backgroundColor = .systemBackground
        panel.layer.cornerRadius = ScreenAdapter.scaleW(12)
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(panel)

        poiTableView.dataSource = self
        poiTableView.delegate = self
        poiTableView.register(UITableViewCell.self, forCellReuseIdentifier: "POICell")
        poiTableView.rowHeight = ScreenAdapter.scaleH(56)
        panel.addSubview(poiTableView)

        searchButton.setTitle("发送", for: .normal)
        searchButton.backgroundColor = .themePrimary
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.titleLabel?.font = ScreenAdapter.mediumFont(17)
        searchButton.layer.cornerRadius = ScreenAdapter.scaleW(8)
        searchButton.addTarget(self, action: #selector(sendLocation), for: .touchUpInside)
        panel.addSubview(searchButton)

        panel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(ScreenAdapter.scaleH(300))
        }

        poiTableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(searchButton.snp.top).offset(-ScreenAdapter.scaleH(8))
        }

        searchButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(ScreenAdapter.scaleW(16))
            make.trailing.equalToSuperview().offset(-ScreenAdapter.scaleW(16))
            make.bottom.equalToSuperview().offset(-ScreenAdapter.safeAreaBottom - ScreenAdapter.scaleH(8))
            make.height.equalTo(ScreenAdapter.scaleH(44))
        }
    }

    private func setupLocation() {
        locationManager = AMapLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.startUpdatingLocation()
    }

    private func setupSearch() {
        searchAPI = AMapSearchAPI()
        searchAPI?.delegate = self
    }

    private func searchPOI(keyword: String, location: CLLocationCoordinate2D) {
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(withLatitude: location.latitude, longitude: location.longitude)
        request.keywords = keyword
        request.radius = 1000
        request.offset = 20
        searchAPI?.aMapPOIAroundSearch(request)
    }

    @objc private func sendLocation() {
        guard let poi = selectedPOI else {
            AppUtility.showToast("请选择一个位置")
            return
        }
        let picked = PickedLocation(
            name: poi.name ?? "",
            address: poi.address ?? "",
            latitude: poi.location.latitude,
            longitude: poi.location.longitude
        )
        onLocationSelected?(picked)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - MAMapViewDelegate
extension LocationPickerViewController: MAMapViewDelegate {

    func mapView(_ mapView: MAMapView!, didChange userTrackingMode: MAUserTrackingMode, byUser wasUserAction: Bool) {
        if wasUserAction {
            mapView.setCenterCoordinate(mapView.userLocation.coordinate, animated: true)
        }
    }

    func mapView(_ mapView: MAMapView!, regionWillChangeAnimated animated: Bool) {
    }

    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        searchPOI(keyword: "", location: center)
    }
}

// MARK: - AMapLocationManagerDelegate
extension LocationPickerViewController: AMapLocationManagerDelegate {

    func amapLocationManager(_ manager: AMapLocationManager!, didUpdateLocation location: CLLocation!) {
        mapView.setCenterCoordinate(location.coordinate, animated: true)
        mapView.setZoomLevel(16, animated: true)
        searchPOI(keyword: "", location: location.coordinate)
        manager.stopUpdatingLocation()
    }
}

// MARK: - AMapSearchDelegate
extension LocationPickerViewController: AMapSearchDelegate {

    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        pois = response.pois ?? []
        poiTableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension LocationPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pois.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "POICell", for: indexPath)
        let poi = pois[indexPath.row]
        cell.textLabel?.text = poi.name
        cell.textLabel?.font = ScreenAdapter.font(15)
        cell.detailTextLabel?.text = poi.address
        cell.detailTextLabel?.font = ScreenAdapter.font(12)
        cell.accessoryType = selectedPOI?.uid == poi.uid ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedPOI = pois[indexPath.row]
        tableView.reloadData()
        if let coord = selectedPOI?.location {
            mapView.setCenterCoordinate(CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude), animated: true)
        }
    }
}
