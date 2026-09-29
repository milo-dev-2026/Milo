import UIKit

// MARK: - Stub view controllers
// Placeholder implementations to resolve missing-type compile errors.

class NoteSelectViewController: UIViewController {
    var onNoteSelected: ((NoteEntity) -> Void)?
}

class SettingMainViewController: UIViewController {}

class BlacklistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
