import CoreAudioKit
import SwiftUI

#if os(iOS)
typealias HostingController = UIHostingController
#elseif os(macOS)
typealias HostingController = NSHostingController

extension NSView {
    func bringSubviewToFront(_ view: NSView) {
        // No-op for macOS
    }
}
#endif

public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    var audioUnit: AUAudioUnit?
    var hostingController: HostingController<DigitaktAUv3View>?
    var needsConnection = true

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureSwiftUIView()
    }

    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        audioUnit = try DigitaktAUv3AudioUnit(componentDescription: componentDescription, options: [])
        DispatchQueue.main.async {
            self.configureSwiftUIView()
        }
        return audioUnit!
    }

    private func configureSwiftUIView() {
        let contentView = DigitaktAUv3View()
        let hostingController = HostingController(rootView: contentView)

        if let existingHost = self.hostingController {
            existingHost.removeFromParent()
            existingHost.view.removeFromSuperview()
        }

        self.addChild(hostingController)
        hostingController.view.frame = self.view.bounds
        self.view.addSubview(hostingController.view)
        self.hostingController = hostingController

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
}
