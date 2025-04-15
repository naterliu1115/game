/// @description 清理粒子系統與粒子型態

if (part_system_exists(particle_system)) {
    part_system_destroy(particle_system);
}
if (part_type_exists(particle_trail)) {
    part_type_destroy(particle_trail);
}
if (part_type_exists(particle_land)) {
    part_type_destroy(particle_land);
}
if (part_type_exists(particle_absorb)) {
    part_type_destroy(particle_absorb);
}