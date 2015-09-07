//
//  GameScene.m
//  Space Cannon
//
//  Created by Tin N Vo on 9/6/15.
//  Copyright (c) 2015 Tin Vo. All rights reserved.
//

#import "GameScene.h"
#import "Menu.h"
#import "Ball.h"
#import <AVFoundation/AVFoundation.h>

@implementation GameScene
{
    SKNode *mainLayer;
    SKSpriteNode *cannon;
    SKSpriteNode *ammoDisplay;
    SKSpriteNode *pause;
    SKSpriteNode *resume;
    SKLabelNode *scoreDisplay;
    SKLabelNode *pointLabel;
    SKAction *soundBounce;
    SKAction *soundDeepExplosion;
    SKAction *soundExplosion;
    SKAction *soundLazer;
    SKAction *soundZap;
    SKAction *soundShieldUp;
    NSUserDefaults *user;
    NSMutableArray *shieldPool;
    AVAudioPlayer *audioPlayer;
    Menu *menu;
    BOOL shot;
    BOOL gameOver;
    int killCount;
    
}

static const CGFloat SHOOT_SPEED = 1000.0f;
static const CGFloat HALO_LOW_ANGLE = 200.0 * M_PI / 180.0;
static const CGFloat HALO_HIGH_ANGLE = 340.0 * M_PI / 180.0;
static const CGFloat HALO_SPEED = 200.0;
static const uint32_t HALO_CATEGORY         = 0x1;
static const uint32_t BALL_CATEGORY         = 0x1 << 1;
static const uint32_t EDGE_CATEGORY         = 0x1 << 2;
static const uint32_t SHIELD_CATEGORY       = 0x1 << 3;
static const uint32_t BAR_CATEGORY          = 0x1 << 4;
static const uint32_t SHIELD_POWER_CATEGORY = 0x1 << 5;
static const uint32_t MULTI_SHOT_CATEGORY   = 0x1 << 6;
static NSString *const keyTopScore = @"TopScore";


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
    [self runAction: [SKAction repeatActionForever:haloAction] withKey:@"haloAction"];
    
    /* Create shield power up */
    SKAction *spawnShielsPower = [SKAction sequence:@[[SKAction waitForDuration:10 withRange:4],
                                                      [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
    [self runAction: [SKAction repeatActionForever:spawnShielsPower]];
    
    /* Ammos */
    ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    ammoDisplay.position = cannon.position;
    [self addChild:ammoDisplay];
    
    SKAction *ammoPlus = [SKAction sequence:@[[SKAction waitForDuration:1],
                                             [SKAction runBlock:^{
        if(!self.multiMode) {
            self.ammo++;
        }
    }]]];
    [self runAction:[SKAction repeatActionForever:ammoPlus]];
    
    
    /* Shield pool */
    shieldPool =[[NSMutableArray alloc] init];
    for (int i = 0; i < 10; i++) {
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shield.position = CGPointMake(self.size.width / 4 + 32 + (50 * i), 90);
        shield.name = @"shield";
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
        shield.physicsBody.collisionBitMask = 0;
        if (![shieldPool containsObject:shield]) {
            [shieldPool addObject:shield];
        }
    }
    
    
    /* Set up pause and resume buttons */
    pause = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
    pause.xScale = 2.0;
    pause.yScale = 2.0;
    pause.position = CGPointMake(720, 34);
    [self addChild:pause];
    
    resume = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
    resume.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:resume];
    
    /* Scoring */
    scoreDisplay = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    scoreDisplay.position = CGPointMake(self.size.width / 4 + 15, 10);
    scoreDisplay.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    scoreDisplay.fontSize = 20;
    [self addChild:scoreDisplay];
    
    /* Point multiplier label */
    pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    pointLabel.position = CGPointMake(self.size.width / 4 + 15, 37);
    pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    pointLabel.fontSize = 20;
    [self addChild:pointLabel];
    
    /* Initilize sounds */
    soundBounce = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    soundDeepExplosion = [SKAction playSoundFileNamed:@"BarExplosion.caf" waitForCompletion:NO];
    soundExplosion = [SKAction playSoundFileNamed:@"SmallExplosion.caf" waitForCompletion:NO];
    soundLazer = [SKAction playSoundFileNamed:@"LZSound.caf" waitForCompletion:NO];
    soundZap = [SKAction playSoundFileNamed:@"ZapSound.caf" waitForCompletion:NO];
    soundShieldUp = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
    
    /* Menu */
    menu = [[Menu alloc] init];
    [self addChild:menu];
    menu.position = CGPointMake(20, self.size.height - 200);
    
    /* Loading music */
    NSURL *url = [[NSBundle  mainBundle] URLForResource:@"ObservingTheStar" withExtension:@"caf"];
    NSError *error = nil;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (!audioPlayer) {
        NSLog(@"Error loading music: %@", error);
    } else {
        audioPlayer.numberOfLoops = -1;
        audioPlayer.volume = 0.8;
        [audioPlayer play];
        menu.musicPlaying = YES;
    }
    
    /* Init vals */
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    gameOver = YES;
    scoreDisplay.hidden = YES;
    pointLabel.hidden = YES;
    pause.hidden = YES;
    resume.hidden = YES;
    
    
    /* Loading score */
    user = [NSUserDefaults standardUserDefaults];
    menu.highScore = [user integerForKey:keyTopScore];
}


/* Game Over! */
-(void)gameOver {
    /* Make the halos explode and remove them */
    [mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    
    /* Remove the balls */
    [mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    /* Remove the shield */
    [mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        if (![shieldPool containsObject:node]) {
            [shieldPool addObject:node];
        }
        
        [node removeFromParent];
    }];
    
    /* Remove shield power up */
    [mainLayer enumerateChildNodesWithName:@"shieldPower" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    /* Remove multi-shot power up */
    [mainLayer enumerateChildNodesWithName:@"multiShot" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    

    
    menu.score = self.score;
    if (self.score > menu.highScore) {
        menu.highScore = self.score;
        /* Save new high score */
        [user setInteger:self.score forKey:keyTopScore];
        [user synchronize];
    }
    gameOver = YES;
    scoreDisplay.hidden = YES;
    pointLabel.hidden = YES;
    pause.hidden = YES;
    [self runAction:[SKAction waitForDuration:1.0] completion:^{
        [menu show];
    }];
}

/* New Game */
-(void) newGame {
    
    /* Set up game */
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    self.multiMode = NO;
    killCount = 0;
    gameOver = NO;
    scoreDisplay.hidden = NO;
    pointLabel.hidden = NO;
    pause.hidden = NO;
    [menu hide];
    [mainLayer removeAllChildren];
    [self actionForKey:@"haloAction"].speed = 1.0;

    
    /* "Unpack" the shieldpool */
    while (shieldPool.count > 0) {
        //if(!((SKSpriteNode *)[shieldPool objectAtIndex:0]).parent) {
           [mainLayer addChild:[shieldPool objectAtIndex:0]];
        //}
        [shieldPool removeObjectAtIndex:0];
    }
    
    /* Life Bar */
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.position = CGPointMake(self.size.width / 2, 70);
    lifeBar.xScale = 1.55;
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width/2, 0) toPoint:CGPointMake(lifeBar.size.width/2, 0)];
    lifeBar.physicsBody.categoryBitMask = BAR_CATEGORY;
    lifeBar.physicsBody.collisionBitMask = 0;
    [mainLayer addChild:lifeBar];
    
}

/* Shooting balls method */
-(void)shoot {
    Ball *ball = [Ball spriteNodeWithImageNamed:@"Ball"];
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
    ball.physicsBody.contactTestBitMask = EDGE_CATEGORY | SHIELD_POWER_CATEGORY | MULTI_SHOT_CATEGORY;
    [self runAction:soundLazer];
    [mainLayer addChild:ball];
    
    /* Ball trailing */
    NSString *trailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    SKEmitterNode *trailBall = [NSKeyedUnarchiver unarchiveObjectWithFile:trailPath];
    trailBall.targetNode = mainLayer;
    [mainLayer addChild:trailBall];
    ball.trail = trailBall;
    [ball updateTrail];
}


/* Creating the halos method */
-(void)createHalo {
    
    /* Incresing the spawning of halos */
    SKAction *spwnAction = [self actionForKey:@"haloAction"];
    if (spwnAction.speed < 1.5) {
        spwnAction.speed += 0.01;
    }
    
    /* Creating the halos */
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
    
    /* Count the number of haloes on the frame */
    int halosCounter = 0;
    for(SKNode *node in mainLayer.children) {
        if([node.name isEqualToString:@"halo"]) {
            halosCounter++;
        }
    }
    
    /* Bomb power up will spawned when there are 5 halos
     on the screen. else there will be a chance for the
     point multiplier power up to be spawned */
    /*if (halosCounter == 3) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setObject:@YES forKey:@"Bomb"];
        
    } else if (!gameOver && arc4random_uniform(5) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setObject:@YES forKey:@"Multiplier"];
    }*/
    
    if (!gameOver && arc4random_uniform(5) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setObject:@YES forKey:@"Multiplier"];
    }

}

/* Add shield power up */
-(void)spawnShieldPowerUp {
    if (shieldPool.count > 0) {
        SKSpriteNode *shieldPower = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shieldPower.position = CGPointMake(self.size.width + shieldPower.size.width, randomGen(150, self.size.height - 100));
        shieldPower.name = @"shieldPower";
        shieldPower.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shieldPower.physicsBody.categoryBitMask = SHIELD_POWER_CATEGORY;
        shieldPower.physicsBody.collisionBitMask = 0;
        shieldPower.physicsBody.velocity = CGVectorMake(-100, randomGen(-40, 40));
        shieldPower.physicsBody.angularVelocity = M_PI;
        shieldPower.physicsBody.linearDamping = 0.0;
        shieldPower.physicsBody.angularDamping = 0.0;
        [mainLayer addChild:shieldPower];
    }
}

/* Add multi shot power up */
-(void)spawnedMultiShotPowerUp {
    SKSpriteNode *multiShot = [SKSpriteNode spriteNodeWithImageNamed:@"MultiShotPowerUp"];
    multiShot.name = @"multiShot";
    multiShot.position = CGPointMake(-multiShot.size.width, randomGen(150, self.size.height - 100));
    multiShot.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:12.0];
    multiShot.physicsBody.categoryBitMask = MULTI_SHOT_CATEGORY;
    multiShot.physicsBody.collisionBitMask = 0.0;
    multiShot.physicsBody.velocity = CGVectorMake(100, randomGen(-40, 40));
    multiShot.physicsBody.angularVelocity = M_PI;
    multiShot.physicsBody.linearDamping = 0.0;
    multiShot.physicsBody.angularDamping = 0.0;
    [mainLayer addChild:multiShot];
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


/* Set the ammo displayed on the screen */
-(void)setAmmo:(int)ammo {
    if (ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        ammoDisplay.texture =[SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}

/* Set Score */
-(void)setScore:(int)score{
    _score = score;
    scoreDisplay.text = [NSString stringWithFormat:@"Score: %d", score];
}

/* Set point value */
-(void)setPointValue:(int)pointValue {
    _pointValue = pointValue;
    pointLabel.text = [NSString stringWithFormat:@"Points: x%d", pointValue];
}

/* Set multi mode */
-(void)setMultiMode:(BOOL)multiMode {
    _multiMode = multiMode;
    if (multiMode) {
        cannon.texture = [SKTexture textureWithImageNamed:@"GreenCannon"];
    } else {
        cannon.texture = [SKTexture textureWithImageNamed:@"Cannon"];
    }
}

/* Set game paused */
-(void)setGamePause:(BOOL)gamePause {
    if(!gameOver) {
        _gamePause = gamePause;
        pause.hidden = gamePause;
        resume.hidden = !gamePause;
        self.paused = gamePause;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    for (UITouch *touch in touches) {
        if (!gameOver && !self.gamePause) {
            if (![pause containsPoint:[touch locationInNode:pause.parent]]) {
                shot = YES;
            }
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (gameOver && menu.touchable) {
            SKNode *node = [menu nodeAtPoint:[touch locationInNode:menu]];
            if ([node.name isEqualToString:@"play"]) {
                /* Start a new game */
                [self newGame];
            }
            if ([node.name isEqualToString:@"Music"]) {
                menu.musicPlaying = !menu.musicPlaying;
                if(menu.musicPlaying) {
                    [audioPlayer play];
                } else {
                    [audioPlayer stop];
                }
            }
        } else if (!gameOver) {
            if(self.gamePause) {
                if ([resume containsPoint:[touch locationInNode:resume.parent]]) {
                    self.gamePause = NO;
                }
            } else {
                if ([pause containsPoint:[touch locationInNode:pause.parent]]) {
                    self.gamePause = YES;
                }
            }
        }
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
        self.score += self.pointValue;
        [self addExplosion:first.node.position withName:@"HaloExplosion"];
        [self runAction:soundExplosion];
        
        /* Increment the pointValue var when this is a HaloX */
        if ([[first.node.userData valueForKey:@"Multiplier"] boolValue]) {
            self.pointValue++;
        } else if ([[first.node.userData valueForKey:@"Bomb"] boolValue]) {
            /* Make the halos explode and remove them */
            //first.node.name = nil;
            [mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                first.node.name = nil;
                [self addExplosion:node.position withName:@"HaloExplosion"];
                [node removeFromParent];
            }];
        }
        
        /* Increment the killCount, when it hits 3
         we will create the multi show power up */
        killCount++;
        if (killCount % 3 == 0) {
            [self spawnedMultiShotPowerUp];
        }
        
        first.categoryBitMask = 0;
        [first.node removeFromParent];
        [second.node removeFromParent];
    }
    
    /* Colision between the halo and the shield */
    if (first.categoryBitMask == HALO_CATEGORY && second.categoryBitMask == SHIELD_CATEGORY) {
        [self addExplosion:first.node.position withName:@"ShieldExplosion"];
        [self runAction:soundExplosion];
        
        /* The shield got hit by the bomb halo, destroyed all of them */
        if ([[first.node.userData valueForKey:@"Bomb"] boolValue]) {
            [mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
                //[self addExplosion:first.node.position withName:@"ShieldExplosion"];
                //i//f (![shieldPool containsObject:second.node]) {
                
                //}
                [node removeFromParent];
                [shieldPool addObject:second.node];
            }];
        }
        
        first.categoryBitMask = 0;
        [first.node removeFromParent];
        if (![shieldPool containsObject:second.node]) {
            [shieldPool addObject:second.node];
        }
        [second.node removeFromParent];
    }
    
    /* Colision between the halo and the lifebar */
    if (first.categoryBitMask == HALO_CATEGORY && second.categoryBitMask == BAR_CATEGORY) {
        [self addExplosion:second.node.position withName:@"LifeBarExplosion"];
        [self runAction:soundDeepExplosion];
        [second.node removeFromParent];
        [self gameOver];
    }
    
    /* Colision between the ball and the edges */
    if (first.categoryBitMask == BALL_CATEGORY && second.categoryBitMask == EDGE_CATEGORY) {
        [self addExplosion:contact.contactPoint withName:@"BounceExplosion"];
        
        /* Check to make sure that is of class Ball
        if bounces more than 4, remove it from frame */
        if ([first.node isKindOfClass:[Ball  class]]) {
            ((Ball *)first.node).numBounces++;
            if (((Ball *)first.node).numBounces > 4) {
                [first.node removeFromParent];
                self.pointValue = 1;
            }
        }
        [self runAction:soundBounce];
    }
    
    /* Colision between the ball and the shield power up */
    if (first.categoryBitMask == BALL_CATEGORY && second.categoryBitMask == SHIELD_POWER_CATEGORY) {
        if(shieldPool.count > 0) {
            int randIndex = arc4random_uniform((int)shieldPool.count);
            [mainLayer addChild:[shieldPool objectAtIndex:randIndex]];
            [shieldPool removeObjectAtIndex:randIndex];
            [self runAction:soundShieldUp];
        }
        [first.node removeFromParent];
        [second.node removeFromParent];
    }
    
    /* Colision between the ball and the multi shot power up */
    if (first.categoryBitMask == BALL_CATEGORY && second.categoryBitMask == MULTI_SHOT_CATEGORY) {
        self.multiMode = YES;
        [self runAction:soundShieldUp];
        self.ammo = 5;
        [first.node removeFromParent];
        [second.node removeFromParent];
    }
}

/* Clean up the balls that go out off the screen */
-(void)didSimulatePhysics {
    if (shot) {
        if (self.ammo > 0) {
            self.ammo--;
            [self shoot];
            if (self.multiMode) {
                for (int i = 1; i < 5; i++) {
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1*i];
                }
                
                if (self.ammo == 0) {
                    self.multiMode = NO;
                    self.ammo = 5;
                }
            }
        }
        shot = NO;
    }
    
    /* Remove the balls */
    [mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        /* Go thru and update trail */
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0.0];
        }

        /* Remove if needed (out of frame) */
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
            self.pointValue = 1;
        }
    }];
    
    /* Remove shield power up */
    [mainLayer enumerateChildNodesWithName:@"shieldPower" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + node.frame.size.width < 0) {
            [node removeFromParent];
        }
    }];
    
    /* Remove multi-shot power up */
    [mainLayer enumerateChildNodesWithName:@"multiShot" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x - node.frame.size.width > self.size.width) {
            [node removeFromParent];
        }
    }];
    
    /* Remove the halos */
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
