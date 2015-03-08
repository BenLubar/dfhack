#pragma once

#include <vector>
#include <algorithm>
#include <random>

template<typename value_t, size_t max_size>
class Window {
protected:
    std::vector<value_t> v;

public:
    typedef typename std::vector<value_t>::const_reverse_iterator iterator;

    Window() {
    }

    virtual ~Window() {
    }

    virtual void add(value_t x) {
        if (size() == max_size) {
            std::copy(v.cbegin() + 1, v.cend(), v.begin());
            *v.end() = x;
        } else {
            v.push_back(x);
        }
    }

    virtual size_t size() {
        return v.size();
    }

    iterator begin() {
        return v.crbegin();
    }

    iterator end() {
        return v.crend();
    }
};

template<typename value_t, size_t max_size>
class RandomWindow : public Window<value_t, max_size> {
protected:
    std::default_random_engine generator;
    std::uniform_int_distribution<size_t> distribution;

public:
    RandomWindow() : distribution(0, max_size - 1) {
    }

    virtual ~RandomWindow() {
    }

    virtual void add(value_t x) {
        if (this->size() == max_size) {
            this->v[distribution(generator)] = x;
        } else {
            this->v.push_back(x);
        }
    }
};

template<typename value_t, size_t max_size>
class AverageWindow : public Window<value_t, max_size> {
protected:
    value_t sum;

public:
    AverageWindow() : sum(0) {
    }

    virtual ~AverageWindow() {
    }

    virtual void add(value_t x) {
        if (this->size() == max_size) {
            sum -= this->v.at(0);
            std::copy(this->v.cbegin() + 1, this->v.cend(), this->v.begin());
            *this->v.end() = x;
        } else {
            this->v.push_back(x);
        }
        sum += x;
    }

    virtual value_t average() {
        return sum / this->size();
    }
};

// vim: et:ts=4:sw=4
