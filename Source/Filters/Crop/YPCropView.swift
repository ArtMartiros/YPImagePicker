//
//  YPCropView.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 12/02/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//    

import UIKit
import Stevia

class YPCropView: UIView {
    let backView = UIView()
    let imageView = UIImageView()
    lazy var topCurtain: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: effect)
        return blurEffectView
    }()
    let cropArea = UIView()
    let bottomCurtain: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: effect)
        return blurEffectView
    }()
    let toolbar = UIToolbar()
    let customMaskView = UIImageView()
    
    convenience init(image: UIImage, ratio: Double) {
        self.init(frame: .zero)
        setupViewHierarchy()
        setupLayout(with: image, ratio: ratio)
        applyStyle()
        imageView.image = image
    }
    
    private func setupViewHierarchy() {
        sv(
            backView,
            imageView,
            topCurtain,
            cropArea,
            customMaskView,
            bottomCurtain,
            toolbar
        )
    }
    
    private func setupLayout(with image: UIImage, ratio: Double) {
        layout(
            0,
            |topCurtain|,
            |cropArea|,
            |bottomCurtain|,
            0
        )
        |toolbar|
        if #available(iOS 11.0, *) {
            toolbar.Bottom == safeAreaLayoutGuide.Bottom
        } else {
            toolbar.bottom(0)
        }
        
        let r: CGFloat = CGFloat(1.0 / ratio)
        cropArea.Height == cropArea.Width * r
        cropArea.centerVertically()
        backView.Width == cropArea.Width
        backView.Height == cropArea.Height
        backView.centerVertically()
        customMaskView.Width == 212
        customMaskView.Height == customMaskView.Width * 1.385
        customMaskView.centerHorizontally()
        customMaskView.centerVertically()
        // Fit image differently depnding on its ratio.
        let imageRatio: Double = Double(image.size.width / image.size.height)
        if ratio > imageRatio {
            let scaledDownRatio = UIScreen.main.bounds.width / image.size.width
            imageView.width(image.size.width * scaledDownRatio )
            imageView.centerInContainer()
        } else if ratio < imageRatio {
            imageView.Height == cropArea.Height
            imageView.centerInContainer()
        } else {
            imageView.followEdges(cropArea)
        }
        
        // Fit imageView to image's bounds
        imageView.Width == imageView.Height * CGFloat(imageRatio)
    }
    
    private func applyStyle() {
        backgroundColor = .ypSystemBackground
        clipsToBounds = true
        backView.style { i in
            i.backgroundColor = .black
            i.isUserInteractionEnabled = false
            i.isMultipleTouchEnabled = false
        }
        
        imageView.style { i in
            i.isUserInteractionEnabled = true
            i.isMultipleTouchEnabled = true
        }
        topCurtain.style(curtainStyle)
        cropArea.style { v in
            v.backgroundColor = .clear
            v.isUserInteractionEnabled = false
        }
        customMaskView.style { v in
            v.image = YPIcons().customMaskImage
            v.isUserInteractionEnabled = false
        }
        bottomCurtain.style(curtainStyle)
        toolbar.style { t in
            t.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
            t.setShadowImage(UIImage(), forToolbarPosition: .any)
        }
    }
    
    func curtainStyle(v: UIView) {
        //        v.backgroundColor = UIColor.ypSystemBackground.withAlphaComponent(0.7)
        v.isUserInteractionEnabled = false
    }
}
