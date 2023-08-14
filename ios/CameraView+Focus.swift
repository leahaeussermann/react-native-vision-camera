//
//  CameraView+focus.swift
//  mrousavy
//
//  Created by Marc Rousavy on 19.02.21.
//  Copyright © 2021 mrousavy. All rights reserved.
//

import Foundation

extension CameraView {
  func focus(point: CGPoint, promise: Promise) {
    withPromise(promise) {
      guard let device = self.videoDeviceInput?.device else {
        throw CameraError.session(SessionError.cameraNotReady)
      }
      if !device.isFocusPointOfInterestSupported {
        throw CameraError.device(DeviceError.focusNotSupported)
      }

      var normalizedPoint: CGPoint
      if let previewView = previewView as? PreviewView {
        // previewView is of type PreviewView can use the built in captureDevicePointConverted
        normalizedPoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
      } else {
        normalizedPoint = captureDevicePointConverted(fromLayerPoint: point)
      }

      do {
        try device.lockForConfiguration()

        device.focusPointOfInterest = normalizedPoint
        device.focusMode = .autoFocus

        if device.isExposurePointOfInterestSupported {
          device.exposurePointOfInterest = normalizedPoint
          device.exposureMode = .autoFocus
        }

        // Enable subject area change monitoring
        device.isSubjectAreaChangeMonitoringEnabled = true

        // Remove any existing observer for subject area change notifications
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)

        // Register observer for subject area change notifications
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)

        device.unlockForConfiguration()
        return nil
      } catch {
        throw CameraError.device(DeviceError.configureError)
      }
    }
  }
  
  @objc func subjectAreaDidChange(notification: NSNotification) {
    guard let device = self.videoDeviceInput?.device else {
      invokeOnError(.session(.cameraNotReady))
      return
    }
    do {
      try device.lockForConfiguration()

      // Reset focus and exposure settings to continuous mode
      if device.isFocusPointOfInterestSupported {
        device.focusMode = .continuousAutoFocus
      }

      if device.isExposurePointOfInterestSupported {
        device.exposureMode = .continuousAutoExposure
      }

      device.isSubjectAreaChangeMonitoringEnabled = false

      device.unlockForConfiguration()
    } catch {
      invokeOnError(.device(.configureError))
    }
  }
}

