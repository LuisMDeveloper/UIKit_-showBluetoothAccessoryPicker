import Combine
import ExternalAccessory
import UIKit

class BluetoothAccessoryPickerViewController: UIViewController {
  private var cancellables = Set<AnyCancellable>()
  private let statusLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.numberOfLines = 0
    label.text = "Bluetooth Accessory Picker Demo"
    return label
  }()

  private let selectAccessoryButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("Select Bluetooth Accessory", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .blue
    button.layer.cornerRadius = 10
    button.addTarget(self, action: #selector(showBluetoothAccessoryPicker), for: .touchUpInside)
    return button
  }()

  private let listAccessoriesButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("List Available Accessories", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .orange
    button.layer.cornerRadius = 10
    button.addTarget(self, action: #selector(listAvailableAccessories), for: .touchUpInside)
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupUI()

    EAAccessoryManager.shared().registerForLocalNotifications()

    NotificationCenter.default
      .publisher(for: .EAAccessoryDidConnect, object: nil)
      .sink { notification in
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else { return }
        print("Accessory connected: \(accessory.name)")
      }
      .store(in: &cancellables)

    NotificationCenter.default
      .publisher(for: .EAAccessoryDidDisconnect, object: nil)
      .sink { notification in
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else { return }
        print("Accessory disconnected: \(accessory.name)")
      }
      .store(in: &cancellables)
  }

  private func setupUI() {
    view.addSubview(statusLabel)
    view.addSubview(selectAccessoryButton)
    view.addSubview(listAccessoriesButton)

    NSLayoutConstraint.activate([
      statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      selectAccessoryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      selectAccessoryButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
      selectAccessoryButton.widthAnchor.constraint(equalToConstant: 250),
      selectAccessoryButton.heightAnchor.constraint(equalToConstant: 50),

      listAccessoriesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      listAccessoriesButton.topAnchor.constraint(
        equalTo: selectAccessoryButton.bottomAnchor, constant: 20),
      listAccessoriesButton.widthAnchor.constraint(equalToConstant: 250),
      listAccessoriesButton.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  @objc private func showBluetoothAccessoryPicker() {
    let options: [String: Any] = [:]
    statusLabel.text = "Attempting to show Bluetooth picker..."
    let name = "YourAccessoryName"  // Replace with your accessory name
    var nameFilter: NSPredicate? = NSPredicate(format: "name CONTAINS %@", name)
    nameFilter = nil  // Comment this line to filter by name
    DispatchQueue.main.async {
      EAAccessoryManager.shared().showBluetoothAccessoryPicker(withNameFilter: nameFilter) {
        [weak self] error in
        print("Bluetooth picker completed.")
        DispatchQueue.main.async {
          if let error = error {
            switch (error as NSError).code {
            case EABluetoothAccessoryPickerError.alreadyConnected.rawValue:
              self?.statusLabel.text = "Accessory is already connected."
            case EABluetoothAccessoryPickerError.resultCancelled.rawValue:
              self?.statusLabel.text = "Picker was cancelled."
            case EABluetoothAccessoryPickerError.resultFailed.rawValue:
              self?.statusLabel.text = "Failed to connect to the accessory."
            case EABluetoothAccessoryPickerError.resultNotFound.rawValue:
              self?.statusLabel.text = "Accessory not found."
            default:
              self?.statusLabel.text = "An unknown error occurred: \(error.localizedDescription)"
            }
          } else {
            self?.statusLabel.text = "Accessory connected successfully!"
          }
        }
      }
    }
  }

  @objc private func listAvailableAccessories() {
    let accessories = EAAccessoryManager.shared().connectedAccessories
    print("connectedAccessories")
    if accessories.isEmpty {
      statusLabel.text = "No accessories found."
    } else {
      let accessoryNames = accessories.map { $0.name }.joined(separator: ", ")
      statusLabel.text = "Found accessories: \(accessoryNames)"
      print("Connected accessories: \(accessoryNames)")
    }
  }
}

#if canImport(SwiftUI) && DEBUG
  import SwiftUI
  struct BluetoothAccessoryPickerViewController_Previews: PreviewProvider {
    static var previews: some View {
      UIViewControllerPreview {
        BluetoothAccessoryPickerViewController()
      }
    }
  }

  struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController

    init(_ builder: @escaping () -> ViewController) {
      viewController = builder()
    }

    func makeUIViewController(context: Context) -> ViewController {
      return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
  }
#endif
