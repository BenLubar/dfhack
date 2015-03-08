#pragma once

#include <algorithm>
#include "loss_result.h"
#include "vol.h"

template<
    typename input_t,
    size_t num_states,
    size_t num_actions,
    size_t temporal_window
>
class Input {
public:
    static const size_t out_size = num_states*temporal_window + num_actions*temporal_window + num_states;

    Input() {
    }

    virtual ~Input() {
    }

    virtual void forward(const input_t &v, bool is_training = false) {
        for (size_t i = 0; i < out_size; i++) {
            act.param[i] = v[i] ? (out_size - i <= num_actions * temporal_window) ? float(num_states) : 1 : 0;
        }
    }

    virtual void backward() {
    }

    virtual void train(float l1, float l2, float learning_rate, size_t batch_size, loss_result_t& loss) {
    }

    vol_t<out_size> act;
};

// vim: et:ts=4:sw=4
