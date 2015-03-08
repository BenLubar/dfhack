#pragma once

#include "array.h"

template<size_t dim>
struct vol_t {
    static const size_t size = dim;
    array<float, size> param;
    array<float, size> grad;
};

// vim: et:ts=4:sw=4
