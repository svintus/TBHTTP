Pod::Spec.new do |spec|
  spec.name                = 'TBHTTP'
  spec.version             = '0.0.8'
  spec.license             = { :type => 'MIT' }
  spec.homepage            = 'https://github.com/mosobase/TBHTTP'
  spec.authors             = { 'Marcus Osobase' => 'marcus@tunnelbear.com' }
  spec.summary             = 'Light NSURLSession wrapper'
  spec.source              = { :git => 'https://github.com/mosobase/TBHTTP.git', :tag => spec.version.to_s, :branch => 'framework' }
  spec.source_files        = 'TBHTTP/*.{h,m}'
	spec.public_header_files = 'TBHTTP/*.h'
  spec.requires_arc        = true
	
	spec.osx.frameworks      = 'CoreServices'
  spec.ios.frameworks      = 'MobileCoreServices'
  spec.osx.deployment_target = '10.10'
  spec.ios.deployment_target = '7.0'

end
