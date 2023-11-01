Building OpenCV from Source, using CMake and Command Line
=========================================================

cd ~/<my_working_directory>
python opencv/platforms/ios/build_framework.py ios
export OPENCV_SKIP_XCODEBUILD_FORCE_TRYCOMPILE_DEBUG=1
python3 build_framework.py ios  \
--iphoneos_deployment_target "14.0" \ 
--build_only_specified_archs   \
--iphoneos_archs "arm64"   \
--iphonesimulator_archs "x86_64" 

If everything's fine, a few minutes later you will get ~/<my_working_directory>/ios/opencv2.framework. You can add this framework to your Xcode projects.
