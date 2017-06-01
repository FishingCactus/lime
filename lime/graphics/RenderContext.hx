package lime.graphics;


import lime.graphics.GLRenderContext;


enum RenderContext {

	OPENGL (gl:GLRenderContext);
	CUSTOM (data:Dynamic);
	NONE;

}