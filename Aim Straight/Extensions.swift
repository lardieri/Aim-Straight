//
//  Extensions.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit


extension CALayer {

    // Note: does *not* include `self` if `self` is T — that's up to you to figure out.
    // Call: someLayer.sublayers(ofType: FooLayer.self)
    func sublayers<T>(ofType t: T.Type) -> [T] where T: CALayer {
        guard let sublayers = sublayers else { return [] }
        return sublayers.compactMap { $0 as? T } + sublayers.flatMap { $0.sublayers(ofType: t) }
    }

}


extension UIView {

    func firstSubviewWithLayer<T>(ofType t: T.Type) -> UIView? where T: CALayer {
        var layer: CALayer? = self.layer.sublayers(ofType: T.self).first

        while layer != nil {
            if let view = layer!.delegate as? UIView {
                return view
            } else {
                layer = layer!.superlayer
            }
        }

        return nil
    }

}
