//
//  YPCropVC.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 12/02/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

public enum YPCropType {
    case none
    case rectangle(ratio: Double)
}

class YPCropVC: UIViewController {
    fileprivate var radians: Double = 0
    public var didFinishCropping: ((UIImage) -> Void)?
    
    override var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    
    private let originalImage: UIImage
    private let pinchGR = UIPinchGestureRecognizer()
    private let panGR = UIPanGestureRecognizer()
    private let rotateGR = UIRotationGestureRecognizer()
    private let pressGR = UILongPressGestureRecognizer()
    
    private let v: YPCropView
    override func loadView() { view = v }
    
    private var anchor = CGPoint()
    private var center = CGPoint()
    
    private func setupPreferences() {
        var preferences = EasyTipView.Preferences()
        
        preferences.drawing.font = .systemFont(ofSize: 14)
        preferences.drawing.foregroundColor = .black
        preferences.drawing.backgroundColor = .white
        preferences.drawing.textAlignment = .center
        preferences.drawing.cornerRadius = 8
        preferences.drawing.arrowHeight = 10
        preferences.drawing.arrowPosition = .bottom
        preferences.positioning.contentHInset = 20
        preferences.animating.dismissOnTap = false
        preferences.animating.springDamping = 10
        preferences.positioning.contentVInset = 4
        
        EasyTipView.globalPreferences = preferences
    }
    lazy var maskTipView: EasyTipView = {
        return EasyTipView(text: YPConfig.wordings.hint, preferences: EasyTipView.globalPreferences, delegate: nil)
    }()
    
    required init(image: UIImage, ratio: Double) {
        v = YPCropView(image: image, ratio: ratio)
        originalImage = image
        super.init(nibName: nil, bundle: nil)
        self.title = YPConfig.wordings.crop
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreferences()
        setupToolbar()
        setupGestureRecognizers()
    }
    
    func setupToolbar() {
        let cancelButton = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                           style: .plain,
                                           target: self,
                                           action: #selector(cancel))
        cancelButton.tintColor = .ypLabel
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let saveButton = UIBarButtonItem(title: YPConfig.wordings.save,
                                           style: .plain,
                                           target: self,
                                           action: #selector(done))
        saveButton.tintColor = .ypLabel
        
        v.toolbar.items = [cancelButton, flexibleSpace, saveButton]
    }
    
    func setupGestureRecognizers() {
        // Pinch Gesture
        pinchGR.addTarget(self, action: #selector(pinch(_:)))
        pinchGR.delegate = self
        v.imageView.addGestureRecognizer(pinchGR)
        
        // Pan Gesture
        panGR.addTarget(self, action: #selector(pan(_:)))
        panGR.delegate = self
        v.imageView.addGestureRecognizer(panGR)
        
        // Rotate Gesture
        rotateGR.addTarget(self, action: #selector(handleRotation(_:)))
        rotateGR.delegate = self
        v.imageView.addGestureRecognizer(rotateGR)
        
        pressGR.addTarget(self, action: #selector(self.handlePress(_:)))
        pressGR.numberOfTouchesRequired = 2
        pressGR.minimumPressDuration = 0.01
        pressGR.delegate = self
        v.imageView.addGestureRecognizer(pressGR)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UserDefaultsStorage.shared.keyIsAlreadyTapAddCustomImage {
            let maskView = v.customMaskView
            maskTipView.show(forView: maskView)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        maskTipView.dismiss()
    }
    @objc
    func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    func done() {
        guard let image = v.imageView.image else {
            return
        }
        
        guard let rotatedImage = image.rotate(radians: Float(radians)) else { return }
//        guard let cgImage = rotatedImage?.toCIImage()?.toCGImage() else { return }
        UserDefaultsStorage.shared.keyIsAlreadyTapAddCustomImage = true
        let xCrop = v.cropArea.frame.minX - v.imageView.frame.minX
        let yCrop = v.cropArea.frame.minY - v.imageView.frame.minY
        let widthCrop = v.cropArea.frame.width
        let heightCrop = v.cropArea.frame.height
        //нужен просто для того чтобы перевести в координаты image
        let imageScaleRatio = rotatedImage.size.width / v.imageView.frame.width
        let scaleRatio = v.imageView.frame.width / v.cropArea.frame.width
        
        guard let croppedImage = rotatedImage.crop(x: -xCrop * imageScaleRatio,
                                                   y: -yCrop * imageScaleRatio,
                                                   cropWidth: widthCrop * imageScaleRatio,
                                                   cropHeight: heightCrop * imageScaleRatio,
                                                   scale: 1) else { return }
//        guard let cgImagenewImage = croppedImage.toCIImage()?.toCGImage() else { return }
//        let scaledCropRect = CGRect(x: xCrop * imageScaleRatio,
//                                            y: yCrop * imageScaleRatio,
//                                            width: widthCrop * imageScaleRatio,
//                                            height: heightCrop * imageScaleRatio)
//        if let imageRef = cgImage.cropping(to: scaledCropRect) {
//            let croppedImage1 = UIImage(cgImage: cgImagenewImage)
            didFinishCropping?(croppedImage)
//        }
        
    }
}

extension YPCropVC: UIGestureRecognizerDelegate {
    
    // MARK: - Pinch Gesture
    
    @objc
    func pinch(_ sender: UIPinchGestureRecognizer) {
        // TODO: Zoom where the fingers are (more user friendly)
        switch sender.state {
        case .began, .changed:
            // Formula:
            // P' = s * P + (1 - s) * A
            // where P' - new point, P - old point, A - anchor point, s - scale
            
            var transform = v.imageView.transform
            // Apply zoom level.
            transform = transform.scaledBy(x: sender.scale,
                                            y: sender.scale)
            
            let tx = (1 - sender.scale) * self.anchor.x
            let ty = (1 - sender.scale) * self.anchor.y
            transform = transform.translatedBy(x: tx, y: ty)
            
            v.imageView.transform = transform
        case .ended:
            pinchGestureEnded()
        case .cancelled, .failed, .possible:
            ()
        @unknown default:
            fatalError()
        }
        // Reset the pinch scale.
        sender.scale = 1.0
    }
    
    private func pinchGestureEnded() {
        var transform = v.imageView.transform
        let kMinZoomLevel: CGFloat = 1.0
        let kMaxZoomLevel: CGFloat = 3.0
        var wentOutOfAllowedBounds = false
        
        // Prevent zooming out too much
        if transform.a < kMinZoomLevel {
            transform = .identity
            wentOutOfAllowedBounds = true
        }
        
        // Prevent zooming in too much
        if transform.a > kMaxZoomLevel {
            transform.a = kMaxZoomLevel
            transform.d = kMaxZoomLevel
            wentOutOfAllowedBounds = true
        }
        
        // Animate coming back to the allowed bounds with a haptic feedback.
//        if wentOutOfAllowedBounds {
//            generateHapticFeedback()
//            UIView.animate(withDuration: 0.3, animations: {
//                self.v.imageView.transform = transform
//            })
//        }
    }
    
    func generateHapticFeedback() {
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    // MARK: - Pan Gesture
    
    @objc
    func pan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let imageView = v.imageView
        
        // Apply the pan translation to the image.
        imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
        
        // Reset the pan translation.
        sender.setTranslation(CGPoint.zero, in: view)
        
        if sender.state == .ended {
            keepImageIntoCropArea()
        }
    }
    
    
    func rotate_point(point: CGPoint, angle: CGFloat) -> CGPoint {
        // rotate a point given angle in radians
        let x = cos(angle) * point.x - sin(angle) * point.y
        let y = sin(angle) * point.x + cos(angle) * point.y
        return CGPoint(x: x, y: y)
    }

    
    @objc
    func handleRotation(_ recognizer: UIRotationGestureRecognizer) {
        if let recognizerView = recognizer.view {
            // Formula:
            // P' = R * P + (A - R * A)
            // where P' - new point, P - old point, R - rotation matrix, A - anchor point
            
            recognizerView.transform = recognizerView.transform.rotated(by: recognizer.rotation)
            
            let rot_anchor = rotate_point(point: anchor, angle: recognizer.rotation)
            let tx = anchor.x - rot_anchor.x
            let ty = anchor.y - rot_anchor.y
            recognizerView.transform = recognizerView.transform.translatedBy(x: tx, y: ty)

            radians = atan2(Double(recognizerView.transform.b), Double(recognizerView.transform.a))
            
            recognizer.rotation = 0
        }
    }
    
    private func keepImageIntoCropArea() {
        let imageRect = v.imageView.frame
        let cropRect = v.cropArea.frame
        var correctedFrame = imageRect
        
        // Cap Top.
        if imageRect.minY > cropRect.minY {
            correctedFrame.origin.y = cropRect.minY
        }
        
        // Cap Bottom.
        if imageRect.maxY < cropRect.maxY {
            correctedFrame.origin.y = cropRect.maxY - imageRect.height
        }
        
        // Cap Left.
        if imageRect.minX > cropRect.minX {
            correctedFrame.origin.x = cropRect.minX
        }
        
        // Cap Right.
        if imageRect.maxX < cropRect.maxX {
            correctedFrame.origin.x = cropRect.maxX - imageRect.width
        }
        
        // Animate back to allowed bounds
//        if imageRect != correctedFrame {
//            UIView.animate(withDuration: 0.3, animations: {
//                self.v.imageView.frame = correctedFrame
//            })
//        }
    }
    
    @objc
    func handlePress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let loc = sender.location(in: v.imageView)
            
            let size = v.cropArea.frame.size.width
            let aspect = v.imageView.image!.size.width / v.imageView.image!.size.height
            
            if aspect > 1 {
                center.x = size / 2 * aspect
                center.y = size / 2
            }
            else {
                center.x = size / 2
                center.y = size / 2 / aspect
            }
            
            anchor = CGPoint(x: loc.x - center.x, y: loc.y - center.y)
        }
    }
    
    /// Allow both Pinching and Panning at the same time.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.black.cgColor)
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func crop(x: CGFloat, y: CGFloat, cropWidth: CGFloat, cropHeight: CGFloat, scale: CGFloat) -> UIImage? {
        let cropSize = CGSize(width: cropWidth, height: cropHeight)
        let frame = CGRect(origin: CGPoint.zero, size: size )
        //определяет какой размер будет
        UIGraphicsBeginImageContextWithOptions(cropSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.black.cgColor)
        // Move origin to middle
        
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: x, y: y)
        
        self.draw(in: frame)
        //        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

