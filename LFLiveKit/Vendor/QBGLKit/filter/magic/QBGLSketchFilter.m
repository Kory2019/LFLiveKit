//
//  QBGLSketchFilter.m
//  Qubi
//
//  Created by Ken Sun on 2016/8/27.
//  Copyright © 2016年 Qubi. All rights reserved.
//

#import "QBGLSketchFilter.h"
#import "QBGLDrawable.h"
#import "QBGLUtils.h"
#import "QBGLProgram.h"

char * const kQBSketchFilterVertex;
char * const kQBSketchFilterFragment;

@implementation QBGLSketchFilter

- (instancetype)init {
    self = [self initWithVertexShader:kQBSketchFilterVertex fragmentShader:kQBSketchFilterFragment];
    if (self) {
        [self loadTextures];
    }
    return self;
}

- (void)loadTextures {
    [super loadTextures];
    [self.program setParameter:"strength" floatValue:1.0];
}

- (void)setAdditionalUniformVarsForRender {
    [super setAdditionalUniformVarsForRender];
    
    const GLfloat offset[] = {1 / self.inputSize.width, 1 / self.inputSize.height};
    glUniform2fv([self.program uniformWithName:"singleStepOffset"], 1, offset);
}

@end


#define STRING(x) #x

char * const kQBSketchFilterVertex = STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 varying vec2 textureCoordinate;
 
 attribute vec4 inputAnimationCoordinate;
 varying vec2 animationCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     animationCoordinate = inputAnimationCoordinate.xy;
 }
 );

char * const kQBSketchFilterFragment = STRING
(
 varying highp vec2 textureCoordinate;
 precision mediump float;
 
 uniform sampler2D inputImageTexture;
 uniform vec2 singleStepOffset;
 uniform float strength;
 
 varying highp vec2 animationCoordinate;
 uniform sampler2D animationTexture;
 uniform int enableAnimationView;
 
 const highp vec3 W = vec3(0.299,0.587,0.114);
 
 void main()
{
    float threshold = 0.0;
    //pic1
    vec4 oralColor = texture2D(inputImageTexture, textureCoordinate);
    
    //pic2
    vec3 maxValue = vec3(0.,0.,0.);
    
    for(int i = -2; i<=2; i++)
    {
        for(int j = -2; j<=2; j++)
        {
            vec4 tempColor = texture2D(inputImageTexture, textureCoordinate+singleStepOffset*vec2(i,j));
            maxValue.r = max(maxValue.r,tempColor.r);
            maxValue.g = max(maxValue.g,tempColor.g);
            maxValue.b = max(maxValue.b,tempColor.b);
            threshold += dot(tempColor.rgb, W);
        }
    }
    //pic3
    float gray1 = dot(oralColor.rgb, W);
    
    //pic4
    float gray2 = dot(maxValue, W);
    
    //pic5
    float contour = gray1 / gray2;
    
    threshold = threshold / 25.;
    float alpha = max(1.0,gray1>threshold?1.0:(gray1/threshold));
    
    float result = contour * alpha + (1.0-alpha)*gray1;
    
    vec4 animationColor = texture2D(animationTexture, animationCoordinate);
    if (enableAnimationView == 1) {
        vec3 textureColor = vec3(result,result,result);
        textureColor.r = animationColor.r + textureColor.r * (1.0 - animationColor.a);
        textureColor.g = animationColor.g + textureColor.g * (1.0 - animationColor.a);
        textureColor.b = animationColor.b + textureColor.b * (1.0 - animationColor.a);
        gl_FragColor = vec4(textureColor, oralColor.w);
    } else {
        gl_FragColor = vec4(vec3(result,result,result), oralColor.w);
    }
}
);

