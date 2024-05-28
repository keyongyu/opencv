#!/bin/bash
SOURCE_DIR=$(cd ..;pwd)
build_android(){
  export ANDROID_NDK=~/Library/Android/sdk/ndk/26.3.11579264
  export ANDROID_SDK_ROOT=~/Library/Android/sdk

  sed -i"" -e '/^  -g$/d' ${ANDROID_NDK}/build/cmake/android.toolchain.cmake
  #sed -i -e '/^  -g$/d' ${ANDROID_NDK}/build/cmake/android-legacy.toolchain.cmake

  export PATH=$PATH:${ANDROID_SDK_ROOT}/cmake/3.22.1/bin

  COMMON_CMAKE_OPTIONS="-GNinja -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake"
  COMMON_CMAKE_OPTIONS="${COMMON_CMAKE_OPTIONS} -DANDROID_PLATFORM=android-22"
  COMMON_CMAKE_OPTIONS="${COMMON_CMAKE_OPTIONS} -DBUILD_opencv_world=OFF -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON"
  COMMON_CMAKE_OPTIONS="${COMMON_CMAKE_OPTIONS} -DANDROID_CPP_FEATURES=no-exceptions "
  COMMON_CMAKE_OPTIONS="${COMMON_CMAKE_OPTIONS} -DANDROID_CPP_FEATURES=no-rtti"
  COMMON_CMAKE_OPTIONS="${COMMON_CMAKE_OPTIONS} -DCMAKE_INSTALL_PREFIX=install "
  COMMON_CMAKE_OPTIONS="${COMMON_CMAKE_OPTIONS} -DCMAKE_BUILD_TYPE=Release "

  #must use bash, the cat output will not work in zsh
      cd ${SOURCE_DIR}

      rm -fr build-armeabi-v7a
      mkdir build-armeabi-v7a && cd build-armeabi-v7a
      cmake ${COMMON_CMAKE_OPTIONS}  -DANDROID_ABI="armeabi-v7a" -DANDROID_ARM_NEON=ON \
            `cat ../options.txt` -DBUILD_opencv_world=OFF -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
      cmake --build . -j
      cmake --build . --target install


      cd ${SOURCE_DIR}
      rm -fr build-arm64-v8a
      mkdir build-arm64-v8a && cd build-arm64-v8a
      cmake ${COMMON_CMAKE_OPTIONS}  -DANDROID_ABI="arm64-v8a" \
          `cat ../options.txt` -DBUILD_opencv_world=OFF -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
      cmake --build . -j
      cmake --build . --target install


      cd ${SOURCE_DIR}
      rm -fr build-x86
      mkdir build-x86 && cd build-x86
      cmake ${COMMON_CMAKE_OPTIONS}  -DANDROID_ABI="x86" \
              `cat ../options.txt` -DBUILD_opencv_world=OFF -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
      cmake --build . -j
      cmake --build . --target install


      cd ${SOURCE_DIR}
      rm -fr build-x86_64
      mkdir build-x86_64 && cd build-x86_64
      cmake ${COMMON_CMAKE_OPTIONS} -DANDROID_ABI="x86_64" \
              `cat ../options.txt` -DBUILD_opencv_world=OFF -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
      cmake --build . -j
      cmake --build . --target install



      cd ${SOURCE_DIR}
      PACKAGE_NAME=cv_4_9_0_no_rtti_exception_android
      rm -fr ${PACKAGE_NAME}
      mkdir ${PACKAGE_NAME}
          cp -rf build-x86/install/* ${PACKAGE_NAME}/
          cp -rf build-x86_64/install/* ${PACKAGE_NAME}/
          cp -rf build-armeabi-v7a/install/* ${PACKAGE_NAME}/
          cp -rf build-arm64-v8a/install/* ${PACKAGE_NAME}/
          zip -9 -r ${PACKAGE_NAME}.zip ${PACKAGE_NAME}

        rm -rf build-x86
        rm -rf build-x86_64
        rm -rf build-armeabi-7va
        rm -rf build-arm64-v8a
}

CV_VERSION=4.9.0
IOS_DEPLOYMENT_TARGET=11.0
#MAC_DEPLOYMENT_TARGET=11.0
MAC_CATALYST_DEPLOYMENT_TARGET=13.1
ENABLE_BITCODE="OFF"
ENABLE_ARC="OFF"
ENABLE_VISIBILITY="OFF"

IOS_PACKAGE_NAME="cv_${CV_VERSION}-ios"
IOS_SIMULATOR_PACKAGE_NAME="cv_${CV_VERSION}-ios-simulator"
build_ios(){
      cd ${SOURCE_DIR}

      #ios
      COMMON_CMAKE_OPTIONS=(-DCMAKE_TOOLCHAIN_FILE=patch/toolchain/ios.toolchain.cmake \
                             -DPLATFORM=OS  \
                             -DDEPLOYMENT_TARGET=${IOS_DEPLOYMENT_TARGET}  \
                             -DENABLE_BITCODE=${ENABLE_BITCODE} \
                             -DENABLE_ARC=${ENABLE_ARC} \
                             -DENABLE_VISIBILITY=${ENABLE_VISIBILITY} \
                             -DCMAKE_C_FLAGS="-fno-rtti -fno-exceptions" \
                             -DCMAKE_CXX_FLAGS="-fno-rtti -fno-exceptions" \
                             -DCMAKE_INSTALL_PREFIX=install \
                             -DCMAKE_BUILD_TYPE=Release  )
      rm -fr build-arm64
      mkdir build-arm64 && cd build-arm64
      cmake "${COMMON_CMAKE_OPTIONS[@]}" -DARCHS="arm64" \
            `cat ../options.txt` -DBUILD_opencv_world=ON -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
      # workaround ar @list issue on macos
      #cmake --build . -j 4 || { cd modules/world; $DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar qc ../../lib/libopencv_world.a `cat world_objects.rsp` CMakeFiles/opencv_world.dir/src/world_init.cpp.o; cd ../..; }
      cmake --build . -j
      cmake --build . --target install
      echo "merge lib"
      libtool -static -o ${SOURCE_DIR}/build-arm64/install/lib/libopencv_merged.a \
            ${SOURCE_DIR}/build-arm64/install/lib/libopencv_world.a   \
            ${SOURCE_DIR}/build-arm64/install/lib/opencv4/3rdparty/*.a


      ls -lh ${SOURCE_DIR}/build-arm64/install/lib/libopencv_merged.a


      cd ${SOURCE_DIR}
      rm -rf opencv2.framework
      mkdir -p opencv2.framework/Versions/A/Headers
      mkdir -p opencv2.framework/Versions/A/Resources
      ln -s A opencv2.framework/Versions/Current
      ln -s Versions/Current/Headers opencv2.framework/Headers
      ln -s Versions/Current/Resources opencv2.framework/Resources
      ln -s Versions/Current/opencv2 opencv2.framework/opencv2
      lipo -create ${SOURCE_DIR}/build-arm64/install/lib/libopencv_merged.a -o opencv2.framework/Versions/A/opencv2

      PACKAGE_NAME=$IOS_PACKAGE_NAME
      cp -r ${SOURCE_DIR}/build-arm64/install/include/opencv4/opencv2/* opencv2.framework/Versions/A/Headers/
      cp -r ${SOURCE_DIR}/build-arm64/install/include/opencv2/* opencv2.framework/Versions/A/Headers/
      cp ${SOURCE_DIR}/Info.plist opencv2.framework/Versions/A/Resources/
      rm -f ${PACKAGE_NAME}.zip
      zip -9 -y -r ${PACKAGE_NAME}.zip opencv2.framework
}
build_ios_simulator(){
      #simulator
      cd ${SOURCE_DIR}
      COMMON_CMAKE_OPTIONS=(-DCMAKE_TOOLCHAIN_FILE=patch/toolchain/ios.toolchain.cmake \
                             -DPLATFORM=SIMULATOR  \
                             -DDEPLOYMENT_TARGET=${IOS_DEPLOYMENT_TARGET}  \
                             -DENABLE_BITCODE=${ENABLE_BITCODE} \
                             -DENABLE_ARC=${ENABLE_ARC} \
                             -DENABLE_VISIBILITY=${ENABLE_VISIBILITY} \
                             -DCMAKE_C_FLAGS="-fno-rtti -fno-exceptions" \
                             -DCMAKE_CXX_FLAGS="-fno-rtti -fno-exceptions" \
                             -DCMAKE_INSTALL_PREFIX=install \
                             -DCMAKE_BUILD_TYPE=Release  )

      rm -fr build-x86_64
      mkdir build-x86_64 && cd build-x86_64
      cmake "${COMMON_CMAKE_OPTIONS[@]}" -DARCHS="x86_64" \
              `cat ../options.txt` -DBUILD_opencv_world=ON -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..

      cmake --build . -j
      cmake --build . --target install
      echo "merge lib"
      libtool -static -o ${SOURCE_DIR}/build-x86_64/install/lib/libopencv_merged.a \
            ${SOURCE_DIR}/build-x86_64/install/lib/libopencv_world.a   \
            ${SOURCE_DIR}/build-x86_64/install/lib/opencv4/3rdparty/*.a

      ls -lh ${SOURCE_DIR}/build-x86_64/install/lib/libopencv_merged.a

      cd ${SOURCE_DIR}
      rm -fr build-arm64
      mkdir build-arm64 && cd build-arm64
      pwd
      cmake "${COMMON_CMAKE_OPTIONS[@]}" -DARCHS="arm64" \
            `cat ../options.txt` -DBUILD_opencv_world=ON -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
      cmake --build . -j
      cmake --build . --target install
      echo "merge lib"
      libtool -static -o ${SOURCE_DIR}/build-arm64/install/lib/libopencv_merged.a \
            ${SOURCE_DIR}/build-arm64/install/lib/libopencv_world.a   \
            ${SOURCE_DIR}/build-arm64/install/lib/opencv4/3rdparty/*.a

      ls -lh ${SOURCE_DIR}/build-arm64/install/lib/libopencv_merged.a
      PACKAGE_NAME=$IOS_SIMULATOR_PACKAGE_NAME

      cd ${SOURCE_DIR}
      rm -rf opencv2.framework
      mkdir -p opencv2.framework/Versions/A/Headers
      mkdir -p opencv2.framework/Versions/A/Resources
      ln -s A opencv2.framework/Versions/Current
      ln -s Versions/Current/Headers opencv2.framework/Headers
      ln -s Versions/Current/Resources opencv2.framework/Resources
      ln -s Versions/Current/opencv2 opencv2.framework/opencv2
      lipo -create \
          ${SOURCE_DIR}/build-x86_64/install/lib/libopencv_merged.a \
          ${SOURCE_DIR}/build-arm64/install/lib/libopencv_merged.a \
          -o opencv2.framework/Versions/A/opencv2
      cp -r ${SOURCE_DIR}/build-x86_64/install/include/opencv4/opencv2/* opencv2.framework/Versions/A/Headers/
      cp -r ${SOURCE_DIR}/build-x86_64/install/include/opencv2/* opencv2.framework/Versions/A/Headers/
      cp ${SOURCE_DIR}/Info.plist opencv2.framework/Versions/A/Resources/
      rm -f ${PACKAGE_NAME}.zip
      zip -9 -y -r ${PACKAGE_NAME}.zip opencv2.framework
}
#build_maccatalyst(){
#      #maccatalyst
#      cd ${SOURCE_DIR}
#      COMMON_CMAKE_OPTIONS=(-DCMAKE_TOOLCHAIN_FILE=patch/toolchain/ios.toolchain.cmake \
#                             -DPLATFORM=MAC_CATALYST\
#                             -DDEPLOYMENT_TARGET=${MAC_CATALYST_DEPLOYMENT_TARGET}  \
#                             -DENABLE_BITCODE=${ENABLE_BITCODE} \
#                             -DENABLE_ARC=${ENABLE_ARC} \
#                             -DENABLE_VISIBILITY=${ENABLE_VISIBILITY} \
#                             -DCMAKE_C_FLAGS="-fno-rtti -fno-exceptions" \
#                             -DCMAKE_CXX_FLAGS="-fno-rtti -fno-exceptions" \
#                             -DCMAKE_INSTALL_PREFIX=install \
#                             -DCMAKE_BUILD_TYPE=Release  )
#
#      rm -fr build-x86_64
#      mkdir build-x86_64 && cd build-x86_64
#      cmake "${COMMON_CMAKE_OPTIONS[@]}" -DARCHS="x86_64" \
#              `cat ../options.txt` -DBUILD_opencv_world=ON -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
#
#      cmake --build . -j
#      cmake --build . --target install
#
#      cd ${SOURCE_DIR}
#      rm -fr build-arm64
#      mkdir build-arm64 && cd build-arm64
#      pwd
#      cmake "${COMMON_CMAKE_OPTIONS[@]}" -DARCHS="arm64" \
#            `cat ../options.txt` -DBUILD_opencv_world=ON -DOPENCV_DISABLE_FILESYSTEM_SUPPORT=ON ..
#      cmake --build . -j
#      cmake --build . --target install
#
#
#      MAC_CATALYST_PACKAGE_NAME="cv_${CV_VERSION}-mac-catalyst"
#      PACKAGE_NAME=$MAC_CATALYST_PACKAGE_NAME
#      cd ${SOURCE_DIR}
#      rm -rf opencv2.framework
#      mkdir -p opencv2.framework/Versions/A/Headers
#      mkdir -p opencv2.framework/Versions/A/Resources
#      ln -s A opencv2.framework/Versions/Current
#      ln -s Versions/Current/Headers opencv2.framework/Headers
#      ln -s Versions/Current/Resources opencv2.framework/Resources
#      ln -s Versions/Current/opencv2 opencv2.framework/opencv2
#      lipo -create \
#          ${SOURCE_DIR}/build-x86_64/install/lib/libopencv_world.a \
#          ${SOURCE_DIR}/build-arm64/install/lib/libopencv_world.a \
#          -o opencv2.framework/Versions/A/opencv2
#      cp -r ${SOURCE_DIR}/build-x86_64/install/include/opencv4/opencv2/* opencv2.framework/Versions/A/Headers/
#      cp -r ${SOURCE_DIR}/build-x86_64/install/include/opencv2/* opencv2.framework/Versions/A/Headers/
#      cp ${SOURCE_DIR}/Info.plist opencv2.framework/Versions/A/Resources/
#      rm -f ${PACKAGE_NAME}.zip
#      zip -9 -y -r ${PACKAGE_NAME}.zip opencv2.framework
#}
build_xcframework(){
    #echo "build_xcframework 111"
    cd ${SOURCE_DIR}
    PACKAGE_NAME="cv_${CV_VERSION}-apple"
    rm -fr ${IOS_PACKAGE_NAME}
    mkdir -p ${IOS_PACKAGE_NAME}
    rm -fr ${IOS_SIMULATOR_PACKAGE_NAME}
    mkdir -p ${IOS_SIMULATOR_PACKAGE_NAME}
    #echo "build_xcframework 111"
    unzip -q ${IOS_PACKAGE_NAME}.zip -d ${IOS_PACKAGE_NAME}
    #echo "build_xcframework 222"
    unzip -q ${IOS_SIMULATOR_PACKAGE_NAME}.zip -d ${IOS_SIMULATOR_PACKAGE_NAME}
    #echo "build_xcframework 333"
    xcodebuild -create-xcframework \
        -framework ${IOS_PACKAGE_NAME}/opencv2.framework \
        -framework ${IOS_SIMULATOR_PACKAGE_NAME}/opencv2.framework \
        -output opencv2.xcframework
    rm -f ${PACKAGE_NAME}.zip
    zip -9 -y -r ${PACKAGE_NAME}.zip opencv2.xcframework
}
build_android
#build_ios
#build_ios_simulator
#build_xcframework