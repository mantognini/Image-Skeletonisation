//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#include <thrust/copy.h>

template <typename Pixels>
template <typename Container>
void BWImage<Pixels>::copyFrom(Container const& container)
{
    thrust::copy(container.pixels.begin(), container.pixels.end(), this->pixels.begin());
}

