//
//  TastyToast.swift
//  TastyToast
//
//  Created by Beatman on 2020/12/9.
//

import Foundation
import UIKit

class Toasty {
    
    var config: ToastUIConfig!
    
    class func show(title: String = "", content: String, _ uiConfig: ToastUIConfig = ToastUIConfig.defaultConfig) {
        let contentConfig = ToastContentConfig(title: title, content: content)
        TastyToast.shared.makeToast(with: uiConfig, contentConfig: contentConfig)
    }
    
    class func flash(delay: CGFloat = 1.0, title: String = "", content: String, _ uiConfig: ToastUIConfig = ToastUIConfig.defaultConfig) {
        let contentConfig = ToastContentConfig(title: title, content: content)
        TastyToast.shared.makeFlashToast(delay: delay, uiConfig, contentConfig: contentConfig)
    }
    
    class func hide() {
        TastyToast.shared.hideToast()
    }
    
}

class TastyToast {
    
    static let shared = TastyToast()
    
    private var toast: ToastContainer?
    private weak var timer: Timer? = nil
    private var toastShowing: Bool = false
    
    private init() { }
    
    func makeToast(with uiConfig: ToastUIConfig = ToastUIConfig(), contentConfig: ToastContentConfig) {
        if !toastShowing {
            self.timer?.invalidate()
            self.toast = ToastContainer(uiConfig: uiConfig, contentConfig: contentConfig)
            UIApplication.shared.keyWindow?.addSubview(self.toast!)
            self.toast?.show()
            self.toastShowing = true
        }
    }
    
    func makeFlashToast(delay: CGFloat, _ uiConfig: ToastUIConfig = ToastUIConfig.defaultConfig, contentConfig: ToastContentConfig) {
        self.makeToast(with: uiConfig, contentConfig: contentConfig)
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(delay), target: self, selector: #selector(hideToast), userInfo: nil, repeats: false)
    }
    
    @objc func hideToast() {
        self.toast?.hide()
        self.timer?.invalidate()
        self.toastShowing = false
    }
    
}

internal class ToastContainer: UIView {
    
    private var contentLabel: UILabel!
    private var titleLabel: UILabel!
    private var uiConfig: ToastUIConfig!
    private var contentConfig: ToastContentConfig!
    private let textPadding: CGFloat = 5
    
    init(uiConfig: ToastUIConfig, contentConfig: ToastContentConfig) {
        super.init(frame: .zero)
        self.uiConfig = uiConfig
        self.contentConfig = contentConfig
        self.setupUI()
    }
    
    func show() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    private func setupUI() {
        self.alpha = 0
        self.backgroundColor = uiConfig.backgroundColor
        self.layer.cornerRadius = uiConfig.cornerRadius
        self.layer.masksToBounds = true
        self.layer.borderWidth = uiConfig.borderWidth
        self.layer.borderColor = uiConfig.borderColor.cgColor
        let titleCalculateHeight = contentConfig.title?.height(width: uiConfig.estimateWidth-20, font: uiConfig.titleFont) ?? 0
        let titleHeight = (contentConfig.title?.count ?? 0) > 0 ? titleCalculateHeight : 0
        let contentHeight = contentConfig.content?.height(width: uiConfig.estimateWidth-20, font: uiConfig.contentFont) ?? 0
        let heightOffset = textPadding * ((contentConfig.title?.count ?? 0) > 0 ? 3 : 2)
        let bottomOffScreenHeight: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        self.frame = CGRect(x: UIScreen.main.bounds.width/2 - uiConfig.estimateWidth/2,
                            y: UIScreen.main.bounds.height - bottomOffScreenHeight - uiConfig.bottomOffset - titleHeight - contentHeight,
                            width: uiConfig.estimateWidth,
                            height: titleHeight + contentHeight + heightOffset)
        self.titleLabel = UILabel(frame: CGRect(x: textPadding, y: textPadding, width: self.frame.width-textPadding*2, height: (contentConfig.title?.count  ?? 0) > 0 ? titleHeight : 0))
        let titleLabelTop: CGFloat = (contentConfig.title?.count ?? 0) > 0 ? 5 : 0
        self.contentLabel = UILabel(frame: CGRect(x: 10, y: titleLabel.frame.height + titleLabelTop + textPadding, width: self.frame.width-20, height: contentHeight))
        self.titleLabel.numberOfLines = 0
        self.contentLabel.numberOfLines = 0
        self.titleLabel.textColor = uiConfig.titleColor
        self.contentLabel.textColor = uiConfig.contentColor
        self.titleLabel.font = uiConfig.titleFont
        self.contentLabel.font = uiConfig.contentFont
        self.titleLabel.text = contentConfig.title
        self.contentLabel.text = contentConfig.content
        self.titleLabel.textAlignment = .center
        self.contentLabel.textAlignment = .center
        self.addSubview(titleLabel)
        self.addSubview(contentLabel)
        if uiConfig.tapDiappearEnabled {
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.hide))
            self.addGestureRecognizer(tap)
        }
        if uiConfig.shadowEnabled {
            self.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
            self.layer.shadowOffset = CGSize(width: 1, height: 1)
            self.layer.shadowRadius = 4
            self.layer.shadowOpacity = 0.8
            self.layer.masksToBounds = false
        }
    }
    
    @objc func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

struct ToastContentConfig {
    var title: String?
    var content: String!
}

struct ToastUIConfig {
    
    var backgroundColor = UIColor.black.withAlphaComponent(0.6)
    var titleColor: UIColor = UIColor.white
    var titleFont: UIFont = UIFont.systemFont(ofSize: 14)
    var contentColor: UIColor = UIColor.white
    var contentFont: UIFont = UIFont.systemFont(ofSize: 12)
    var cornerRadius: CGFloat = 8.0
    var borderWidth: CGFloat = 1
    var borderColor: UIColor = .clear
    var bottomOffset: CGFloat = 44
    var estimateWidth: CGFloat = UIScreen.main.bounds.width/4
    var tapDiappearEnabled: Bool = true
    var shadowEnabled: Bool = true
    
    static let defaultConfig: ToastUIConfig = ToastUIConfig()
    
}

extension String {
    func height(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}
