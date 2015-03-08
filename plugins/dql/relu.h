#pragma once

#include "layer.h"

// Implements ReLU nonlinearity elementwise
// x -> max(0, x)
// the output is in [0, inf)
template<typename parent_t>
struct ReLU : Layer<parent_t> {
    ReLU() {
    }

    virtual void forward(const typename parent_t::input_t &v, bool is_training = false) {
        this->parent.forward(v, is_training);
        for (size_t i = 0; i < parent_t::out_size; i++) {
            float f = this->parent.act.param[i];
            if (f <= 0) {
                this->act.param[i] = 0; // threshold at 0
            } else {
                this->act.param[i] = f;
            }
        }
    }

    virtual void backward() {
        for (size_t i = 0; i < parent_t::out_size; i++) {
            if (this->act.param[i] <= 0) {
                this->parent.act.grad[i] = 0; // threshold
            } else {
                this->parent.act.grad[i] = this->act.grad[i];
            }
        }
        this->parent.backward();
    }
};

// vim: et:ts=4:sw=4
