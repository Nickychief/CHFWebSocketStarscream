//
//  CXEditDiglogViewController.swift
//  Test
//
//  Created by 刘远明 on 8/6/23.
//

import UIKit

class CXEditDiglogViewController: UIViewController {
    open var allowsTapToDismiss: Bool = true
    public lazy var dimmedBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewDidPress))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    public lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGroupedBackground
        view.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var containerStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 1
        return view
    }()
    
    public lazy var avgBuyPrice: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.numberOfLines = 0
        return lb
    }()
    
    public lazy var avgBuyPriceDesc: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        
        lb.numberOfLines = 0
        return lb
    }()
    
    public lazy var avgBuyPriceCaluate: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        
        lb.numberOfLines = 0
        return lb
    }()
    
    public lazy var drawPoint: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        return lb
    }()
    
    public lazy var drawPointDesc: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        
        lb.numberOfLines = 0
        return lb
    }()
    
    public lazy var drawPointCaluate: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        
        lb.numberOfLines = 0
        return lb
    }()
    
    public lazy var bottomTipLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.numberOfLines = 0
        
        return lb
    }()
    
    let text1 = UITextField()
    let text2 = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
        setupUI()
        updateData()
        initNotification()
    }
    
    func initNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setupUI() {
        view.addSubview(dimmedBackgroundView)
        view.addSubview(containerView)
//        containerView.addSubview(scrollView)
        containerView.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(avgBuyPrice)
        containerStackView.addArrangedSubview(avgBuyPriceDesc)
        containerStackView.addArrangedSubview(avgBuyPriceCaluate)
        containerStackView.addArrangedSubview(drawPoint)
        containerStackView.addArrangedSubview(drawPointDesc)
        containerStackView.addArrangedSubview(drawPointCaluate)
//        containerStackView.addArrangedSubview(bottomTipLabel)
        
        containerStackView.setCustomSpacing(16, after: avgBuyPriceCaluate)
        containerStackView.setCustomSpacing(16, after: drawPointCaluate)
        
        dimmedBackgroundView.makeViewConstraints(toFitSuperView: view)
//        scrollView.makeViewConstraints(toFitSuperView: containerView)
        containerStackView.makeViewConstraints(toFitSuperView: containerView)
        NSLayoutConstraint.activate([
//            scrollView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            // greaterThanOrEqualTo
            // containerView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            // containerView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            scrollView.heightAnchor.constraint(lessThanOrEqualToConstant: 520),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func updateData() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.08
        
        avgBuyPrice.attributedText = NSMutableAttributedString(string: "PortfolioAvgBuyPriceAndDrawPointDialog_AvgBuyPrice", attributes: [.paragraphStyle: paragraphStyle])
        avgBuyPriceDesc.attributedText = NSMutableAttributedString(string:  "PortfolioAvgBuyPriceAndDrawPointDialog_AvgBuyPriceDesc", attributes: [.paragraphStyle: paragraphStyle])
        avgBuyPriceCaluate.attributedText = NSMutableAttributedString(string:  "PortfolioAvgBuyPriceAndDrawPointDialog_AvgBuyPriceCaluate", attributes: [.paragraphStyle: paragraphStyle])
        drawPoint.attributedText = NSMutableAttributedString(string:  "PortfolioAvgBuyPriceAndDrawPointDialog_DrawPoint", attributes: [.paragraphStyle: paragraphStyle])
        drawPointDesc.attributedText = NSMutableAttributedString(string:  "PortfolioAvgBuyPriceAndDrawPointDialog_DrawPointDesc", attributes: [.paragraphStyle: paragraphStyle])
        drawPointCaluate.attributedText = NSMutableAttributedString(string:  "PortfolioAvgBuyPriceAndDrawPointDialog_DrawPointCaluate", attributes: [.paragraphStyle: paragraphStyle])
        bottomTipLabel.attributedText = NSMutableAttributedString(string:  "PortfolioAvgBuyPriceAndDrawPointDialog_bottomTip", attributes: [.paragraphStyle: paragraphStyle])
        
        
        let btn2 = UIButton {  _ in //[weak self]
//            let nav = UINavigationController(rootViewController: MGPresentViewController())
//            nav.modalPresentationStyle = .fullScreen
//            self.present(nav, animated: true)
        }
        btn2.setTitle("Prenset", for: .normal)
        containerStackView.addArrangedSubview(btn2)
        
        text1.text = "123"
        containerStackView.addArrangedSubview(text1)
        
        let btn3 = UIButton {  _ in
            
        }
        btn3.setTitle("Edit", for: .normal)
        containerStackView.addArrangedSubview(btn3)
        
        text2.text = "123"
        containerStackView.addArrangedSubview(text2)
        
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "PortfolioAvgBuyPriceAndDrawPointDialog_AvgBuyPrice\nPortfolioAvgBuyPriceAndDrawPointDialog_AvgBuyPrice\nPortfolioAvgBuyPriceAndDrawPointDialog_AvgBuyPrice\n"
        containerStackView.addArrangedSubview(label)
    }
    
    @objc open func viewDidPress() {
        if allowsTapToDismiss != false {
            dismiss(animated: true)
        }
    }
}


extension CXEditDiglogViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    @objc func keyBoardWillShow(notification: Notification) {
        allowsTapToDismiss = false
        guard let userInfo = notification.userInfo as? NSDictionary,
              let value = userInfo.object(forKey: UIResponder.keyboardFrameEndUserInfoKey) as? NSValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
//        let targetView: UIView? = modifyOrderView.submitButton
        var targetTextField: UITextField?
        if text1.isFirstResponder {
            targetTextField = text1
        } else if text2.isFirstResponder {
            targetTextField = text2
        }
        
        if let targetView = targetTextField {
            let size = UIScreen.main.bounds.size
            let frame = value.cgRectValue
            let targetViewFrame = targetView.frame
            let maxY = targetView.convert(targetView.bounds, to: view)
            let m1 = targetView.convert(targetView.bounds, to: containerStackView)
            let m2 = targetView.convert(targetView.bounds, to: view)
            
            let offsetY = maxY.origin.y - frame.minY + targetViewFrame.size.height
            if offsetY > 0 {
                UIView.animate(withDuration: duration, delay: 0.0,
                               animations: {
                    self.containerStackView.transform =
                    CGAffineTransformMakeTranslation(0, -offsetY)
                }, completion: nil)
            }
        }
    }
    @objc func keyBoardWillHide(notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.allowsTapToDismiss = true
        }
        guard let userInfo = notification.userInfo as? NSDictionary,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration, delay: 0.0) {
            self.containerStackView.transform = CGAffineTransformMakeTranslation(0, 0)
        }
    }
}
