#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_qrcode.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_qrcode'
  s.version          = '0.0.1'
  s.summary          = 'A fast and lightweight Flutter plugin for scanning barcodes and QR codes.'
  s.description      = <<-DESC
A fast and lightweight Flutter plugin for scanning barcodes and QR codes using the device's camera.
Supports multiple barcode formats with AVFoundation and Vision Framework on macOS.
                       DESC
  s.homepage         = 'https://github.com/Nghi-NV/flutter_qrcode'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nghi-NV' => '' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
