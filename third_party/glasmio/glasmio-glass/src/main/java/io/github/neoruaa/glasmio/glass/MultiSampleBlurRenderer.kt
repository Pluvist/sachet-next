package io.github.neoruaa.glasmio.glass

import android.graphics.RenderEffect
import android.graphics.RuntimeShader

/** Three normalized nine-tap passes over the caller's reduced-resolution source. */
class MultiSampleBlurRenderer {
    private val programs by lazy { List(3) { RuntimeShader(MultiSampleBlurShader) } }
    private var previousRadius=Float.NaN
    private var previousWidth=Float.NaN
    private var previousHeight=Float.NaN
    private var previousClamp=true
    private var previousInput:RenderEffect?=null
    private var previousEffect:RenderEffect?=null

    fun effect(radius:Float,input:RenderEffect?=null,width:Float=0f,height:Float=0f,clampEdges:Boolean=true):RenderEffect? {
        if(!radius.isFinite()||radius<=.01f)return input
        if(radius==previousRadius&&width==previousWidth&&height==previousHeight&&
            clampEdges==previousClamp&&input===previousInput)return previousEffect
        var result=input
        // Each normalized tent pass has variance step²/2 along either axis.
        val step=radius*.8164966f
        for(program in programs) {
            program.setFloatUniform("sampleStep",step)
            program.setFloatUniform("sampleSize",width,height)
            program.setFloatUniform("clampEdges",if(clampEdges)1f else 0f)
            val pass=RenderEffect.createRuntimeShaderEffect(program,"content")
            result=result?.let{RenderEffect.createChainEffect(pass,it)}?:pass
        }
        previousRadius=radius;previousWidth=width;previousHeight=height
        previousClamp=clampEdges;previousInput=input;previousEffect=result
        return result
    }
}

private const val MultiSampleBlurShader="""
uniform shader content;
uniform float sampleStep;
uniform float2 sampleSize;
uniform float clampEdges;
half4 main(float2 p) {
    float4 result=float4(0.0);
    for(int y=-1;y<=1;y++) {
        for(int x=-1;x<=1;x++) {
            float2 q=p+float2(float(x),float(y))*sampleStep;
            if(clampEdges>.5 && sampleSize.x>0.0 && sampleSize.y>0.0)
                q=clamp(q,float2(.5),max(sampleSize-float2(.5),float2(.5)));
            float weight=(x==0?.5:.25)*(y==0?.5:.25);
            result+=float4(content.eval(q))*weight;
        }
    }
    return half4(result);
}
"""
