/// @function start_dialogue(npc)
/// @param npc NPC 对象实例
/// @description 开始与指定NPC的对话
function start_dialogue(npc) {
    if (!instance_exists(npc) || !instance_exists(obj_dialogue_manager)) return false;
    
    with (obj_dialogue_manager) {
        active = true;
        current_npc = npc;
        dialogue = npc.dialogue;
        dialogue_index = 0;
        dialogue_box_needs_update = true;
        return true;
    }
    return false;
}

/// @function end_dialogue()
/// @description 结束当前对话
function end_dialogue() {
    if (!instance_exists(obj_dialogue_manager)) return false;
    
    with (obj_dialogue_manager) {
        active = false;
        current_npc = noone;
        dialogue_box_needs_update = true;
        return true;
    }
    return false;
}

/// @function advance_dialogue()
/// @description 推进对话到下一条
/// @returns {bool} true如果对话继续，false如果对话结束
function advance_dialogue() {
    if (!instance_exists(obj_dialogue_manager) || !obj_dialogue_manager.active) return false;
    
    with (obj_dialogue_manager) {
        dialogue_index += 1;
        dialogue_box_needs_update = true;
        
        // 检查对话是否结束
        if (dialogue_index >= array_length(dialogue)) {
            end_dialogue();
            return false;
        }
        return true;
    }
    return false;
}

/// @function is_dialogue_active()
/// @description 检查对话是否处于活动状态
/// @returns {bool} 对话是否活动
function is_dialogue_active() {
    return (instance_exists(obj_dialogue_manager) && obj_dialogue_manager.active);
}

/// @function get_current_dialogue_text()
/// @description 获取当前显示的对话文本
/// @returns {string} 当前对话文本或空字符串
function get_current_dialogue_text() {
    if (!instance_exists(obj_dialogue_manager) || !obj_dialogue_manager.active) return "";
    
    with (obj_dialogue_manager) {
        if (dialogue_index < array_length(dialogue)) {
            return dialogue[dialogue_index];
        }
    }
    return "";
}
