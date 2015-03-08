#include "Core.h"
#include <Console.h>
#include <Export.h>
#include <PluginManager.h>

#include "DataDefs.h"
//#include "df/world.h"
#include "df/interface_key.h"

#include "brain.h"
#include "trainer.h"
#include "input.h"
#include "fc.h"
#include "relu.h"
#include "regression.h"

using namespace DFHack;

DFHACK_PLUGIN("dql");

const size_t dql_num_states = ((1<<8 /* ch */) + (1<<4 /* fg */) + (1<<3 /* bg */)) * 80 * 25;
const size_t dql_num_actions = df::enum_traits<df::interface_key>::last_item_value - df::enum_traits<df::interface_key>::first_item_value + 1;
const size_t dql_temporal_window = 1;

typedef bool dql_input[dql_num_states*dql_temporal_window + dql_num_actions*dql_temporal_window + dql_num_states];
template<typename parent_t>
using dql_fc = ReLU<FullyConn<parent_t, dql_input, 50>, dql_input>;
using dql_network = Regression<dql_fc<dql_fc<Input<dql_input, dql_num_states, dql_num_actions, dql_temporal_window> > >, dql_input, dql_num_actions>;
using dql_trainer = Trainer<dql_input, dql_network>;
using dql_brain = Brain<dql_network, dql_trainer, df::interface_key, dql_num_states, dql_num_actions, dql_temporal_window>;

// Any globals a plugin requires (e.g. world) should be listed here.
// For example, this line expands to "using df::global::world" and prevents the
// plugin from being loaded if df::global::world is null (i.e. missing from symbols.xml):
//
//REQUIRE_GLOBAL(world);

command_result dql(color_ostream &out, std::vector<std::string>& parameters);

// Mandatory init function. If you have some global state, create it here.
DFhackCExport command_result plugin_init(color_ostream& out, std::vector<PluginCommand>& commands) {
    // Fill the command list with your commands.
    commands.push_back(PluginCommand(
        "dql", "Do nothing, look pretty.",
        dql, false, /* true means that the command can't be used from non-interactive user interface */
        // Extended help string. Used by CR_WRONG_USAGE and the help command:
        "  This command does nothing at all.\n"
        "Example:\n"
        "  dql\n"
        "    Does nothing.\n"
    ));
    return CR_OK;
}

// This is called right before the plugin library is removed from memory.
DFhackCExport command_result plugin_shutdown(color_ostream& out) {
    // You *MUST* kill all threads you created before this returns.
    // If everything fails, just return CR_FAILURE. Your plugin will be
    // in a zombie state, but things won't crash.
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

// Whatever you put here will be done in each game step. Don't abuse it.
// It's optional, so you can just comment it out like this if you don't need it.
/*
DFhackCExport command_result plugin_onupdate ( color_ostream &out )
{
    // whetever. You don't need to suspend DF execution here.
    return CR_OK;
}
*/

// A command! It sits around and looks pretty. And it's nice and friendly.
command_result dql(color_ostream& out, std::vector<std::string>& parameters) {
    // It's nice to print a help message you get invalid options
    // from the user instead of just acting strange.
    // This can be achieved by adding the extended help string to the
    // PluginCommand registration as show above, and then returning
    // CR_WRONG_USAGE from the function. The same string will also
    // be used by 'help your-command'.
    if (!parameters.empty())
        return CR_WRONG_USAGE;
    // Commands are called from threads other than the DF one.
    // Suspend this thread until DF has time for us. If you
    // use CoreSuspender, it'll automatically resume DF when
    // execution leaves the current scope.
    CoreSuspender suspend;
    // Actually do something here. Yay.
    out.print("Hello! I do nothing, remember?\n");
    out.print("%d\n", dql_num_states);
    out.print("%d\n", dql_num_actions);
    out.print("%d\n", sizeof(dql_brain));
    // Give control back to DF.
    return CR_OK;
}

// vim: et:ts=4:sw=4
