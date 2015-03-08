#pragma once

#include <algorithm>

template<typename value_t, size_t size>
struct array {
    typedef value_t * iterator;

    value_t v[size];

    inline array<value_t, size>& operator=(array<value_t, size>& other) {
        std::copy(&v[0], &v[size], &other[0]);
        return *this;
    }

    inline value_t& operator[](int i) {
        return v[i];
    }

    inline iterator begin() {
        return &v[0];
    }

    inline iterator end() {
        return &v[size];
    }
};

// vim: et:ts=4:sw=4
