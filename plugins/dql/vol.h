#pragma once

template<size_t dim>
struct vol_t {
public:
    static const size_t size = dim;
    float param[size];
    float grad[size];
};

// vim: et:ts=4:sw=4
