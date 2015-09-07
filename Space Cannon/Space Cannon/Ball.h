//
//  Ball.h
//  Space Cannon
//
//  Created by Tin N Vo on 9/7/15.
//  Copyright (c) 2015 Tin Vo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Ball : SKSpriteNode
@property (nonatomic) SKEmitterNode *trail;
@property (nonatomic) int numBounces;
-(void)updateTrail;
@end
