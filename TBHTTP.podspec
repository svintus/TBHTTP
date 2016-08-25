Pod::Spec.new do |spec|
  spec.name                = 'TBHTTP'
  spec.version             = '0.0.2'
  spec.license             = { :type => 'MIT' }
  spec.homepage            = 'https://github.com/mosobase/TBHTTP'
  spec.authors             = { 'Marcus Osobase' => 'marcus@tunnelbear.com' }
  spec.summary             = 'Light NSURLSession wrapper'
  spec.source              = { :git => 'https://github.com/mosobase/TBHTTP.git', :tag => spec.version.to_s }
  spec.source_files        = 'TBHTTP/*.{h,m}'
	spec.frameworks					 = 'CoreServices', 'Cocoa'
#  spec.public_header_files = 'TBHTTP/TBHTTP.h'
  spec.requires_arc        = true
	
	spec.osx.deployment_target = '10.10'
end
