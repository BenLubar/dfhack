#pragma once

#include <algorithm>
#include "layer.h"
#include "fc.h"

// implements an L2 regression cost layer,
// so penalizes \sum_i(||x_i - y_i||^2), where x is its input
// and y is the user-provided array of "correct" values.
template<typename parent_t, typename input_t, size_t _size>
class Regression : public LossLayer<FullyConn<parent_t, input_t, _size, false>, input_t, _size> {
public:
    Regression() {
    }

    virtual ~Regression() {
    }

    virtual void forward(const input_t &v, bool is_training = false) {
        this->parent.forward(v, is_training);
        std::copy(&this->parent.act.param[0], &this->parent.act.param[out_size], &this->act.param[0]);
    }

	// compute and accumulate gradient wrt weights and bias of this layer
    virtual float loss(size_t i, float v) {
        std::fill(&this->parent.act.grad[0], &this->parent.act.grad[out_size], 0);

    	float x = this->parent.act.param[i] - v;
    	this->parent.act.grad[i] = x;

	    return x * x / 2;
    }
};

// vim: et:ts=4:sw=4
