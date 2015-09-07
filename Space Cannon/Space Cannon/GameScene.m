//
//  GameScene.m
//  Space Cannon
//
//  Created by Tin N Vo on 9/6/15.
//  Copyright (c) 2015 Tin Vo. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene
{
    SKNode *mainLayer;
    SKSpriteNode *cannon;
}

-(void)didMoveToView:(SKView *)view {
    /* Add the background node */
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointMake(self.size.width/2, self.size.height/2);
    background.xScale = 1.63;
    background.yScale = 1.5;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    /* Add the main layer */
    mainLayer = [[SKNode alloc] init];
    [self addChild:mainLayer];
    
    /* Add the cannon */
    cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    cannon.position = CGPointMake(self.size.width / 2, 0.0);
    [self addChild:cannon];
    
    /* Create rotation for the cannon */
    SKAction *rotate = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],
                                            [SKAction rotateByAngle:-M_PI duration:2]]];
    [cannon runAction:[SKAction repeatActionForever:rotate]];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
