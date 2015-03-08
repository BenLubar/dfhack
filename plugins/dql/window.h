#pragma once

#include <algorithm>
#include <random>
#include "array.h"

template<typename value_t, size_t max_size>
struct Window {
protected:
    array<value_t, max_size> v;
    size_t s;

public:
    typedef value_t * iterator;

    Window() {
    }

    void add(value_t x) {
        std::copy_backward(&v[0], &v[size() - 1], &v[size()]);
        v[0] = x;
        if (size() < max_size) {
            s++;
        }
    }

    inline size_t size() {
        return s;
    }

    iterator begin() {
        return &v[0];
    }

    iterator end() {
        return &v[size()];
    }
};

template<typename value_t, size_t max_size>
struct RandomWindow : Window<value_t, max_size> {
protected:
    std::default_random_engine generator;
    std::uniform_int_distribution<size_t> distribution;

public:
    RandomWindow() : distribution(0, max_size - 1) {
    }

    void add(value_t x) {
        if (this->size() == max_size) {
            this->v[distribution(generator)] = x;
        } else {
            this->v[this->s] = x;
            this->s++;
        }
    }

};

template<typename value_t, size_t max_size>
struct AverageWindow : Window<value_t, max_size> {
protected:
    value_t sum;

public:
    AverageWindow() : sum(0) {
    }

    void add(value_t x) {
        if (this->size() == max_size) {
            sum -= this->v[max_size - 1];
        }
        Window<value_t, max_size>::add(x);
        sum += x;
    }

    value_t average() {
        return sum / value_t(this->size());
    }
};

// vim: et:ts=4:sw=4
