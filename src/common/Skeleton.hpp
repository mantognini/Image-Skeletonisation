//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#ifndef __Image_Skeletonisation__skeleton__
#define __Image_Skeletonisation__skeleton__

#include <SFML/System/Time.hpp>

#include <string>

/**
 *  @brief Skeletonise the image
 *
 *  @param input      input image file
 *  @param output     output image file
 *  @param elapsed    output parameter for the time required by the computation itself (no I/O)
 *  @param iterations output parameter for the number of iteration of the computation
 */
void skeleton(std::string const& input, std::string const& output, sf::Time& elapsed, int& iterations);

#endif /* defined(__Image_Skeletonisation__skeleton__) */
