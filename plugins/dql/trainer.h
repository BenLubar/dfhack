#pragma once

#include "loss_result.h"

template<typename net_t, size_t batch_size = 1, typename input_t = typename net_t::input_t>
struct Trainer {
private:
    static constexpr float learning_rate = 0.01;
    static constexpr float l1_decay = 0.0;
    static constexpr float l2_decay = 0.0;
public:
    static const size_t batch = batch_size;

    Trainer(net_t& n) : net(n) {
    }

    virtual ~Trainer() {
    }

    loss_result_t train(input_t x, size_t i, float v) {
        loss_result_t loss;
        net.forward(x, true);

        loss.cost = net.loss(i, v);
        net.backward();

        k++;
        if (k % batch_size == 0) {
            net.train(l1_decay, l2_decay, learning_rate, batch_size, loss);
        }

        loss.loss = loss.cost + loss.l1_decay + loss.l2_decay;
        return loss;
	}

    size_t k; // iteration counter
    net_t& net;
};

// vim: et:ts=4:sw=4
