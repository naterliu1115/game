// 恢復到IDLE動畫
current_animation = UNIT_ANIMATION.IDLE;
image_index = animation_frames.IDLE[0];
image_speed = idle_animation_speed;
is_acting = false;

show_debug_message(object_get_name(object_index) + " 攻擊結束，回到IDLE" + 
                  ", 幀範圍: " + string(animation_frames.IDLE[0]) + "-" + string(animation_frames.IDLE[1]) + 
                  ", 當前幀: " + string(image_index) + 
                  ", 動畫速度: " + string(image_speed)); 