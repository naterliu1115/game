/// @description 初始化戰鬥管理器的資料結構與變數
/// @author AI
function battle_init() {
    show_debug_message("[battle_init] 戰鬥初始化腳本已執行");
    // --- 核心狀態 ---
    battle_state = BATTLE_STATE.INACTIVE;
    ending_substate = ENDING_SUBSTATE.SHRINKING;
    battle_timer = 0;
    battle_result_handled = false;
    processing_last_enemy_drops = false;

    // --- 列表 ---
    player_units = ds_list_create();
    enemy_units = ds_list_create();
    last_enemy_flying_items = ds_list_create();
    battle_log = ds_list_create();
    defeated_enemies_exp = ds_list_create();
    defeated_enemy_ids_this_battle = [];
    current_battle_drops = [];
    pending_flying_items = [];

    // --- 戰鬥區域 ---
    battle_area = {
        center_x: 0,
        center_y: 0,
        boundary_radius: 0
    };
    battle_center_x = battle_area.center_x;
    battle_center_y = battle_area.center_y;
    battle_boundary_radius = battle_area.boundary_radius;

    // --- UI 相關 ---
    ui_data = {
        info_text: "",
        info_alpha: 1.0,
        info_timer: 0,
        surface_needs_update: true
    };
    info_alpha = ui_data.info_alpha;
    info_text = ui_data.info_text;
    info_timer = ui_data.info_timer;
    surface_needs_update = ui_data.surface_needs_update;

    // --- 單位系統相關 ---
    units_data = {
        global_summon_cooldown: 0,
        atb_rate: 0
    };
    global_summon_cooldown = units_data.global_summon_cooldown;
    atb_rate = units_data.atb_rate;

    // --- 經驗與升級 ---
    exp_system = {
        experience: 0,
        experience_to_level_up: 100
    };
    experience = exp_system.experience;
    experience_to_level_up = exp_system.experience_to_level_up;

    // --- 獎勵相關 ---
    rewards = {
        exp: 0,
        gold: 0,
        items_list: [],
        visible: false
    };
    reward_exp = rewards.exp;
    reward_gold = rewards.gold;
    reward_items_list = rewards.items_list;
    reward_visible = rewards.visible;

    // --- 戰鬥結束相關 ---
    battle_result = ""; // "VICTORY", "DEFEAT", "ESCAPE"
    battle_timer_end = 0;
    final_battle_duration_seconds = 0;
    enemies_defeated_this_battle = 0;

    // --- 邊界動畫 ---
    border_target_scale = 0;
    border_current_scale = 0;
    border_anim_speed = 0.05;
} 