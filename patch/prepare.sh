#!/bin/zsh
SOURCE_DIR=$(cd ..;pwd)
#prepare:
prepare(){

    cd ${SOURCE_DIR}
    #truncate -s 0 cmake/OpenCVFindLibsGrfmt.cmake
    rm -rf modules/gapi
    rm -rf modules/photo

    rm modules/core/src/cuda_*
    rm modules/core/src/direct*
    rm modules/core/src/gl_*
    rm modules/core/src/intel_gpu_*
    rm modules/core/src/ocl*
    rm modules/core/src/opengl.cpp
    rm modules/core/src/ovx.cpp
    rm modules/core/src/umatrix.hpp
    rm modules/core/src/va_intel.cpp
    rm modules/core/src/va_wrapper.impl.hpp

    rm modules/core/include/opencv2/core/cuda*.hpp
    rm modules/core/include/opencv2/core/directx.hpp
    rm modules/core/include/opencv2/core/ocl*.hpp
    rm modules/core/include/opencv2/core/opengl.hpp
    rm modules/core/include/opencv2/core/ovx.hpp
    rm modules/core/include/opencv2/core/private.cuda.hpp
    rm modules/core/include/opencv2/core/va_*.hpp
    rm -rf modules/core/include/opencv2/core/cuda
    rm -rf modules/core/include/opencv2/core/opencl
    rm -rf modules/core/include/opencv2/core/openvx

    #rm modules/photo/src/denoising.cuda.cpp
    #rm modules/photo/include/opencv2/photo/cuda.hpp

    #find modules -type d | xargs -i rm -rf {}/src/cuda
    #find modules -type d | xargs -i rm -rf {}/src/opencl
    #find modules -type d | xargs -i rm -rf {}/perf/cuda
    #find modules -type d | xargs -i rm -rf {}/perf/opencl
    rm -rf modules/**/src/cuda
    rm -rf modules/**/src/opencl
    rm -rf modules/**/perf/cuda
    rm -rf modules/**/perf/opencl
    export LC_ALL=C
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/opencl_kernels/d'
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/cuda.hpp/d'
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/opengl.hpp/d'
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/ocl_defs.hpp/d'
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/ocl.hpp/d'
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/ovx_defs.hpp/d'
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/ovx.hpp/d'
    find modules -type f -name "*.cpp" -o -name "*.h" -o -name "*.hpp" | xargs sed -i '' '/va_intel.hpp/d'

    patch -p1 -i patch/opencv-4.9.0-no-gpu.patch
    patch -p1 -i patch/opencv-4.9.0-no-rtti.patch
    patch -p1 -i patch/opencv-4.9.0-no-zlib.patch
    patch -p1 -i patch/opencv-4.9.0-link-openmp.patch
    patch -p1 -i patch/opencv-4.9.0-no-rtti-flann.patch
    patch -p1 -i patch/opencv-4.9.0-no-rtti-calib3d.patch
    patch -p1 -i patch/opencv-4.9.0-imgcodecs.patch
    patch -p1 -i patch/opencv-4.9.0-features2d.patch
    patch -p1 -i patch/opencv-4.9.0-dynamicCast.patch
    patch -p1 -i patch/opencv-4.9.0-minimal-install.patch

    #cp -r patch/flann modules/
    rm -rf modules/highgui
    rm -rf apps data doc samples platforms
    rm -rf modules/java
    rm -rf modules/js
    rm -rf modules/python
    rm -rf modules/ts
    sed -e 's/__VERSION__/4.9.0/g' patch/Info.plist > ./Info.plist

    cp patch/opencv4_cmake_options.txt ./options.txt
}
prepare
