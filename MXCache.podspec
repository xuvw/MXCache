#
# Be sure to run `pod lib lint MXCache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MXCache'
  s.version          = '0.1.0'
  s.summary          = 'OS 内置缓存系统支持磁盘、内存缓存，LRU淘汰算法，基于活跃CPU核心数的多线程支持'

    s.description      = <<-DESC
                         iOS 内置缓存系统支持磁盘、内存缓存，LRU淘汰算法，基于活跃CPU核心数的多线程支持
                       DESC

  s.homepage         = 'https://github.com/xuvw/MXCache.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'heke' => 'smileshitou@hotmail.com' }
  s.source           = { :git => 'https://github.com/xuvw/MXCache.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MXCache/Classes/**/*'
  
  s.dependency 'FMDB', '2.7.5'
  s.dependency 'MXLRU', '0.1.0'
  s.dependency 'MXGCDQueuePool', '0.1.0'

end
