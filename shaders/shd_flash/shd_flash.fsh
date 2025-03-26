//
// 閃爍著色器效果的片段著色器
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// 閃爍顏色
uniform vec3 u_flash_color;
// 閃爍強度 (0-1)
uniform float u_flash_alpha;

void main()
{
    // 取樣原始紋理
    vec4 original_color = texture2D(gm_BaseTexture, v_vTexcoord);
    
    // 混合閃爍顏色
    vec3 final_color = mix(original_color.rgb, u_flash_color, u_flash_alpha);
    
    // 輸出混合後的顏色，保持原始Alpha通道
    gl_FragColor = vec4(final_color, original_color.a);
} 