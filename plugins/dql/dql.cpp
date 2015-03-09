#include "Core.h"
#include <Console.h>
#include <Export.h>
#include <PluginManager.h>

#include "DataDefs.h"
#include "modules/Screen.h"
#include "modules/Gui.h"
#include "df/interface_key.h"
#include "df/world.h"
#include "df/game_mode.h"

#include <algorithm>

#include "brain.h"
#include "trainer.h"
#include "input.h"
#include "fc.h"
#include "relu.h"
#include "regression.h"
#include "window.h"

using namespace DFHack;
using namespace DFHack::Screen;

DFHACK_PLUGIN("dql");

const size_t dql_num_states = ((1<<8 /* ch */) + (1 /* bold */) + (1<<3 /* fg */) + (1<<3 /* bg */)) * 80 * 25;
const size_t dql_num_actions = df::enum_traits<df::interface_key>::last_item_value - df::enum_traits<df::interface_key>::first_item_value + 1;
const size_t dql_temporal_window = 1;

template<typename parent_t>
using dql_fc = ReLU<FullyConn<parent_t, 50>>;
using dql_network = Regression<dql_fc<dql_fc<Input<dql_num_states, dql_num_actions, dql_temporal_window> > >, dql_num_actions>;
using dql_trainer = Trainer<dql_network>;
using dql_brain = Brain<dql_network, dql_trainer, df::interface_key, dql_num_states, dql_num_actions, dql_temporal_window>;

static dql_brain *the_brain = nullptr;
static bool is_active = false;
DFHACK_PLUGIN_IS_ENABLED(is_enabled);

REQUIRE_GLOBAL(gview);
REQUIRE_GLOBAL(world);
REQUIRE_GLOBAL(gamemode);
REQUIRE_GLOBAL(cur_year);
REQUIRE_GLOBAL(cur_year_tick);
REQUIRE_GLOBAL(cur_year_tick_advmode);

command_result dql(color_ostream& out, std::vector<std::string>& parameters);

// Mandatory init function. If you have some global state, create it here.
DFhackCExport command_result plugin_init(color_ostream& out, std::vector<PluginCommand>& commands) {
    // Fill the command list with your commands.
    commands.push_back(PluginCommand(
        "dql", "A deep Q-learning artifical intelligence",
        dql, false, /* true means that the command can't be used from non-interactive user interface */
        // Extended help string. Used by CR_WRONG_USAGE and the help command:
        "  An artificial intelligence that learns by bashing the keyboard.\n"
        "  This plugin takes a lot of memory, so if you want to stop using\n"
        "  it, be sure to [unload dql] in the dfhack console.\n"
        "  \n"
        "  Read more about deep Q-learning:\n"
        "    https://en.wikipedia.org/wiki/Deep_learning\n"
        "    https://en.wikipedia.org/wiki/Q-learning\n"
        "    https://cs.stanford.edu/people/karpathy/convnetjs\n"
        "Example:\n"
        "  dql new\n"
        "    Creates a new brain with no knowledge.\n"
        "  dql load [name]\n"
        "    Loads a brain from the specified file.\n"
        "  dql save [name]\n"
        "    Saves a brain to the specified file.\n"
        "  dql start\n"
        "    Starts the learning process. Random keys will be pressed a lot.\n"
        "  dql status\n"
        "    Shows some text describing the status of the brain.\n"
    ));
    return CR_OK;
}

void delete_brain(color_ostream& out) {
    if (the_brain) {
        if (is_active) {
            is_active = false;
            out.print("dql: Brain deactivated!\n");
        }
        delete the_brain;
        the_brain = nullptr;
        out.print("dql: Brain deleted!\n");
    }
}

// This is called right before the plugin library is removed from memory.
DFhackCExport command_result plugin_shutdown(color_ostream& out) {
    delete_brain(out);
    return CR_OK;
}

DFhackCExport command_result plugin_enable(color_ostream& out, bool enable) {
    if (!enable) {
        delete_brain(out);
    }
    is_enabled = enable;
    return CR_OK;
}

DFhackCExport command_result plugin_onupdate(color_ostream& out) {
    if (!is_active) {
        return CR_OK;
    }
    if (!the_brain) {
        is_active = false;
        out.print("dql: Warning: There is no brain, but the brain is active?!\n");
        return CR_OK;
    }
    if (!is_enabled) {
        delete_brain(out);
        return CR_OK;
    }

    static typename dql_brain::input_t prev_input;
    static typename dql_brain::input_t the_input;

    // keep the old input.
    prev_input = the_input;

    // clear out the input array.
    std::fill(&the_input[0], &the_input[dql_num_states], false);

    typename dql_brain::input_t::iterator pi = the_input.begin();
    // for each tile of the screen (assumes 80x25):
    for (int y = 0; y < 25; y++) {
        for (int x = 0; x < 80; x++) {
            Pen tile = readTile(x, y);
            // character
            pi[(uint8_t) tile.ch] = true;
            pi += 1<<8;
            // is the tile bright?
            pi[0] = tile.bold;
            pi += 1;
            // foreground color
            pi[tile.fg & 7] = true;
            pi += 1<<3;
            // background color
            pi[tile.bg & 7] = true;
            pi += 1<<3;
        }
    }

    // ask the brain.
    float value = 0.0;
    df::interface_key action = the_brain->forward(out, the_input, &value);

    out.print("dql:DEBUG: key = %s\n", df::enum_traits<df::interface_key>::key_table[action]);
    out.print("dql:DEBUG: value = %f\n", value);

    // do what it says.
    static interface_key_set keys;
    keys.clear();
    keys.insert(action);
    Gui::getCurViewscreen()->feed(&keys);

    // make sure we're redrawing the screen immediately.
    invalidate();

    // figure out how well we did.
    float game_mode_reward = 0.0;
    if (*gamemode == df::game_mode::ADVENTURE) {
        game_mode_reward = 10.0;
    } else {
        game_mode_reward = -100.0;
    }
    float time_progression_reward = 0.0;
    static int32_t last_year = -1;
    static int32_t last_year_tick = -1;
    static int32_t last_year_tick_advmode = -1;
    if (last_year != *cur_year) {
        time_progression_reward += float(*cur_year - last_year) * 12 * 28 * 24 * 60 * 60;
        last_year = *cur_year;
    }
    if (last_year_tick != *cur_year_tick) {
        time_progression_reward += float(*cur_year_tick - last_year_tick) * 72;
        last_year_tick = *cur_year_tick;
    }
    if (last_year_tick_advmode != *cur_year_tick_advmode) {
        time_progression_reward += float(*cur_year_tick_advmode - last_year_tick_advmode);
        last_year_tick_advmode = *cur_year_tick_advmode;
    }
    time_progression_reward = std::min(std::max(time_progression_reward, float(-100)), float(100));

    float screen_changed_reward = -10.0;
    for (size_t i = 0; i < dql_num_states; i++) {
        if (prev_input[i] != the_input[i]) {
            screen_changed_reward += 0.1;
        }
    }

    static Window<df::interface_key, 4> key_pressed_window;

    float not_pushing_the_same_key_over_and_over_reward = 6.0;
    for (df::interface_key prev_action : key_pressed_window) {
        if (action == prev_action) {
            not_pushing_the_same_key_over_and_over_reward -= 4.0;
        }
    }
    key_pressed_window.add(action);

    float reward = game_mode_reward + time_progression_reward + screen_changed_reward + not_pushing_the_same_key_over_and_over_reward;
    out.print("dql:DEBUG: reward = %f\n", reward);

    // tell the brain.
    the_brain->backward(out, reward);

    return CR_OK;
}

// A command! It sits around and looks pretty. And it's nice and friendly.
command_result dql(color_ostream& out, std::vector<std::string>& parameters) {
    if (!is_enabled) {
        is_enabled = true;
        out.print("dql: Enabling plugin.\n");
    }

    if (parameters.empty()) {
        return CR_WRONG_USAGE;
    }

    CoreSuspender suspend;
    if (parameters[0] == "new") {
        if (parameters.size() != 1) {
            return CR_WRONG_USAGE;
        }
        delete_brain(out);
        the_brain = new dql_brain();
        out.print("dql: Created a new brain.\n");
    } else if (parameters[0] == "load") {
        if (parameters.size() != 2) {
            return CR_WRONG_USAGE;
        }
        delete_brain(out);
        // TODO: load a brain from the specified file.
    } else if (parameters[0] == "save") {
        if (parameters.size() != 2) {
            return CR_WRONG_USAGE;
        }
        if (!the_brain) {
            out.print("dql: There is no brain to save.\n");
            return CR_OK;
        }
        // TODO: save the brain to the specified file.
    } else if (parameters[0] == "start") {
        if (parameters.size() != 1) {
            return CR_WRONG_USAGE;
        }
        if (!is_active) {
            is_active = true;
            out.print("dql: Activated the brain!\n");
        } else {
            out.print("dql: The brain is already active!\n");
        }
    } else if (parameters[0] == "status") {
        if (parameters.size() != 1) {
            return CR_WRONG_USAGE;
        }
        if (the_brain) {
            the_brain->print_to(out);
            if (is_active) {
                out.print("The brain is active.\n");
            } else {
                out.print("The brain is inactive.\n");
            }
        } else {
            out.print("There is no brain.\n");
        }
    } else {
        return CR_WRONG_USAGE;
    }

    return CR_OK;
}

// vim: et:ts=4:sw=4
