//
//  Ball.m
//  Space Cannon
//
//  Created by Tin N Vo on 9/7/15.
//  Copyright (c) 2015 Tin Vo. All rights reserved.
//

#import "Ball.h"

@implementation Ball

-(void)updateTrail {
    if (self.trail) {
        self.trail.position = self.position;
    }
}

-(void)removeFromParent {
    if (self.trail) {
        self.trail.particleBirthRate = 0;
        SKAction *remove = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime + self.trail.particleLifetimeRange],
                                                [SKAction removeFromParent]]];
        [self runAction:remove];
    }
    [super removeFromParent];
}

@end
