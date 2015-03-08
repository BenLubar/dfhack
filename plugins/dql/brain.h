#pragma once

#include <algorithm>
#include <random>
#include "window.h"
#include "loss_result.h"
#include "ColorText.h"

template<
    typename network_t,
    typename trainer_t,
    typename action_t,
    size_t num_states,
    size_t num_actions,
    size_t temporal_window,
    size_t experience_size = 50,
    size_t start_learn_threshold = 10,
    size_t learning_steps_total = 200000,
    size_t learning_steps_burnin = 3000
>
class Brain {
private:
    static constexpr float gamma = 0.7;
    static constexpr float epsilon_min = 0.05;
    static constexpr float epsilon_test_time = 0.05;
public:
    static const size_t net_inputs = num_states*temporal_window + num_actions*temporal_window + num_states;
    typedef bool net_input_t[net_inputs];
    typedef bool input_t[num_states];

    typedef struct {
        net_input_t state0;
        action_t    action0;
        float       reward0;
        net_input_t state1;
    } experience_t;

    static const size_t window_size = temporal_window < 2 ? 2 : temporal_window;
    Window<input_t,     window_size> state_window;
    Window<action_t,    window_size> action_window;
    Window<float,       window_size> reward_window;
    Window<net_input_t, window_size> net_window;
    RandomWindow<experience_t, experience_size>  experience;

    network_t value_net;

    float  epsilon;
    AverageWindow<float, 1000> average_reward_window;
    AverageWindow<float, 1000> average_loss_window;
    bool    learning;
    int32_t age;
    int32_t forward_passes;

    trainer_t tdtrainer;

    std::default_random_engine random_engine;
    std::uniform_int_distribution<int32_t> action_distribution;
    std::uniform_real_distribution<float> epsilon_distribution;

    Brain() : value_net(), tdtrainer(&value_net), action_distribution(0, num_actions - 1), epsilon_distribution(0, 1) {
    }

    virtual ~Brain() {
    }

    virtual action_t random_action() {
        return (action_t) action_distribution(random_engine);
    }

    virtual action_t policy(net_input_t s, float *value = nullptr) {
        value_net.forward(s);
        float (&action_values)[num_actions] = value_net.act.param;
        action_t action = (action_t) 0;
        for (int i = 1; i < num_actions; i++) {
            if (action_values[i] > action_values[action]) {
                action = (action_t) i;
                if (value) {
                    *value = action_values[i];
                }
            }
        }
        return action;
    }

    virtual void net_input(net_input_t& w, const input_t& xt) {
        bool *pw = &w[0];

        // start with current input
        pw = std::copy(&xt[0], &xt[num_states], pw);

        size_t i = 0;
        // encode each previous input
        for (const input_t& state : state_window) {
            if (window_size != temporal_window) {
                // this block can be optimized out by the compiler

                if (window_size - state_window.size() < temporal_window - i) {
                    i++;
                    continue;
                }
            }
            pw = std::copy(&state[0], &state[num_states], pw);
        }

        i = 0;
        // make sure we're in the right place in the array for when
        // we haven't reached the buffer size yet.
        pw = &w[num_states*temporal_window + num_states];

        // encode each previous action
        for (const action_t& action : action_window) {
            if (window_size != temporal_window) {
                // this block can be optimized out by the compiler

                if (window_size - action_window.size() < temporal_window - i) {
                    i++;
                    continue;
                }
            }
            pw[action] = true;
            pw += num_actions;
        }
    }

    // compute forward (behavior) pass given the input neuron signals from body
    virtual action_t forward(input_t input) {
        forward_passes++;

        action_t action;
        // create network input
        net_input_t ni;
        net_input(ni, input);
        if (learning) {
            // compute epsilon for the epsilon-greedy policy
            epsilon = std::min(float(1), std::max(epsilon_min, 1 - float(age - learning_steps_burnin) / float(learning_steps_total - learning_steps_burnin)));
        } else {
            // use test-time value
            epsilon = epsilon_test_time;
        }

        if (epsilon_distribution(random_engine) < epsilon) {
            // choose a random action with epsilon probability
            action = random_action();
        } else {
            // otherwise use our policy to make decision
            action = policy(ni);
        }

        // remember the state and action we took for backward pass
        net_window.add(ni);
        state_window.add(input);
        action_window.add(action);

        return action;
    }

    virtual void backward(float reward) {
        average_reward_window.add(reward);
        reward_window.add(reward);

        if (!learning) {
            return;
        }

        age++;

        // it is time t+1 and we have to store (s_t, a_t, r_t, s_{t+1}) as new experience
        // (given that an appropriate number of state measurements already exist, of course)
        if (forward_passes > temporal_window + 1) {
            experience_t e;
            e.state0  = *(net_window.begin()    + 1);
            e.action0 = *(action_window.begin() + 1);
            e.reward0 = *(reward_window.begin() + 1);
            e.state1  = *(net_window.begin());
            experience.add(e);
        }

        // learn based on experience, once we have some samples to go on
        // this is where the magic happens...
        if (experience.size() > start_learn_threshold) {
            float avcost = 0;
            for (size_t k = 0; k < trainer_t::batch; k++) {
                experience_t e = *(experience.begin() + std::uniform_int_distribution<size_t>(0, experience.size() - 1)(random_engine));
                float value;
                policy(e.state1, &value);
                float r = e.reward0 + gamma*value;
                loss_result_t loss = tdtrainer.train(e.state0, e.action0, r);
                avcost += loss.loss;
            }
            avcost = avcost / float(trainer_t::batch);
            average_loss_window.add(avcost);
        }
    }

    virtual void print_to(DFHack::color_ostream& out) {
        out.print("experience replay size: %d\n", experience.size());
        out.print("exploration epsilon: %f\n", epsilon);
        out.print("age: %d\n", age);
        out.print("average Q-learning loss: %f\n", average_loss_window.average());
        out.print("smooth-ish reward: %f\n", average_reward_window.average());
    }
};

// vim: et:ts=4:sw=4
