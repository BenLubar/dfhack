#pragma once

#include <algorithm>
#include "layer.h"
#include "fc.h"

// implements an L2 regression cost layer,
// so penalizes \sum_i(||x_i - y_i||^2), where x is its input
// and y is the user-provided array of "correct" values.
template<typename parent_t, size_t _size>
struct Regression : Layer<FullyConn<parent_t, _size, false>> {
    Regression() {
    }

    void forward(const typename parent_t::input_t &v, bool is_training = false) {
        this->parent.forward(v, is_training);
        std::copy(&this->parent.act.param[0], &this->parent.act.param[_size], &this->act.param[0]);
    }

	// compute and accumulate gradient wrt weights and bias of this layer
    float loss(size_t i, float v) {
        std::fill(&this->parent.act.grad[0], &this->parent.act.grad[_size], 0);

    	float x = this->parent.act.param[i] - v;
    	this->parent.act.grad[i] = x;

	    return x * x / 2;
    }
};

// vim: et:ts=4:sw=4
