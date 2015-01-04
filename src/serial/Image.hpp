//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#ifndef __Image_Skeletonisation__Image__
#define __Image_Skeletonisation__Image__

#include <string>
#include <vector>

class BWImage {
public:
    using Pixel = bool;
    using PixelRef = std::vector<bool>::reference;

    // For convention purpose
    static constexpr Pixel BLACK = true;
    static constexpr Pixel WHITE = false;

public:
    BWImage(std::size_t width, std::size_t height, Pixel color = BLACK)
        : mWidth(width)
        , mHeight(height)
        , mPixels(width * height, color)
    {
    }

    // Forbid copy to prevent mistakes in processing
    BWImage(BWImage const&) = delete;
    BWImage& operator=(BWImage const&) = delete;

    // But allow move
    BWImage(BWImage&&) = default;
    BWImage& operator=(BWImage&&) = default;

    // Access to the pixels
    Pixel operator()(std::size_t i, std::size_t j) const { return mPixels[indexOf(i, j)]; }
    PixelRef operator()(std::size_t i, std::size_t j) { return mPixels[indexOf(i, j)]; }
    Pixel operator()(std::pair<int, int> const& p) const { return mPixels[indexOf(p.first, p.second)]; }
    PixelRef operator()(std::pair<int, int> const& p) { return mPixels[indexOf(p.first, p.second)]; }

    std::size_t getWidth() const { return mWidth; }
    std::size_t getHeight() const { return mHeight; }

private:
    // Compute linear index of (i, j)
    std::size_t indexOf(std::size_t i, std::size_t j) const
    {
        return j * getWidth() + i;
    }

private:
    std::size_t const mWidth;
    std::size_t const mHeight;
    std::vector<Pixel> mPixels; ///< Linear array
};

// Throw std::runtime_error if the image is not properly loaded
BWImage loadImage(std::string const& filename);

// Throw std::runtime_error if the image is not properly saved
void saveImage(std::string const& filename, BWImage const& image);

#endif /* defined(__Image_Skeletonisation__Image__) */
