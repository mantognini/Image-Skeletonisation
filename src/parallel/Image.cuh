//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#ifndef __Image_Skeletonisation__Image__
#define __Image_Skeletonisation__Image__

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>

#include <string>

typedef bool Pixel;

// For convention purpose
const Pixel BLACK = true;
const Pixel WHITE = false;

typedef thrust::device_vector<Pixel> DevicePixels;
typedef thrust::host_vector<Pixel> HostPixels;

template <typename Pixels>
struct BWImage
{
    std::size_t const width;
    std::size_t const height;
    std::size_t const N;
    Pixels            pixels;

    BWImage(std::size_t width, std::size_t height, Pixel init = WHITE)
        : width(width)
        , height(height)
        , N(width * height)
        , pixels(N, init)
    {
    }

    // Load the data from another container which has the same size as this one
    template <typename Container>
    void copyFrom(Container const& container);

    __host__ __device__
    std::size_t indexOf(std::size_t i, std::size_t j) const { return j * width + i; }

    void set(std::size_t i, std::size_t j, Pixel p) { pixels[indexOf(i, j)] = p; }
    Pixel get(std::size_t i, std::size_t j) const { return pixels[indexOf(i, j)]; }
};

// Throw std::runtime_error if the image is not properly loaded
BWImage<HostPixels> loadImage(std::string const& filename);

// Throw std::runtime_error if the image is not properly saved
void saveImage(std::string const& filename, BWImage<HostPixels> const& bwimage);

#include "Image.inl"

#endif /* defined(__Image_Skeletonisation__Image__) */
