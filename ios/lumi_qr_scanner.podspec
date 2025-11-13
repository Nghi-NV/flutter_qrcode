Pod::Spec.new do |s|
  s.name             = 'lumi_qr_scanner'
  s.version          = '0.0.2'
  s.summary          = 'A fast and lightweight Flutter plugin for scanning barcodes and QR codes.'
  s.description      = <<-DESC
A fast and lightweight Flutter plugin for scanning barcodes and QR codes using the device's camera.
Supports multiple barcode formats with AVFoundation and Vision Framework on iOS.
                       DESC
  s.homepage         = 'https://github.com/Nghi-NV/lumi_qr_scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nghi-NV' => '' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
