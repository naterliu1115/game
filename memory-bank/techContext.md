# Memory Bank: techContext.md

This file outlines the specific technologies, development setup, constraints, and dependencies for the TurnBasedBattle project.

## Core Technologies

*   **Game Engine:** GameMaker Studio (Version inferred from runtime: 2024.13.0.238)
*   **Programming Language:** GameMaker Language (GML)
*   **Data Format:** CSV for initial data loading (items, enemies, levels, skills).

## Development Setup

*   **IDE:** GameMaker Studio IDE, potentially with external editors.
*   **Version Control:** (Not specified, assume Git unless stated otherwise)
*   **Platform:** Windows (Target inferred from build logs)

## Technical Constraints & Considerations

*   **Initialization Order:** Issues are common and require careful management (e.g., using event systems or alarms for delayed execution).
*   **Global Variables:** Reliance on global variables (`global.enemy_templates`, `global.player_monsters`) requires careful synchronization and is a target for refactoring (especially `global.player_monsters`).
*   **Type Safety:** GML lacks native type checking; rely on clear comments and defensive programming.
*   **`with` Scoping:** Variables must be declared before use within `with` blocks.
*   **Layer Management:** Object layer management (Instances, GUI, etc.) needs care to avoid coordinate misuse and visual/logic errors.
*   **Debugging:** Prioritize `show_debug_message` or GameMaker's debugger for step-by-step verification of complex logic (physics, animation, state machines).

## Dependencies

*   **Core Scripts/Objects:**
    *   `load_csv()` script (assumed custom or built-in extension).
    *   `obj_event_manager` for event handling.
    *   `obj_item_manager` manages item data, inventory, and hotbar.
*   **Data Sources:** CSV files for items, enemies, levels, skills.

## GameMaker/GML Specifics (From game-rule.mdc)

*   Refer to official GML specifications and documentation via web search when necessary.
*   **Avoid `speed` Variable:** Do not use the built-in `speed` variable. Prioritize `hspeed`, `vspeed`, or custom speed variables.
*   **`string_format()` Usage:** Ensure argument count and types match the format string. Passing instance IDs or Enum values directly is generally safe.

## Project Standards

*   **Development Communication/Comments:** Always use Traditional Chinese.
*   **Standard Font:** Primarily use `fnt_dialogue` for UI elements.
*   **World Layer Focus:** New features should primarily operate on the world layer, avoiding mixing GUI/world coordinates unless necessary.
*   **Future Optimizations:** Consider unifying drop factories.

// The Chinese sections below this line are duplicates and should be removed. 