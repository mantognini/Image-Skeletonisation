//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#include "Image.cuh"

#include <SFML/Graphics/Image.hpp>

#include <cassert>
#include <stdexcept>

BWImage<HostPixels> loadImage(std::string const& filename)
{
    // Use SFML to load the image
    sf::Image image;
    if (image.loadFromFile(filename)) {

        // Convert the image to BWImage format, with a border padding for optimisation purpose
        BWImage<HostPixels> bwimage(image.getSize().x + 2, image.getSize().y + 2, WHITE);

        for (int i = 0; i < image.getSize().x; ++i) {
            for (int j = 0; j < image.getSize().y; ++j) {
                sf::Color const color = image.getPixel(i, j);
                Pixel const pixel = (color == sf::Color::Black) ? BLACK : WHITE;
                bwimage.set(i + 1, j + 1, pixel);

#ifdef DEBUG
                if (color != sf::Color::Black and color != sf::Color::White) {
                    throw std::runtime_error("non black and white image");
                }
#endif
            }
        }

        return bwimage;
    }
    else {
        throw std::runtime_error(filename + " was not properly loaded");
    }
}

void saveImage(std::string const& filename, BWImage<HostPixels> const& bwimage)
{
    std::size_t const w = bwimage.width;
    std::size_t const h = bwimage.height;

    // Convert the BWImage back to sf::Image without the extra padding
    sf::Image image;
    image.create(w - 2, h - 2);

    for (int i = 1; i < w - 1; ++i) {
        for (int j = 1; j < h - 1; ++j) {
            Pixel const pixel = bwimage.get(i, j);
            sf::Color const color = (pixel == BLACK) ? sf::Color::Black : sf::Color::White;
            image.setPixel(i - 1, j - 1, color);
        }
    }

    // Use SFML to save the image to disk
    if (!image.saveToFile(filename)) {
        throw std::runtime_error(filename + " was not properly saved");
    }
}
