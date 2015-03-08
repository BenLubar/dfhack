#pragma once

#include "loss_result.h"
#include "vol.h"

template<typename parent_t, typename input_t, size_t _size>
class Layer {
public:
    static const size_t out_size = _size;

    Layer() {
    }

    virtual ~Layer() {
    }

    template<size_t n>
    void sgd(vol_t<n> &v, float l1, float l2, float l1_mul, float l2_mul, float learning_rate, size_t batch_size, loss_result_t& loss) {
        float l1_decay = l1 * l1_mul;
        float l2_decay = l2 * l2_mul;

        for (size_t i = 0; i < n; i++) {
            float f = v.param[i];

            float l1grad = f < 0 ? -l1_decay : l1_decay;
            float l2grad = l2_decay * f;

            // accumulate weight decay loss
            loss.l2_decay += l2grad * f / 2;
            loss.l1_decay += l1grad * f;

            // raw batch gradient
            float grad = (l2grad + l1grad + v.grad[i]) / float(batch_size);

            // vanilla sgd
            v.param[i] -= learning_rate * grad;
            v.grad[i] = 0.0;
        }
    }

    virtual void forward(const input_t &v, bool is_training = false) {
        parent.forward(v, is_training);
    }
    virtual void backward() {
        parent.backward();
    }
    virtual void train(float l1, float l2, float learning_rate, size_t batch_size, loss_result_t& loss) {
        parent.train(l1, l2, learning_rate, batch_size, loss);
    }

    parent_t parent;
    vol_t<out_size> act;
};

template<typename parent_t, typename input_t, size_t _size>
class LossLayer : public Layer<parent_t, input_t, _size> {
    virtual float loss(size_t i, float v) = 0;
};

// vim: et:ts=4:sw=4
