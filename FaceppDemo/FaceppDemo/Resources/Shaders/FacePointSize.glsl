attribute vec4 vPosition;

uniform float sizeScale;

void main(void)
{
    gl_Position = vPosition;
    gl_PointSize = 5.0 * sizeScale;
}