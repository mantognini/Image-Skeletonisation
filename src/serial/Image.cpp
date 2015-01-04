//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#include "Image.hpp"

#include <SFML/Graphics/Image.hpp>

#include <cassert>
#include <stdexcept>

BWImage loadImage(std::string const& filename)
{
    // Use SFML to load the image
    sf::Image image;
    if (image.loadFromFile(filename)) {

        // Convert the image to BWImage format, with a border padding for optimisation purpose
        BWImage bwimage(image.getSize().x + 2, image.getSize().y + 2, BWImage::WHITE);

        for (int i = 0; i < image.getSize().x; ++i) {
            for (int j = 0; j < image.getSize().y; ++j) {
                auto const color = image.getPixel(i, j);
                auto const pixel = (color == sf::Color::Black) ? BWImage::BLACK : BWImage::WHITE;
                bwimage(i + 1, j + 1) = pixel;

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

void saveImage(std::string const& filename, BWImage const& bwimage)
{
    auto const w = bwimage.getWidth();
    auto const h = bwimage.getHeight();

    // Convert the BWImage back to sf::Image without the extra padding
    sf::Image image;
    image.create(w - 2, h - 2);

    for (int i = 1; i < w - 1; ++i) {
        for (int j = 1; j < h - 1; ++j) {
            auto const pixel = bwimage(i, j);
            auto const color = (pixel == BWImage::BLACK) ? sf::Color::Black : sf::Color::White;
            image.setPixel(i - 1, j - 1, color);
        }
    }

    // Use SFML to save the image to disk
    if (!image.saveToFile(filename)) {
        throw std::runtime_error(filename + " was not properly saved");
    }
}
