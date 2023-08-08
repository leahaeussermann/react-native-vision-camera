package com.mrousavy.camera

import kotlinx.coroutines.guava.await

suspend fun CameraView.enableTorch(status: Boolean){
      val cameraControl = camera?.cameraControl ?: throw CameraNotReadyError()

      cameraControl.enableTorch(status)
  }
