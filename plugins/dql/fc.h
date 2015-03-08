#pragma once

#include <algorithm>
#include <random>
#include "layer.h"
#include "loss_result.h"

template<typename parent_t, typename input_t, size_t num_neurons, bool use_bias = true>
class FullyConn : public Layer<parent_t, input_t, num_neurons> {
private:
    static constexpr float bias_pref = use_bias ? 0.1 : 0.0;
    static constexpr float l1_mul = 0.0;
    static constexpr float l2_mul = 1.0;

public:
    FullyConn() {
        std::default_random_engine generator;
        std::normal_distribution<float> norm(0, sqrt(1.0 / float(parent_t::out_size)));
	    for (size_t i = 0; i < num_neurons; i++) {
            for (size_t j = 0; j < parent_t::out_size; j++) {
	            filter[i].param[j] = norm(generator);
            }
        }
        std::fill(&biases.param[0], &biases.param[num_neurons], bias_pref);
    }

    virtual ~FullyConn() {
    }

    vol_t<parent_t::out_size> filter[num_neurons];
    vol_t<num_neurons> biases;

    virtual void forward(const input_t &v, bool is_training = false) {
        this->parent.forward(v, is_training);
	    for (size_t i = 0; i < num_neurons; i++) {
            float x = 0;
            for (size_t j = 0; j < parent_t::out_size; j++) {
                x += this->parent.act.param[j] * filter[i].param[j];
            }
            this->act.param[i] = x + biases.param[i];
        }
    }

    virtual void backward() {
        std::fill(&this->parent.act.grad[0], &this->parent.act.grad[parent_t::out_size], 0);

	    for (size_t i = 0; i < num_neurons; i++) {
            float grad = this->act.grad[i];
            for (size_t j = 0; j < parent_t::out_size; j++) {
                this->parent.act.grad[j] += filter[i].param[j] * grad; // grad wrt input data
                filter[i].grad[j] += this->parent.act.param[j] * grad; // grad wrt params
            }
            biases.grad[i] += grad;
        }
        this->parent.backward();
    }

    virtual void train(float l1, float l2, float learning_rate, size_t batch_size, loss_result_t& loss) {
	    for (size_t i = 0; i < num_neurons; i++) {
            this->sgd(filter[i], l1, l2, l1_mul, l2_mul, learning_rate, batch_size, loss);
        }
        this->sgd(biases, l1, l2, 0, 0, learning_rate, batch_size, loss);

        this->parent.train(l1, l2, learning_rate, batch_size, loss);
    }
};

// vim: et:ts=4:sw=4
