#include "Core.h"
#include <Console.h>
#include <Export.h>
#include <PluginManager.h>

#include "DataDefs.h"
#include "modules/Screen.h"
#include "modules/Gui.h"
#include "df/interface_key.h"

#include <algorithm>

#include "brain.h"
#include "trainer.h"
#include "input.h"
#include "fc.h"
#include "relu.h"
#include "regression.h"

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

// Called to notify the plugin about important state changes.
// Invoked with DF suspended, and always before the matching plugin_onupdate.
// More event codes may be added in the future.
/*
DFhackCExport command_result plugin_onstatechange(color_ostream &out, state_change_event event)
{
    switch (event) {
    case SC_GAME_LOADED:
        // initialize from the world just loaded
        break;
    case SC_GAME_UNLOADED:
        // cleanup
        break;
    default:
        break;
    }
    return CR_OK;
}
*/

static typename dql_brain::input_t the_input;

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

    // clear out the input array.
    std::fill(&the_input[0], &the_input[dql_num_states], false);

    bool *pi = &the_input[0];
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
    df::interface_key action = the_brain->forward(the_input);

    // do what it says.
    static interface_key_set keys;
    keys.clear();
    keys.insert(action);
    Gui::getCurViewscreen()->feed(&keys);

    // make sure we're redrawing the screen immediately.
    invalidate();

    // figure out how well we did.
    float reward = 0.0;
    // TODO

    // tell the brain.
    the_brain->backward(reward);

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
