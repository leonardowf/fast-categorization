//
//  ItemExplosionMenu.swift
//  fast-categorization
//
//  Created by Leonardo Wistuba de França on 4/27/17.
//  Copyright © 2017 Leonardo. All rights reserved.
//

import UIKit

class ItemExplosionMenu: UIView {
    private weak var circleHighlightView: UIView?
    private weak var backgroundView: UIView?


    private var longPressing = false

    private var cloneOfCircleHighlightView: UIView?
    private weak var cloneOfContentView: UIView?
    private weak var windowContainerView: UIView?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    private func setup() {
        addContentView()
        addLongPressGestureRecognizer()

    }

    private func addContentView() {
        let viewToAdd = contentView()
        viewToAdd.translatesAutoresizingMaskIntoConstraints = false

        addSubview(viewToAdd)

        let constraintsAttributes: [NSLayoutAttribute] = [.top, .leading, .trailing, .bottom]
        let constraints = constraintsAttributes.map { (layoutAttribute) -> NSLayoutConstraint in
            NSLayoutConstraint(item: viewToAdd,
                               attribute: layoutAttribute,
                               relatedBy: NSLayoutRelation.equal,
                               toItem: self,
                               attribute: layoutAttribute,
                               multiplier: 1.0,
                               constant: 0.0)
        }

        addConstraints(constraints)
    }

    private func addLongPressGestureRecognizer() {
        let onLongPressSelector = #selector(ItemExplosionMenu.onLongPress(gesture:))
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: onLongPressSelector)
        longPressGesture.minimumPressDuration = 0.0625
        addGestureRecognizer(longPressGesture)
    }

    func onLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            onLongPressBegan()
        } else if gesture.state == .ended {
            onLongPressEnded()
        }
    }

    private func onLongPressBegan() {
        longPressing = true
        insertAndAnimateCircleHighlight()
        addAndAnimateBackgroundView()
        addCloneViews()
    }

    private func onLongPressEnded() {
        longPressing = false
        animateAndRemoveCircleHightlight()
        animateAndRemoveBackgroundView()
        removeCloneViews()
    }

    private func insertAndAnimateCircleHighlight() {
        let circle = buildCircleHightlight()
        cloneOfCircleHighlightView = buildCircleHightlight()

        self.superview?.addSubview(circle)
        circleHighlightView = circle
        self.superview?.sendSubview(toBack: circle)

        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.curveEaseInOut, animations: {
            let scale: CGFloat = 1.5
            circle.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.cloneOfCircleHighlightView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { (finished) in

        }
    }

    private func buildCircleHightlight() -> UIView {
        let circle = UIView(frame: self.frame)
        circle.layer.cornerRadius = circle.frame.size.width / 2
        circle.backgroundColor = UIColor.red
        circle.alpha = 0.5

        return circle
    }

    private func animateAndRemoveCircleHightlight() {
        UIView.animate(withDuration: 0.3, animations: {
            let scale: CGFloat = 0.5
            self.circleHighlightView?.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.cloneOfCircleHighlightView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { (finished) in
            if finished {
                if !self.longPressing {
                    self.cloneOfCircleHighlightView?.removeFromSuperview()
                    self.circleHighlightView?.removeFromSuperview()
                }

            }
        }
    }

    private func addAndAnimateBackgroundView() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let backgroundView = UIView(frame: window.frame)
        backgroundView.backgroundColor = UIColor.black

        backgroundView.alpha = 0.0
        UIView.animate(withDuration: 0.2) { 
            backgroundView.alpha = 0.2
        }

        window.addSubview(backgroundView)

        let windowContainerView = UIView(frame: window.frame)
        window.addSubview(windowContainerView)

        self.windowContainerView = windowContainerView
        self.backgroundView = backgroundView

    }

    private func addCloneViews() {
        guard let window = UIApplication.shared.keyWindow,
            let circleHighlightView = circleHighlightView,
            let cloneOfCircleHighlightView = cloneOfCircleHighlightView else {
            return
        }

        let circleHighlightViewReferencePoint = circleHighlightView.convert(CGPoint.zero, to: window)
        var circleHighlightViewFrame = circleHighlightView.frame
        circleHighlightViewFrame.origin = circleHighlightViewReferencePoint
        cloneOfCircleHighlightView.frame = circleHighlightViewFrame

        let contentViewReferencePoint = self.convert(CGPoint.zero, to: window)
        let cloneContentView = contentView()
        var contentViewFrameFrame = self.frame
        contentViewFrameFrame.origin = contentViewReferencePoint
        cloneContentView.frame = contentViewFrameFrame

        windowContainerView?.addSubview(cloneOfCircleHighlightView)
        windowContainerView?.addSubview(cloneContentView)

        self.cloneOfContentView = cloneContentView
    }

    private func removeCloneViews() {
        self.windowContainerView?.removeFromSuperview()
        self.cloneOfCircleHighlightView?.removeFromSuperview()
        self.cloneOfCircleHighlightView = nil

    }

    private func animateAndRemoveBackgroundView() {
        backgroundView?.removeFromSuperview()
    }

    func contentView() -> UIView {
        let view = UIView(frame: CGRect.zero)

        view.backgroundColor = UIColor.yellow

        return view

    }

}
