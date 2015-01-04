//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#include "Image.cuh"
#include "Skeleton.hpp"

#include <SFML/System/Clock.hpp>

#include <thrust/functional.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/transform_reduce.h>

#ifdef DEBUG
#include <iostream>
#define DEBUG_PRINT(x) (x)
#else
#define DEBUG_PRINT(x)
#endif


// Run one full iteration of the thinning algorithm.
// Both buffer1 and buffer2 at the end contain the same data.
bool erode(BWImage<DevicePixels>& buffer1, BWImage<DevicePixels>& buffer2);

// Run one sub-cycle of the thinning algorithm.
// Buffer1 is the source and buffer2 will be thinned if appropriate.
bool erodeIter(BWImage<DevicePixels> const& buffer1, BWImage<DevicePixels>& buffer2, bool firstSubiter);

//************************************************************************************************//
//                                      IMPLEMENTATION                                            //
//************************************************************************************************//

void skeleton(std::string const& input, std::string const& output, sf::Time& elapsed, int& iterations)
{
    // Load the image from disk
    sf::Clock clk;
    BWImage<HostPixels> hostImg = loadImage(input);

#ifndef ENABLE_SAVE_IMAGE
    // Ignore I/O time when not saving the image
    clk.restart();
#endif

    // Create two buffers for the thinning algorithm
    // We do it here to avoid reallocating device memory in a loop
    // The first one contains
    BWImage<DevicePixels> buffer1(hostImg.width, hostImg.height);
    buffer1.copyFrom(hostImg); // Copy from host to device

    BWImage<DevicePixels> buffer2(hostImg.width, hostImg.height);
    buffer2.copyFrom(buffer1); // Copy from device to device

    iterations = 0;
    for (bool run = true; run; ++iterations) {
        // buffer1 and buffer2 will be modified with the new image
        DEBUG_PRINT(std::cout << "thinning....\n");
        run = erode(buffer1, buffer2);
    }

    // Fetch the skeleton from the device
    hostImg.copyFrom(buffer1);

    // Save the skeleton back image
#ifdef ENABLE_SAVE_IMAGE
    saveImage(output, hostImg);
#endif

    // Included I/O time when ENABLE_SAVE_IMAGE is defined
    elapsed = clk.restart();
}

bool erode(BWImage<DevicePixels>& buffer1, BWImage<DevicePixels>& buffer2)
{
    DEBUG_PRINT(std::cout << "\t1st subcycle....\n");
    bool const eroded1 = erodeIter(buffer1, buffer2, true);

    DEBUG_PRINT(std::cout << "\tcopy data......\n");
    buffer1.copyFrom(buffer2); // device to device

    DEBUG_PRINT(std::cout << "\t2nd subcycle....\n");
    bool const eroded2 = erodeIter(buffer1, buffer2, false);

    DEBUG_PRINT(std::cout << "\tcopy data......\n");
    buffer1.copyFrom(buffer2); // device to device

    DEBUG_PRINT(std::cout << "\tdone\n");

    return eroded1 or eroded2;
}

struct ErodePixelFunctor : thrust::unary_function<int, bool>
{
    bool const firstSubiter;    // Flag for sub-iteration identity
    Pixel const* pbuffer1;      // Raw pointer to the device memory of size width * height
    Pixel* pbuffer2;            // Idem
    int const width;    // Image width
    int const height;   // Image height

    ErodePixelFunctor(bool firstSubiter,
                      Pixel const* pbuffer1, Pixel* pbuffer2,
                      int width, int height)
        : firstSubiter(firstSubiter)
        , pbuffer1(pbuffer1)
        , pbuffer2(pbuffer2)
        , width(width)
        , height(height)
    {
    }

    // Erode (or not) the pixel at the given index
    __host__ __device__
    bool operator()(int index)
    {
        // Goal: use as few if statement as possible!

        int const i = index % width;
        int const j = index / width; // integer division

        Pixel const black = pbuffer1[index];

#ifdef ENABLE_PARALLEL_SHORT_CIRCUIT_WHITE
        if (!black) return false;
#endif

        Pixel const x1    = pbuffer1[indexOf(i + 1, j)];
        Pixel const x2    = pbuffer1[indexOf(i + 1, j - 1)];
        Pixel const x3    = pbuffer1[indexOf(i, j - 1)];
        Pixel const x4    = pbuffer1[indexOf(i - 1, j - 1)];
        Pixel const x5    = pbuffer1[indexOf(i - 1, j)];
        Pixel const x6    = pbuffer1[indexOf(i - 1, j + 1)];
        Pixel const x7    = pbuffer1[indexOf(i, j + 1)];
        Pixel const x8    = pbuffer1[indexOf(i + 1, j + 1)];

        // Xh: Hiditch's crossing number
        int const Xh =
            /* b(1) */ (!x1 & (x2 | x3)) +
            /* b(2) */ (!x3 & (x4 | x5)) +
            /* b(3) */ (!x5 & (x6 | x7)) +
            /* b(4) */ (!x7 & (x8 | x1));

        // G1:
        bool const G1 = (Xh == 1);

        // N1 and N2
        int const N1 = (x2 | x1) + (x4 | x3) + (x6 | x5) + (x8 | x7);
        int const N2 = (x3 | x2) + (x5 | x4) + (x7 | x6) + (x1 | x8);
        int const N = N2 ^ ((N1 ^ N2) & -(N1 < N2)); // min(N1, N2)

        // G2:
        bool const G2 = (2 <= N) & (N <= 3);

        // G3 / G3':
        bool const G3 =
            (firstSubiter and ((x2 | x3 | !x8) & x1) == 0) |
            (!firstSubiter and ((x6 | x7 | !x4) & x5) == 0);

        // All together:
        bool const deleted = black & G1 & G2 & G3;

        // Because WHITE == false we can do as follow:
        pbuffer2[index] = pbuffer1[index] & !deleted;

        return deleted; // 1/true or 0/false
    }

    __host__ __device__
    int indexOf(int i, int j) const { return j * width + i; }
};

bool erodeIter(BWImage<DevicePixels> const& buffer1, BWImage<DevicePixels>& buffer2, bool firstSubiter)
{
    int const w     = buffer1.width;
    int const h     = buffer1.height;
    int const begin = buffer1.indexOf(1, 1);
    int const end   = buffer1.indexOf(w - 1, h - 1);

    // Transformation: take the index as input, modify the second buffer
    //                 and return 1 when the pixel is deleted, 0 otherwise
    // Reduction: addition the number of deleted pixels
    bool eroded = thrust::transform_reduce(
        thrust::make_counting_iterator(begin),
        thrust::make_counting_iterator(end),
        ErodePixelFunctor(firstSubiter, buffer1.pixels.data().get(), buffer2.pixels.data().get(), w, h),
        0,
        thrust::bit_or<bool>()
    );

    // Continue while some pixels were deleted
    return eroded;
}
