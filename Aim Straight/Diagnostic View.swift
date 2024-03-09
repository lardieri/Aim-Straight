//
//  Diagnostic View.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit

class DiagnosticView: UIView {

    // MARK: Outlets

    @IBOutlet weak var gravityXLabel: UILabel!
    @IBOutlet weak var gravityYLabel: UILabel!
    @IBOutlet weak var gravityZLabel: UILabel!

    @IBOutlet weak var signLabel: UILabel!
    @IBOutlet weak var axisLabel: UILabel!

    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!

    // MARK: Public properties

    var viewModel: ViewModel? = nil

    // MARK: Private methods

    func update() {
        guard let attitude = viewModel?.getExtendedAttitude() else { return }

        OperationQueue.main.addOperation { [weak self] in
            guard let self = self else { return }
            self.internalUpdate(attitude)
        }
    }

    private func internalUpdate(_ extendedAttitude: ViewModel.ExtendedAttitude) {
        assert(OperationQueue.current == .main)

        gravityXLabel.text = format(extendedAttitude.gravityX)
        gravityYLabel.text = format(extendedAttitude.gravityY)
        gravityZLabel.text = format(extendedAttitude.gravityZ)

        signLabel.text = "\(extendedAttitude.sign)"
        axisLabel.text = "\(extendedAttitude.axis)"

        pitchLabel.text = format(extendedAttitude.attitude.pitch)
        rollLabel.text = format(extendedAttitude.attitude.roll)
    }

    private func format(_ number: Double) -> String {
        return String(format: "%+.2f", number)
    }

    // MARK: Private properties

    private var observer: NSObjectProtocol? = nil

}
