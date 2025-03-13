// obj_recall_effect 的 Step 事件
// 更新效果
scale -= shrink_speed;
image_alpha -= fade_speed;

// 當效果結束時銷毀
if (image_alpha <= 0 || scale <= 0) {
    instance_destroy();
}