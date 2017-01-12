precision mediump float;

uniform highp float color_selector;

void main()
{
    if (color_selector  == 1.0) {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    } else if (color_selector  == 2.0) {
        gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
    } else if (color_selector == 3.0) {
        gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0);
    } else
        gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}