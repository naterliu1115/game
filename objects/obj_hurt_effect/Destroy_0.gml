// obj_hurt_effect - Destroy Event

// 清理粒子列表
if (ds_exists(particles, ds_type_list)) {
    ds_list_destroy(particles);
}