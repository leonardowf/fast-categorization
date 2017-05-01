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

    private var itemViews: [UIView] = []

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
            onLongPressEnded(gesture: gesture)
        } else if gesture.state == .changed {
            onLongPressChanged(gesture: gesture)
        }
    }

    private func onLongPressBegan() {
        longPressing = true
        insertAndAnimateCircleHighlight()
        addAndAnimateBackgroundView()
        addCloneViews()
        addItemViews()
    }

    private func onLongPressChanged(gesture: UILongPressGestureRecognizer) {
        animateIncreaseOfHighlightedItemView(gesture: gesture)
    }

    private func onLongPressEnded(gesture: UILongPressGestureRecognizer) {
        longPressing = false
        animateAndRemoveCircleHighlight()
        animateHighlightedItemViewBackToNormalSize(gesture: gesture)

        removeItemViews {
            self.animateAndRemoveBackgroundView()
            self.removeCloneViews()
        }
    }

    private func pointAtDegree(zeroPoint: CGPoint, degree: Int, radius: CGFloat) -> CGPoint {
        let x = zeroPoint.x + radius * cos(degree.degreesToRadians)
        let y = zeroPoint.y + radius * sin(degree.degreesToRadians)

        let point = CGPoint(x: x, y: y)
        return point
    }

    private func animateHighlightedItemViewBackToNormalSize(gesture: UILongPressGestureRecognizer) {
        let items = highlightedItemViews(gesture: gesture)

        for highlightedItemView in items {
            UIView.animate(withDuration: 0.05) {
                let scale: CGFloat = 1.0
                highlightedItemView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }

    private func centerPointAtWindow() -> CGPoint {
        guard let window = UIApplication.shared.keyWindow else {
            return CGPoint.zero
        }

        let centerPoint = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        let zeroPoint = self.convert(centerPoint, to: window)
        return zeroPoint
    }

    private func calculateItemPoints() -> [CGPoint] {
        let zeroPoint = centerPointAtWindow()
        let r = radius()
        let quantityOfItems = numberOfItems()

        var points: [CGPoint] = []

        let degreesByItem = 160 / (quantityOfItems - 1)
        var evenNumberOfItemsOffset = 0

        if quantityOfItems % 2 == 0 {
            evenNumberOfItemsOffset = degreesByItem / 2
        } else {
            let point = pointAtDegree(zeroPoint: zeroPoint, degree: 0, radius: r)
            points.append(point)
        }

        for index in 1...quantityOfItems / 2 {
            let degree = index * degreesByItem - 1 * evenNumberOfItemsOffset
            let point = pointAtDegree(zeroPoint: zeroPoint, degree: degree, radius: r)

            points.append(point)
        }

        for index in 1...quantityOfItems / 2 {
            let degree = -1 * index * degreesByItem + evenNumberOfItemsOffset
            let point = pointAtDegree(zeroPoint: zeroPoint, degree: degree, radius: r)

            points.append(point)
        }

        points = points.sorted(by: { (lpoint, rpoint) -> Bool in
            return lpoint.y < rpoint.y
        })

        return points
    }

    private func addItemViews() {
        let centerPoint = centerPointAtWindow()
        let points = calculateItemPoints()

        let itemSize = CGSize(width: 40, height: 40)

        var delay = 0.2

        itemViews = []
        for (index, point) in points.enumerated() {
            let view = viewForItem(itemIndex: index)

            let viewOrigin = CGPoint(x: centerPoint.x - itemSize.width / 2, y: centerPoint.y - itemSize.height / 2)
            var viewFrame = view.frame
            viewFrame.origin = viewOrigin
            view.frame = viewFrame

            windowContainerView?.addSubview(view)
            windowContainerView?.sendSubview(toBack: view)
            itemViews.append(view)

            UIView.animate(withDuration: 0.4,
                    delay: delay,
                    usingSpringWithDamping: 0.5,
                    initialSpringVelocity: 0.3,
                    options: UIViewAnimationOptions.curveEaseInOut, animations: {

                let size = view.frame.size
                let endPosition = CGPoint(x: point.x - viewFrame.size.width / 2, y: point.y - itemSize.height / 2)
                let endFrame = CGRect(origin: endPosition, size: size)

                view.frame = endFrame

            }, completion: { (finished) in

            })

            delay = delay + 0.05
        }
    }

    private func rotatePointByDegree(point: CGPoint, degree: Int, c0: CGPoint) -> CGPoint {
        let xrot = cos(degree.degreesToRadians) * (point.x - c0.x) - sin(degree.degreesToRadians) * (point.y - c0.y) + c0.x
        let yrot = sin(degree.degreesToRadians) * (point.x - c0.x) + cos(degree.degreesToRadians) * (point.y - c0.y) + c0.y

        return CGPoint(x: xrot, y: yrot)
    }

    private func insertAndAnimateCircleHighlight() {
        let circle = buildCircleHighlight()
        cloneOfCircleHighlightView = buildCircleHighlight()

        self.superview?.addSubview(circle)
        circleHighlightView = circle
        self.superview?.sendSubview(toBack: circle)

        UIView.animate(withDuration: 0.3,
                delay: 0.0,
                usingSpringWithDamping: 0.3,
                initialSpringVelocity: 0.7,
                options: UIViewAnimationOptions.curveEaseInOut,
                animations: {

            let scale: CGFloat = 1.5
            circle.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.cloneOfCircleHighlightView?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }) { (finished) in

        }
    }

    private func buildCircleHighlight() -> UIView {
        let circle = UIView(frame: self.frame)
        circle.layer.cornerRadius = circle.frame.size.width / 2
        circle.backgroundColor = UIColor.red
        circle.alpha = 0.5

        return circle
    }

    private func animateAndRemoveCircleHighlight() {
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

    private func animateIncreaseOfHighlightedItemView(gesture: UILongPressGestureRecognizer) {
        for (index, view) in itemViews.enumerated() {
            let location = gesture.location(in: view)
            if view.point(inside: location, with: nil) {
                UIView.animate(withDuration: 0.3) {
                    let scale: CGFloat = 1.2
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            } else {
                UIView.animate(withDuration: 0.1) {
                    let scale: CGFloat = 1.0
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            }
        }
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

    private func highlightedItemViews(gesture: UILongPressGestureRecognizer) -> [UIView] {
        var highlightedItemViews: [UIView] = []
        for (index, view) in itemViews.enumerated() {
            let location = gesture.location(in: view)
            if view.point(inside: location, with: nil) {
                highlightedItemViews.append(view)
            }
        }

        return highlightedItemViews
    }

    private func removeItemViews(completion: @escaping ((Void) -> Void)) {
        let initialPoint = centerPointAtWindow()

        var delay = 0.0
        for (index, view) in itemViews.enumerated() {
            UIView.animate(withDuration: 0.2,
                    delay: delay,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 0.0,
                    options: UIViewAnimationOptions.curveLinear, animations: {

                var viewFrame = view.frame
                var destinationPoint = initialPoint
                destinationPoint.x -= viewFrame.width / 2
                destinationPoint.y -= viewFrame.height / 2
                viewFrame.origin = destinationPoint
                view.frame = viewFrame

                delay += 0.05
            }, completion: { finished in
                if index == self.itemViews.count - 1 {
                    completion()
                }
             })
        }
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
        view.layer.cornerRadius = self.frame.width / 2

        view.backgroundColor = UIColor.blue

        return view
    }

    func numberOfItems() -> Int {
        return 5
    }

    func viewForItem(itemIndex: Int) -> UIView {
        let viewRect = CGRect(x: 0, y: 0, width: 40, height: 40)
        let view = UIView(frame: viewRect)
        view.backgroundColor = UIColor.purple
        view.layer.cornerRadius = viewRect.size.height / 2
        return view
    }

    func radius() -> CGFloat {
        return 70.0
    }
}

extension Int {
    var degreesToRadians: CGFloat { return CGFloat(self) * .pi / 180 }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
