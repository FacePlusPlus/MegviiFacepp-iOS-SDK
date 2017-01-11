uniform mat4 projection;
uniform mat4 modelView;
attribute vec4 vPosition;

void main(void)
{
    gl_Position =  vPosition;
}