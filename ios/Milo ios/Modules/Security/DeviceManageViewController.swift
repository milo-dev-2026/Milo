import UIKit
import SnapKit

class DeviceManageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private struct DeviceItem {
        let deviceId: String
        let name: String
        let info: String
        let isCurrent: Bool
    }

    private var devices: [DeviceItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设备管理"
        view.backgroundColor = .themeBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        loadDevices()
    }

    private func loadDevices() {
        Task {
            do {
                struct DeviceResp: Decodable { let device_id: String?; let name: String?; let info: String?; let is_current: Bool? }
                struct DeviceListResp: Decodable { let data: [DeviceResp]? }
                let resp: DeviceListResp = try await APIClient.shared.requestRaw(.getDeviceList)
                let items = (resp.data ?? []).map {
                    DeviceItem(
                        deviceId: $0.device_id ?? UUID().uuidString,
                        name: $0.name ?? "未知设备",
                        info: $0.info ?? "",
                        isCurrent: $0.is_current ?? false
                    )
                }
                DispatchQueue.main.async {
                    self.devices = items
                    self.tableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    self.devices = [
                        DeviceItem(
                            deviceId: "local",
                            name: UIDevice.current.name,
                            info: "iOS \(UIDevice.current.systemVersion) - 当前设备",
                            isCurrent: true
                        )
                    ]
                    self.tableView.reloadData()
                    AppUtility.showToast("设备列表加载失败")
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(devices.count, 1)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "已登录设备"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        cell.textLabel?.font = ScreenAdapter.font(16)

        if devices.isEmpty {
            cell.textLabel?.text = "暂无设备记录"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
            cell.imageView?.image = nil
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .none
            return cell
        }

        let device = devices[indexPath.row]
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = device.info
        cell.detailTextLabel?.font = ScreenAdapter.font(12)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.imageView?.image = UIImage(systemName: device.isCurrent ? "iphone" : "laptopcomputer")
        cell.imageView?.tintColor = device.isCurrent ? .themePrimary : .secondaryLabel
        cell.accessoryType = device.isCurrent ? .none : .disclosureIndicator
        cell.selectionStyle = device.isCurrent ? .none : .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !devices.isEmpty else { return }
        let device = devices[indexPath.row]
        guard !device.isCurrent else { return }

        let alert = UIAlertController(
            title: "下线设备",
            message: "确定要下线「\(device.name)」吗？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "下线", style: .destructive) { [weak self] _ in
            self?.kickDevice(deviceId: device.deviceId, index: indexPath.row)
        })
        present(alert, animated: true)
    }

    private func kickDevice(deviceId: String, index: Int) {
        Task {
            do {
                _ = try await APIClient.shared.requestRaw(.kickDevice(deviceId: deviceId))
                DispatchQueue.main.async {
                    self.devices.remove(at: index)
                    self.tableView.reloadData()
                    AppUtility.showToast("设备已下线")
                }
            } catch {
                DispatchQueue.main.async {
                    AppUtility.showToast("下线失败，请重试")
                }
            }
        }
    }
}
