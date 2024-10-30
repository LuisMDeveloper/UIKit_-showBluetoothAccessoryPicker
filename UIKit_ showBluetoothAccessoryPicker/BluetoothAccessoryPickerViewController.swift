import Combine
import DatamaxONeilSDK
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

  //Connection_BluetoothEA connection
  var connection: Connection_BluetoothEA?

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
    button.setTitle("Print DPL", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.backgroundColor = .orange
    button.layer.cornerRadius = 10
    button.addTarget(self, action: #selector(printSample), for: .touchUpInside)
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupUI()
    // load our data from a plist file inside our app bundle
    // objective-c code: NSArray *supportedProtocols = [[NSArray alloc] initWithArray:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedExternalAccessoryProtocols"]];
    let supportedProtocols =
      Bundle.main.object(forInfoDictionaryKey: "UISupportedExternalAccessoryProtocols") as? [String]
      ?? []

    EAAccessoryManager.shared().registerForLocalNotifications()
    if connection == nil {
      connection = Connection_BluetoothEA(delegate: self)
    }

    NotificationCenter.default
      .publisher(for: .EAAccessoryDidConnect, object: nil)
      .sink { [weak self] notification in
        guard let self = self else { return }
        guard let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory else { return }
        print("Connecting to accessory: \(accessory.name)")
        //setup connection for selected bluetooth printer
        if accessory.isConnected {
          print("Accessory is already connected by the BluetoothAccessoryPicker")
        }
        print("Supported protocols: \(supportedProtocols)")
        self.connection?.setupConnection(for: accessory, withProtocolString: supportedProtocols[0])
        //Set timeout to 5 seconds
        self.connection?.connTimeout = 5
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
    let name = "Printer"  // Replace with your accessory name
    var nameFilter: NSPredicate? = NSPredicate(format: "SELF CONTAINS[c] %@", name)
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

  func performPrintOperation() {
    if connection == nil {
      print("Printer is not connected")
      return
    }
    // Create a new DPL document
    let documentDPL = DocumentDPL()

    // Configure the DPL document
    documentDPL.writeTextScalable("Hello, World!", withFontID: "00", atRow: 5, atColumn: 5)

    // Get the data from the DPL document
    guard let data = documentDPL.getData() else {
      print("Error getting data from DPL document")
      return
    }

    let dataLength = data.count
    var printData = [UInt8](repeating: 0, count: dataLength)
    data.copyBytes(to: &printData, count: dataLength)

    // Send the DPL document to the printer
    printData.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
      let unsafePointer = pointer.bindMemory(to: UInt8.self).baseAddress
      print("DPL document sent to the printer")
      connection?.writeBytes(unsafePointer, count: dataLength)
      connection?.close()
    }
  }

  @objc private func printSample() {
    self.connection?.open()

  }
}

extension BluetoothAccessoryPickerViewController: ConnectionDelegate {
  func connectionDidOpen(_ connection: Any!) {
    print("Connection did open")
    DispatchQueue.global(qos: .default).async {
      self.performPrintOperation()
    }
  }

  func connectionFailed(_ connection: Any!, withError error: (any Error)!) {
    print("Connection failed")
  }

  func connectionDidClosed(_ connection: Any!) {
    print("Connection did close")
  }

}
