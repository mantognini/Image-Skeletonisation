//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#include "Skeleton.hpp"
#include "Image.hpp"

#include <SFML/System/Clock.hpp>

#include <array>
#include <utility>

static auto constexpr FOREGROUND = BWImage::BLACK;
static auto constexpr BACKGROUND = BWImage::WHITE;

using Position = std::pair<int, int>;
Position makePosition(int x, int y) { return std::make_pair(x, y); }

/**
 *  @brief Erode one pixel
 *
 *  @param img          an image
 *  @param p            (x, y) coord, in the image boundaries
 *  @param firstSubiter identify the kind of subiteration
 *
 *  @return true if the pixel was eroded
 */
bool erodePixel(BWImage const& img, Position const& p, bool firstSubiter);

/**
 *  @brief Perform a subiteration of the thining process
 *
 *  @param img          an image
 *  @param firstSubiter identify the kind of subiteration
 *
 *  @return true if one pixel was eroded
 */
bool erodeIter(BWImage& img, bool firstSubiter);

/**
 *  @brief Erode pixels
 *
 *  @param img image to process
 *
 *  @return true if some pixels were changed
 */
bool erode(BWImage& img);

/**
 *  @brief Check if the given pixel is black
 *
 *  @param img an image
 *  @param p   (x, y) coord, in the image boundaries
 *
 *  @return true if the image is black at (x, y)
 */
bool isBackground(BWImage const& img, Position const& p);

/**
 *  @brief Check if the given pixel is white
 *
 *  @param img an image
 *  @param p   (x, y) coord, in the image boundaries
 *
 *  @return true if (x, y) is outside the image or the pixel is white (not black)
 */
bool isForeground(BWImage const& img, Position const& p);

/**
 *  @brief Set the given pixel as background
 *
 *  @param img an image
 *  @param p   (x, y) coord, in the image boundaries
 */
void setBackground(BWImage& img, Position const& p);

//************************************************************************************************//
//                                      IMPLEMENTATION                                            //
//************************************************************************************************//

void skeleton(std::string const& input, std::string const& output, sf::Time& elapsed, int& iterations)
{
    // Load the image from disk
    sf::Clock clk;
    auto img = loadImage(input);

#ifndef ENABLE_SAVE_IMAGE
    // Ignore I/O time when not saving the image
    clk.restart();
#endif

    iterations = 0;
    for (bool run = true; run; ++iterations) {
        run = erode(img);
    }

#ifdef ENABLE_SAVE_IMAGE
    saveImage(output, img);
#endif

    // Included I/O time when ENABLE_SAVE_IMAGE is defined
    elapsed = clk.restart();
}

bool erodePixel(BWImage const& img, Position const& p, bool firstSubIteration)
{
    if (isBackground(img, p)) {
        return false;
    }

    using RelativePositions = std::array<Position, 8>;

    // Index i maps to the position of neighbour x(i)
    RelativePositions const rp = {
        /* x1 */ makePosition(p.first + 1, p.second),
        /* x2 */ makePosition(p.first + 1, p.second - 1),
        /* x3 */ makePosition(p.first, p.second - 1),
        /* x4 */ makePosition(p.first - 1, p.second - 1),
        /* x5 */ makePosition(p.first - 1, p.second),
        /* x6 */ makePosition(p.first - 1, p.second + 1),
        /* x7 */ makePosition(p.first, p.second + 1),
        /* x8 */ makePosition(p.first + 1, p.second + 1)
    };

    // Fix the mapping and convert it to 0 / 1
    auto const xi = [&rp, &img](char i) { return !isBackground(img, rp[i]); };

    // Xh: Hiditch's crossing number
    auto const Xh =
        /* b(1) */ (!xi(0) & (xi(1) | xi(2))) +
        /* b(2) */ (!xi(2) & (xi(3) | xi(4))) +
        /* b(3) */ (!xi(4) & (xi(5) | xi(6))) +
        /* b(4) */ (!xi(6) & (xi(7) | xi(0)));

    // G1:
    if (Xh != 1) {
        return false;
    }

    // N1 and N2
    auto const N1 = (xi(1) | xi(0)) + (xi(3) | xi(2)) + (xi(5) | xi(4)) + (xi(7) | xi(6));
    auto const N2 = (xi(2) | xi(1)) + (xi(4) | xi(3)) + (xi(6) | xi(5)) + (xi(0) | xi(7));

    // G2:
    auto min = std::min(N1, N2);
    if (min < 2 or 3 < min) {
        return false;
    }

    // G3 / G3'
    auto rot = firstSubIteration ? 0 : 4; // 180° rotation for 2nd sub iteration
    if (((xi(1 + rot) | xi(2 + rot) | !xi(7 - rot)) & xi(0 + rot)) != 0) {
        return false;
    }

    // G1, G2 and G3/G3' are all true
    return true;
}

bool erodeIter(BWImage& img, bool firstSubiter)
{
    auto const w = img.getWidth();
    auto const h = img.getHeight();

    std::vector<Position> toErode;

    for (int i = 1; i < w - 1; ++i) {
        for (int j = 1; j < h - 1; ++j) {
            auto const p = makePosition(i, j);
            if (erodePixel(img, p, firstSubiter)) {
                toErode.push_back(p);
            }
        }
    }

    for (auto const& p : toErode) {
        setBackground(img, p);
    }

#ifdef DEBUG
    auto const size = toErode.size();
#endif

    return !toErode.empty();
}

bool erode(BWImage& img)
{
    auto const eroded1 = erodeIter(img, true);
    auto const eroded2 = erodeIter(img, false);
    return eroded1 or eroded2;
}

bool isBackground(BWImage const& img, Position const& p)
{
    return img(p) == BACKGROUND;
}

bool isForeground(BWImage const& img, Position const& p)
{
    return img(p) == FOREGROUND;
}

void setBackground(BWImage& img, Position const& p)
{
    img(p) = BACKGROUND;
}
