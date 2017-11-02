//
//  JYCustomAlertView.swift
//  JYCustomAlertView
//
//  Created by hb on 2017/9/4.
//  Copyright © 2017年 com.bm.hb. All rights reserved.
//

import UIKit

public let kCustomAlertViewDefaultButtonHeight: CGFloat = 50
public let kCustomAlertViewDefaultButtonSpacerHeight: CGFloat = 1
public let kCustomAlertViewCornerRadius: CGFloat = 5
public let kCustomMotionEffectExtent: CGFloat = 10

public var buttonHeight: CGFloat = 0
public var buttonSpacerHeight: CGFloat = 0

enum JYCustomAlertViewPositon {
    case center // 默认center
    case bottom
    case top
}

class JYCustomAlertView: UIView {
    
    var parentView: UIView! = nil // 父视图
    var dialogView: UIView! = nil // 弹出框
    var containerView: UIView! = nil //弹出框内的容器视图
    var buttonTitles = [String]() // 底部的标题数组
    var useMotionEffects = false // 是否启用视觉差效果
    var closeOnTouchUpOutside = true // 是否点击背景隐藏视图
    var onButtonTouchUpInside: ((JYCustomAlertView, Int) -> ())? = nil // 按钮点击的回调
    /// style
    var positon = JYCustomAlertViewPositon.center // 默认居中
    var showCornerRadius = true // 默认显示圆角
    /// ^^^
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
    }
    
    public convenience init() {
        self.init(frame: .zero)
        
        if parentView != nil {
            self.frame = parentView!.frame
        } else {
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        }
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /// 重写
    ///
    /// - Parameters:
    ///   - touches: touches
    ///   - event: event
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !closeOnTouchUpOutside {
            return
        }
        let touch = (touches as NSSet).anyObject() as! UITouch
        if touch.view is JYCustomAlertView {
            self.close()
        }
    }
}


// MARK: - helper
extension JYCustomAlertView {
    
    /// count and return the screen's size
    ///
    /// - Returns: 尺寸
    fileprivate func countScreenSize() -> CGSize {
        if buttonTitles.count > 0 {
            buttonHeight = kCustomAlertViewDefaultButtonHeight
            buttonSpacerHeight = kCustomAlertViewDefaultButtonSpacerHeight
        } else {
            buttonHeight = 0
            buttonSpacerHeight = 0
        }
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        return CGSize(width: screenWidth, height: screenHeight)
    }
    
    /// count and return the dialog's size
    ///
    /// - Returns: 尺寸
    fileprivate func countDialogSize() -> CGSize {
        if containerView == nil {
            return CGSize(width: 300, height: 150)
        }
        let dialogWidth = containerView.frame.size.width
        let dialogHeight = containerView.frame.size.height + buttonHeight + buttonSpacerHeight
        return CGSize(width: dialogWidth, height: dialogHeight)
    }
    
    /// Add motion effects
    fileprivate func applyMotionEffects() {
        let horizontalEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalEffect.minimumRelativeValue = -kCustomMotionEffectExtent
        horizontalEffect.maximumRelativeValue = kCustomMotionEffectExtent
        
        let verticalEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalEffect.minimumRelativeValue = -kCustomMotionEffectExtent
        verticalEffect.maximumRelativeValue = kCustomMotionEffectExtent
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalEffect, verticalEffect]
        dialogView.addMotionEffect(motionEffectGroup)
    }
    
    /// add buttons to container
    ///
    /// - Parameter container: container
    fileprivate func addButtons(to container: UIView) {
        if buttonTitles.count == 0 {
            return
        }
        
        let buttonWidth = container.bounds.size.width / CGFloat(buttonTitles.count)
        
        for i in 0..<buttonTitles.count {
            let closeButton = UIButton(type: .custom)
            closeButton.frame = CGRect(x: CGFloat(i) * buttonWidth,
                                       y: container.bounds.size.height - buttonHeight,
                                       width: buttonWidth,
                                       height: buttonHeight)
            closeButton.addTarget(self, action: #selector(self.customDialogButtonTouchUpInside(sender:)), for: .touchUpInside)
            closeButton.tag = i
            closeButton.setTitle(buttonTitles[i], for: .normal)
            closeButton.setTitleColor(UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0), for: .normal)
            closeButton.setTitleColor(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0), for: .highlighted)
            closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
            closeButton.titleLabel?.numberOfLines = 0
            closeButton.titleLabel?.textAlignment = .center
            closeButton.layer.cornerRadius = kCustomAlertViewCornerRadius
            container.addSubview(closeButton)
        }
    }
    
    /// Button has been touched
    @objc fileprivate func customDialogButtonTouchUpInside(sender: UIButton) {
        if let clouser = onButtonTouchUpInside {
            clouser(self, sender.tag)
        }
    }
    
    /// 创建默认的内容容器
    ///
    /// - Returns: 容器视图
    fileprivate func createContainerView() -> UIView {
        
        if containerView == nil {
            containerView = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 150))
        }
        
        let screenSize = self.countScreenSize()
        let dialogSize = self.countDialogSize()
        // For the black background
        self.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        
        // This is the dialog's container; we attach the custom content and the buttons to this one
        var rect = CGRect.zero
        switch positon {
        case .center:
            rect = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                          y: (screenSize.height - dialogSize.height) / 2,
                          width: dialogSize.width,
                          height: dialogSize.height)
        case .bottom:
            rect = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                          y: self.frame.size.height - dialogSize.height,
                          width: dialogSize.width,
                          height: dialogSize.height)
        case .top:
            rect = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                          y: 0,
                          width: dialogSize.width,
                          height: dialogSize.height)
        }
        
        let dialogContainer = UIView(frame: rect)
        
        // First, we style the dialog to match the iOS7 UIAlertView >>>
        let gradient = CAGradientLayer()
        gradient.frame = dialogContainer.bounds
        
        gradient.colors = [UIColor(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1).cgColor,
                           UIColor(red: 233.0/255.0, green: 233.0/255.0, blue: 233.0/255.0, alpha: 1).cgColor,
                           UIColor(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1).cgColor] as [Any]
        
        let cornerRadius = kCustomAlertViewCornerRadius
        if showCornerRadius {
            gradient.cornerRadius = cornerRadius
            dialogContainer.layer.cornerRadius = cornerRadius
            //            dialogContainer.layer.borderColor = UIColor(red: 198.0/255.0, green: 198.0/255.0, blue: 198.0/255.0, alpha: 1).cgColor
            //            dialogContainer.layer.borderWidth = 1
        }
        dialogContainer.layer.insertSublayer(gradient, at: 0)
        dialogContainer.layer.shadowRadius = cornerRadius + 5
        dialogContainer.layer.shadowOpacity = 0.1
        dialogContainer.layer.shadowOffset = CGSize(width: 0 - (cornerRadius + 5) / 2, height: 0 - (cornerRadius + 5) / 2)
        dialogContainer.layer.shadowColor = UIColor.black.cgColor
        dialogContainer.layer.shadowPath = UIBezierPath(roundedRect: dialogContainer.bounds, cornerRadius: dialogContainer.layer.cornerRadius).cgPath
        
        // There is a line above the button
        let line = UIView(frame: CGRect(x: 0,
                                        y: dialogContainer.bounds.size.height - buttonHeight - buttonSpacerHeight,
                                        width: dialogContainer.bounds.size.width,
                                        height: buttonSpacerHeight))
        line.backgroundColor = UIColor(red: 198.0/255.0, green: 198.0/255.0, blue: 198.0/255.0, alpha: 1)
        dialogContainer.addSubview(line)
        // ^^^
        
        // add the custom container if there is any
        dialogContainer.addSubview(self.containerView)
        
        // add the buttons too
        self.addButtons(to: dialogContainer)
        
        return dialogContainer
    }
}


// MARK: - 外界调用来显示和隐藏
extension JYCustomAlertView {
    
    /// Create the dialog view, and animate opening the dialog
    public func show() {
        dialogView = self.createContainerView()
        
        dialogView.layer.shouldRasterize = true
        dialogView.layer.rasterizationScale = UIScreen.main.scale
        dialogView.layer.masksToBounds = true
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        
        if useMotionEffects {
            self.applyMotionEffects()
        }
        
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        self.addSubview(dialogView)
        
        // Can be attached to a view or to the top most window
        // Attached to a view:
        if let parentV = parentView {
            parentV.addSubview(self)
        } else {
            // Attached to the top most window
            let screenSize = self.countScreenSize()
            let dialogSize = self.countDialogSize()
            let keyBoardSize = CGSize(width: 0, height: 0)
            
            var dialogViewFrame = CGRect.zero
            switch positon {
            case .center:
                dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                         y: (screenSize.height - keyBoardSize.height - dialogSize.height) / 2,
                                         width: dialogSize.width,
                                         height: dialogSize.height)
            case .bottom:
                dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                         y: self.frame.size.height - dialogSize.height,
                                         width: dialogSize.width,
                                         height: dialogSize.height)
            case .top:
                dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                         y: 0,
                                         width: dialogSize.width,
                                         height: dialogSize.height)
            }
            dialogView.frame = dialogViewFrame
            UIApplication.shared.windows.first!.addSubview(self)
        }
        
        dialogView.layer.opacity = 0.5
        dialogView.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1.0)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
            self.dialogView.layer.opacity = 1.0
            self.dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1)
        }, completion: nil)
    }
    
    /// Dialog close animation then cleaning and removing the view from the parent
    public func close() {
        let currentTransform = dialogView.layer.transform
        dialogView.layer.opacity = 1.0
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
            self.dialogView?.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6, 0.6, 1.0))
            self.dialogView?.layer.opacity = 0.0
        }) { (finished) in
            for v in self.subviews {
                v.removeFromSuperview()
            }
            self.removeFromSuperview()
        }
    }
}

// MARK: - 绑定的通知方法
extension JYCustomAlertView {
    
    /// 设备旋转
    ///
    /// - Parameter notification: 通知对象
    @objc fileprivate func deviceOrientationDidChange(_ notification: Notification) {
        
        // If dialog is attached to the parent view, it probably wants to handle the orientation change itself
        if parentView != nil {
            return
        }
        
        let screenSize = self.countScreenSize()
        let dialogSize = self.countDialogSize()
        var dialogViewFrame = CGRect.zero
        switch positon {
        case .center:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: (screenSize.height - dialogSize.height) / 2,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        case .bottom:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: self.frame.size.height - dialogSize.height,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        case .top:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: 0,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
            self.dialogView?.frame = dialogViewFrame
        }, completion: nil)
    }
    
    /// Handle keyboard show changes
    ///
    /// - Parameter notification: 通知对象
    @objc fileprivate func keyboardWillShow(_ notification: Notification) {
        
        let screenSize = self.countScreenSize()
        let dialogSize = self.countDialogSize()
        var dialogViewFrame = CGRect.zero
        switch positon {
        case .center:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: (screenSize.height - dialogSize.height) / 2,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        case .bottom:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: self.frame.size.height - dialogSize.height,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        case .top:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: 0,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.dialogView?.frame = dialogViewFrame
        }, completion: nil)
    }
    
    /// Handle keyboard hide changes
    ///
    /// - Parameter notification: 通知对象
    @objc fileprivate func keyboardWillHide(_ notification: Notification) {
        
        let screenSize = self.countScreenSize()
        let dialogSize = self.countDialogSize()
        var dialogViewFrame = CGRect.zero
        switch positon {
        case .center:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: (screenSize.height - dialogSize.height) / 2,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        case .bottom:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: self.frame.size.height - dialogSize.height,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        case .top:
            dialogViewFrame = CGRect(x: (screenSize.width - dialogSize.width) / 2,
                                     y: 0,
                                     width: dialogSize.width,
                                     height: dialogSize.height)
        }
        UIView.animate(withDuration: 0.2, delay: 0, animations: {
            self.dialogView?.frame = dialogViewFrame
        }, completion: nil)
    }
}

