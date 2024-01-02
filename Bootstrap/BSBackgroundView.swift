import UIKit
import ColorfulX

@objc class BSBackgroundView: UIView {
    lazy var colorfulBackgroundView: UIView = {
        let view = AnimatedMulticolorGradientView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.setColors([
            RGBColor(r: 22/255, g: 4/255, b: 74/255),
            RGBColor(r: 240/255, g: 54/255, b: 248/255),
            RGBColor(r: 79/255, g: 216/255, b: 248/255),
            RGBColor(r: 74/255, g: 0/255, b: 217/255),
        ], interpolationEnabled: true)
        view.speed = 0.25
        view.transitionDuration = 5.0
        view.frameLimit = 30
        view.alpha = 0.25
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .black
        colorfulBackgroundView.frame = self.bounds
        insertSubview(colorfulBackgroundView, at: 0)
    }
}
