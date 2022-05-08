platform :ios, '11.0'
source 'https://github.com/CocoaPods/Specs.git'
project 'Na-vi.xcodeproj'
use_frameworks!

def mary_pods 
end

target 'Na-vi' do
	mary_pods
end 

target 'Na-vi Keyboard' do
	mary_pods
end 

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end
