//
//  Image Skeletonisation - Copyright (c) 2014 Marco Antognini <antognini.marco@gmail.com>
//  Under zlib/png license. Refer to LICENSE for the full text.
//

#include "Skeleton.hpp"

#include <boost/program_options.hpp>

#include <cstdlib>
#include <exception>
#include <iostream>
#include <string>

namespace po = boost::program_options;

/**
 * @brief Get the last element of a path
 */
std::string stem(std::string path);

int main(int argc, char const** argv) try {
    // Declare the supported options.
    po::options_description desc("Allowed options");
    desc.add_options()("help", "produce help message")("input", po::value<std::string>(), "input image filename")("output", po::value<std::string>(), "output filename");

    po::variables_map vm;
    po::store(po::parse_command_line(argc, argv, desc), vm);
    po::notify(vm);

    if (vm.count("help")) {
        std::cout << desc << std::endl;
        return 1;
    }

    if (vm.count("input") == 0) {
        std::cerr << "Missing input file" << std::endl;
        std::cout << desc << std::endl;
        return 2;
    }

    if (vm.count("output") == 0) {
        std::cerr << "Missing output file" << std::endl;
        std::cout << desc << std::endl;
        return 3;
    }

    sf::Time elapsed = sf::Time::Zero;
    int iterations = 0;
    std::string input = vm["input"].as<std::string>();
    std::string output = vm["output"].as<std::string>();
    skeleton(input, output, elapsed, iterations);

    std::string exe = stem(argv[0]);
    std::string inputName = stem(input);
    std::string outputName = stem(output);

    std::cout << exe << ";" << inputName << ";" << iterations << ";" << elapsed.asMilliseconds() << std::endl;

    return EXIT_SUCCESS;
}
catch (std::exception& e) {
    std::cerr << "skeleton stopped impromptu \n"
              << "Error: " << e.what() << std::endl;
    return EXIT_FAILURE;
}

std::string stem(std::string path)
{
    std::string::size_type lastSlash = path.rfind('/');
    if (lastSlash != std::string::npos && lastSlash < path.length()) {
        return path.substr(lastSlash + 1);
    } else {
        return path;
    }
}
