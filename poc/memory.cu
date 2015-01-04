//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

//
// Playground for memory operations and Thrust
//

#include <thrust/device_vector.h>
#include <thrust/memory.h>
#include <thrust/iterator/constant_iterator.h>
#include <thrust/iterator/counting_iterator.h>

#include <cassert>
#include <ios>
#include <iomanip>
#include <iostream>

// #define MANUAL

int const W = 5;
int const H = 5;
int const N = W * H;

#define INDEX_OF(i, j) ((j) * W + (i))

typedef bool TYPE;
typedef TYPE* RAW_PTR;

struct Functor {
    __device__ TYPE operator()(int index, RAW_PTR pdata)
    {
        return !pdata[index];
    }
};

void print(thrust::host_vector<TYPE> const& h_data)
{
    for (size_t i = 0; i < W; ++i) {
        for (size_t j = 0; j < H; ++j) {
           std::cout << std::setw(10) << h_data[INDEX_OF(i, j)];
        }
        std::cout << std::endl;
    }
}

int main()
{
    // Acquire data
#ifdef MANUAL
    thrust::device_ptr<TYPE> pbuffer1 = thrust::device_malloc<TYPE>(N); // uninitialised
    thrust::device_ptr<TYPE> pbuffer2 = thrust::device_malloc<TYPE>(N); // uninitialised
#else
    thrust::device_vector<TYPE> buffer1(N);
    thrust::device_vector<TYPE>::pointer pbuffer1 = buffer1.data();
    thrust::device_vector<TYPE> buffer2(N);
    thrust::device_vector<TYPE>::pointer pbuffer2 = buffer2.data();
#endif

    // Transform data: initialise first buffer and transform it into the second one
    using namespace thrust::placeholders;
    thrust::transform(
        thrust::make_counting_iterator(0),
        thrust::make_counting_iterator(N),
        pbuffer1,
        _1 % 2 == 0
    );

    thrust::transform(
        thrust::make_counting_iterator(0),
        thrust::make_counting_iterator(N),
        thrust::make_constant_iterator(pbuffer1.get()),
        pbuffer2,
        Functor()
    );

    // Get data
    thrust::host_vector<TYPE> h_data1(N);
    thrust::copy_n(pbuffer1, N, h_data1.begin());
    thrust::host_vector<TYPE> h_data2(N);
    thrust::copy_n(pbuffer2, N, h_data2.begin());

    // Release data
#ifdef MANUAL
    thrust::device_free(pbuffer1);
    thrust::device_free(pbuffer2);
#else
    // buffers are automatically freed when exiting the function
#endif

    // Print the result
    std::cout << std::boolalpha;
    std::cout << "Data1:" << std::endl;
    print(h_data1);
    std::cout << "Data2:" << std::endl;
    print(h_data2);

    return 0;
}
