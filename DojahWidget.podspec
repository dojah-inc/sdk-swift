Pod::Spec.new do |s|
  s.name         = 'DojahWidget'
  s.version      = '1.0.4'
  s.summary      = 'DojahWidget SDK for Pod project.'
  s.homepage     = 'https://github.com/dojah-inc/sdk-swift.git'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Dojah' => 'dojah@dojah.io' }
  s.source       = { :git => 'https://github.com/shittu33/test-react-native-ios.git', :tag => s.version }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/**/*.{swift,h}'
   s.resource_bundles = {
    'DojahWidgetResources' => [
      'Sources/DojahWidget/Resources/**/*',
      'Sources/DojahWidget/Utilities/Components/**/*.{xib}'
    ]
   }


  # Include all JSON and Animation files from resources
#  s.resources = ['Sources/DojahWidget/Resources/**/*.{json,ttf,otf,xcassets}']
  # s.resources = [
  #   'Sources/DojahWidget/Resources/**/*.{json,ttf,otf,pdf,dataset,imageset}',
  #   'Sources/DojahWidget/Resources/JSON/countries.json',
  #   'Sources/DojahWidget/Resources/JSON/government_data_config.json',
  #   'Sources/DojahWidget/Resources/JSON/free_email_domains.json',
  #   'Sources/DojahWidget/Resources/JSON/disposable_email_domains.json',
  #   'Sources/DojahWidget/Resources/JSON/pricing_config.json',
  #   'Sources/DojahWidget/Resources/Animations/loading-circle.json',
  #   'Sources/DojahWidget/Resources/Animations/cancel.json',
  #   'Sources/DojahWidget/Resources/Animations/warning.json',
  #   'Sources/DojahWidget/Resources/Animations/error-2.json',
  #   'Sources/DojahWidget/Resources/Animations/failed.json',
  #   'Sources/DojahWidget/Resources/Animations/check-2.json',
  #   'Sources/DojahWidget/Resources/Animations/success.json',
  #   'Sources/DojahWidget/Resources/Animations/successfully-done.json',
  #   'Sources/DojahWidget/Resources/Animations/error.json',
  #   'Sources/DojahWidget/Resources/Animations/circle-loader.json',
  #   'Sources/DojahWidget/Resources/Animations/successfully-done-2.json',
  #   'Sources/DojahWidget/Resources/Animations/successfully-send.json',
  #   'Sources/DojahWidget/Resources/Animations/check_1.json',
  #   'Sources/DojahWidget/Resources/Fonts.xcassets/Fonts/Atakk-Bold.dataset/Atakk-Bold.ttf',
  #   'Sources/DojahWidget/Resources/Fonts.xcassets/Fonts/Atakk-Medium.dataset/Atakk-Medium.ttf',
  #   'Sources/DojahWidget/Resources/Fonts.xcassets/Fonts/Atakk-Regular.dataset/Atakk-Regular.ttf',
  #   'Sources/DojahWidget/Resources/Fonts.xcassets/Fonts/Atakk-Semibold.dataset'
  # ]

  # External dependencies equivalent to those in the Package.swift
  s.dependency 'HorizonCalendar', '~> 1.16.0'
  s.dependency 'lottie-ios', '~> 4.5.2'
  s.dependency 'RealmSwift', '~> 10.52.2'
  s.dependency 'IQKeyboardManagerSwift', '~> 7.1.1'
  s.dependency 'Kingfisher', '~> 7.12.0'
  s.dependency 'GooglePlaces', '~> 8.5.0'
  # s.dependency 'lottie-ios'

  # Alternatively, for pre-built frameworks:
  # s.vendored_frameworks = 'Frameworks/*.xcframework'
end

