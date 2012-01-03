/*
https://github.com/peterix/dfhack
Copyright (c) 2009-2011 Petr Mrázek (peterix@gmail.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any
damages arising from the use of this software.

Permission is granted to anyone to use this software for any
purpose, including commercial applications, and to alter it and
redistribute it freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must
not claim that you wrote the original software. If you use this
software in a product, an acknowledgment in the product documentation
would be appreciated but is not required.

2. Altered source versions must be plainly marked as such, and
must not be misrepresented as being the original software.

3. This notice may not be removed or altered from any source
distribution.
*/

#pragma once
#include "Export.h"
#include <iostream>
#include <iomanip>
#include <climits>
#include <stdint.h>
#include <vector>
#include <sstream>
#include <cstdio>

using namespace std;

template <typename T>
void print_bits ( T val, DFHack::Console& out )
{
    stringstream strs;
    T n_bits = sizeof ( val ) * CHAR_BIT;
    int cnt;
    for ( unsigned i = 0; i < n_bits; ++i )
    {
        cnt = i/10;
        strs << cnt << " ";
    }
    strs << endl;
    for ( unsigned i = 0; i < n_bits; ++i )
    {
        cnt = i%10;
        strs << cnt << " ";
    }
    strs << endl;
    for ( unsigned i = 0; i < n_bits; ++i )
    {
        strs << "--";
    }
    strs << endl;
    for ( unsigned i = 0; i < n_bits; ++i )
    {
        strs<< !!( val & 1 ) << " ";
        val >>= 1;
    }
    strs << endl;
    out.print(strs.str().c_str());
}

/*
 * Binary search in vectors.
 */

template <typename FT>
int binsearch_index(const std::vector<FT> &vec, FT key, bool exact = true)
{
    // Returns the index of the value >= the key
    int min = -1, max = (int)vec.size();
    const FT *p = vec.data();
    for (;;)
    {
        int mid = (min + max)>>1;
        if (mid == min)
            return exact ? -1 : max;
        FT midv = p[mid];
        if (midv == key)
            return mid;
        else if (midv < key)
            min = mid;
        else
            max = mid;
    }
}

template <typename CT, typename FT>
int binsearch_index(const std::vector<CT*> &vec, FT CT::*field, FT key, bool exact = true)
{
    // Returns the index of the value >= the key
    int min = -1, max = (int)vec.size();
    CT *const *p = vec.data();
    for (;;)
    {
        int mid = (min + max)>>1;
        if (mid == min)
            return exact ? -1 : max;
        FT midv = p[mid]->*field;
        if (midv == key)
            return mid;
        else if (midv < key)
            min = mid;
        else
            max = mid;
    }
}

template <typename CT>
inline int binsearch_index(const std::vector<CT*> &vec, typename CT::key_field_type key, bool exact = true)
{
    return CT::binsearch_index(vec, key, exact);
}

template <typename CT>
inline int binsearch_index(const std::vector<CT*> &vec, typename CT::key_pointer_type key, bool exact = true)
{
    return CT::binsearch_index(vec, key, exact);
}

template<typename FT, typename KT>
inline bool vector_contains(const std::vector<FT> &vec, KT key)
{
    return binsearch_index(vec, key) >= 0;
}

template<typename CT, typename FT>
inline bool vector_contains(const std::vector<CT*> &vec, FT CT::*field, FT key)
{
    return binsearch_index(vec, field, key) >= 0;
}

template<typename FT>
unsigned insert_into_vector(std::vector<FT> &vec, FT key, bool *inserted = NULL)
{
    unsigned pos = (unsigned)binsearch_index(vec, key, false);
    bool to_ins = (pos >= vec.size() || vec[pos] != key);
    if (inserted) *inserted = to_ins;
    if (to_ins)
        vec.insert(vec.begin()+pos,key);
    return pos;
}

template<typename CT, typename FT>
unsigned insert_into_vector(std::vector<CT*> &vec, FT CT::*field, CT *obj, bool *inserted = NULL)
{
    unsigned pos = (unsigned)binsearch_index(vec, field, obj->*field, false);
    bool to_ins = (pos >= vec.size() || vec[pos] != obj);
    if (inserted) *inserted = to_ins;
    if (to_ins)
        vec.insert(vec.begin()+pos,obj);
    return pos;
}

template <typename CT, typename KT>
CT *binsearch_in_vector(const std::vector<CT*> &vec, KT value)
{
    int idx = binsearch_index(vec, value);
    return idx < 0 ? NULL : vec[idx];
}

template <typename CT, typename FT>
CT *binsearch_in_vector(const std::vector<CT*> &vec, FT CT::*field, FT value)
{
    int idx = binsearch_index(vec, field, value);
    return idx < 0 ? NULL : vec[idx];
}

/*
 * MISC
 */

/**
 * Returns the amount of milliseconds elapsed since the UNIX epoch.
 * Works on both windows and linux.
 * source: http://stackoverflow.com/questions/1861294/how-to-calculate-execution-time-of-a-code-snippet-in-c
 */
DFHACK_EXPORT uint64_t GetTimeMs64();

DFHACK_EXPORT std::string stl_sprintf(const char *fmt, ...);
DFHACK_EXPORT std::string stl_vsprintf(const char *fmt, va_list args);
