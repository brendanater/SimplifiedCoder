#
#  Be sure to run `pod spec lint SimplifiedCoder.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.source_files  = "SimplifiedCoder", "SimplifiedCoder/**/*.{h,m,swift}"

  s.name         = "SimplifiedCoder"
  s.version      = "1.0.0"
  s.summary      = "Simplifies the creation of Encoder and Decoders."
  s.description  = "Simplifies creation of Swift Encoder and Decoder protocols by creating default handling of paths, containers, and boxing."
  s.homepage     = "Google.com"
  s.author       = "Brendan Henderson"
  s.license      = "MIT"
  s.source       = { :path => '.' }
  s.platform     = :ios, "11.0"
  
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4' }

end
