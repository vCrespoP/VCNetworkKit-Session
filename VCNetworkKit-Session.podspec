Pod::Spec.new do |s|
  s.name                      = "VCNetworkKit-Session"
  s.version                   = "1.0.0"
  s.summary                   = "VCNetworkKit-Session"
  s.homepage                  = "https://github.com/vCrespoP/VCNetworkKit-Session"
  s.license                   = { :type => "MIT", :file => "LICENSE" }
  s.author                    = { "Vicente Crespo" => "vicente.crespo.penades@gmail.com" }
  s.source                    = { :git => "https://github.com/vCrespoP/VCNetworkKit-Session.git", :tag => s.version.to_s }
  s.swift_version             = "5.1"
  s.ios.deployment_target     = "8.0"
  s.tvos.deployment_target    = "9.0"
  s.watchos.deployment_target = "2.0"
  s.osx.deployment_target     = "10.10"
  s.source_files              = "Sources/**/*"
  s.frameworks                = "Foundation"
  
  s.dependency 'vCrespoP/VCNetworkKit'
  
end