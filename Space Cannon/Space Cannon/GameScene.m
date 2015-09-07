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
    BOOL shot;
}

static const CGFloat SHOOT_SPEED = 1000.0f;

/* Helper method to convert radian to vector */
static inline CGVector radiansToVector(CGFloat radians){
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

-(void)didMoveToView:(SKView *)view {
    /* Turn of gravity in the game (We're in space anyway) */
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    
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
    
    /* Add the edges for the world */
    SKNode *leftEdge = [[SKNode alloc] init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(self.size.width/4, 0.0) toPoint:CGPointMake(self.size.width/4, self.size.height + 100)];
    leftEdge.position = CGPointMake(0.0, 0.0);
    //leftEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:leftEdge];
    
    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(self.size.width/1.335, 0.0) toPoint:CGPointMake(self.size.width/1.335, self.size.height + 100)];
    rightEdge.position = CGPointMake(0.0, 0.0);
    //rightEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:rightEdge];
    
}

/* Shooting balls method */
-(void)shoot {
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"Ball"];
    ball.name = @"ball";
    CGVector rotationVector = radiansToVector(cannon.zRotation);
    ball.position = CGPointMake(cannon.position.x + cannon.size.width * 0.5 * rotationVector.dx,
                                cannon.position.y + cannon.size.width * 0.5 * rotationVector.dy);
    
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    ball.physicsBody.restitution = 1.0; /* Maintain momentum so that it will bounce off the edges */
    ball.physicsBody.linearDamping = 0.0; /* Turn off air friction */
    ball.physicsBody.friction = 0.0; /* Turn off friction */
    [mainLayer addChild:ball];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        shot = YES;
    }
}

/* Clean up the balls that go out off the screen */
-(void)didSimulatePhysics {
    if (shot) {
        [self shoot];
        shot = NO;
    }
    
    [mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
