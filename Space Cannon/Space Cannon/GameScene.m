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
static const CGFloat HALO_LOW_ANGLE = 200.0 * M_PI / 180.0;
static const CGFloat HALO_HIGH_ANGLE = 340.0 * M_PI / 180.0;
static const CGFloat HALO_SPEED = 250.0;
static const uint32_t HALO_CATEGORY     = 0x1;
static const uint32_t BALL_CATEGORY     = 0x1 << 1;
static const uint32_t EDGE_CATEGORY     = 0x1 << 2;
static const uint32_t SHIELD_CATEGORY   = 0x1 << 3;
static const uint32_t BAR_CATEGORY      = 0x1 << 4;

/* Helper method to convert radian to vector */
static inline CGVector radiansToVector(CGFloat radians){
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}


/* Helper method to generate rand # from low to high */
static inline CGFloat randomGen(CGFloat low, CGFloat high) {
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}

-(void)didMoveToView:(SKView *)view {
    /* Turn of gravity in the game (We're in space anyway) */
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    
    /* Which object should receive the collison notification */
    self.physicsWorld.contactDelegate = self;
    
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
    leftEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    leftEdge.physicsBody.dynamic = YES;
    [self addChild:leftEdge];
    
    SKNode *rightEdge = [[SKNode alloc] init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(self.size.width/1.335, 0.0) toPoint:CGPointMake(self.size.width/1.335, self.size.height + 100)];
    rightEdge.position = CGPointMake(0.0, 0.0);
    rightEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:rightEdge];
    
    
    /* Create halo action */
    SKAction *haloAction = [SKAction sequence:@[[SKAction waitForDuration: 2 withRange: 1],  /* This will wait an amount of time for the next halo to be spawned */
                                                [SKAction performSelector:@selector(createHalo) onTarget:self]]]; /* Call createAction function to spawn the halos */
    [self runAction: [SKAction repeatActionForever:haloAction]];
    
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
    ball.physicsBody.categoryBitMask = BALL_CATEGORY; /* Set the category bit mask */
    ball.physicsBody.collisionBitMask = EDGE_CATEGORY; /* If the ball collides with another
    // body that has a category bit mask that has the edge category set, then react to that */
    ball.physicsBody.contactTestBitMask = EDGE_CATEGORY;
    [mainLayer addChild:ball];
}


/* Creating the halos method */
-(void)createHalo {
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.position = CGPointMake(randomGen(halo.size.width/2, self.size.width - halo.size.width/2),
                                self.size.height + halo.size.height/2);
    halo.name = @"halo";
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: 16];
    CGVector direction = radiansToVector(randomGen(HALO_LOW_ANGLE, HALO_HIGH_ANGLE));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
    halo.physicsBody.restitution = 1.0; /* Maintain momentum so that it will bounce off the edges */
    halo.physicsBody.linearDamping = 0.0; /* Turn off air friction */
    halo.physicsBody.friction = 0.0; /* Turn off friction */
    halo.physicsBody.categoryBitMask = HALO_CATEGORY; /* Set the category bit mask */
    halo.physicsBody.collisionBitMask = EDGE_CATEGORY;
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY | SHIELD_CATEGORY | BAR_CATEGORY | EDGE_CATEGORY;
    [mainLayer addChild:halo];
}

/* Add the explosion */
-(void)addExplosion:(CGPoint)position withName:(NSString *)name{
    /* Add SKEmitterNode manually */
    /* SKEmitterNode *explosion = [SKEmitterNode node];
     explosion.particleTexture = [SKTexture textureWithImageNamed:@"spark"];
     explosion.particleLifetime = 1;
     explosion.particleBirthRate = 2000;
     explosion.numParticlesToEmit = 100;
     explosion.emissionAngleRange = 360;
     explosion.particleScale = 0.2;
     explosion.particleScaleSpeed = -0.2;
     explosion.particleSpeed = 200; */
    
    
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    explosion.position = position;
    [mainLayer addChild:explosion];
    SKAction *remove = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                            [SKAction removeFromParent]]];
    [explosion runAction:remove];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        shot = YES;
    }
}

-(void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *first;
    SKPhysicsBody *second;
    if(contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        first = contact.bodyA;
        second = contact.bodyB;
    } else {
        first = contact.bodyB;
        second = contact.bodyA;
    }
    
    /* Colision between the halo and the ball */
    if (first.categoryBitMask == HALO_CATEGORY && second.categoryBitMask == BALL_CATEGORY) {
        //self.score += 10;
        [self addExplosion:first.node.position withName:@"HaloExplosion"];
        //[self runAction:soundExplosion];
        
        //first.categoryBitMask = 0;
        [first.node removeFromParent];
        [second.node removeFromParent];
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
    
    [mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
