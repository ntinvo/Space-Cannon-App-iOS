//
//  Menu.m
//  Space Cannon
//
//  Created by Tin N Vo on 9/7/15.
//  Copyright (c) 2015 Tin Vo. All rights reserved.
//

#import "Menu.h"

@implementation Menu
{
    SKLabelNode *scoreLabel;
    SKLabelNode *topScore;
}
-(id) init {
    self = [super init];
    if (self) {
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.xScale = 1.75;
        title.yScale = 1.75;
        title.position = CGPointMake(500, 70);
        [self addChild:title];
        
        SKSpriteNode *play = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        play.name = @"play";
        play.position = CGPointMake(500, -170);
        play.xScale = 1.75;
        play.yScale = 1.75;
        [self addChild:play];
        
        SKSpriteNode *scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.xScale = 1.75;
        scoreBoard.yScale = 1.75;
        scoreBoard.position = CGPointMake(500, -50);
        [self addChild:scoreBoard];
        
        scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Din Alternate"];
        scoreLabel.fontSize = 50;
        scoreLabel.position = CGPointMake(408, -85);
        [self addChild:scoreLabel];
        
        topScore = [SKLabelNode labelNodeWithFontNamed:@"Din Alternate"];
        topScore.fontSize = 50;
        topScore.position = CGPointMake(586, -85);
        [self addChild:topScore];
        
        self.score = 0;
        self.highScore = 0;
    }
    return self;
}

-(void)setScore:(int)score {
    _score = score;
    scoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
}

-(void)setHighScore:(int)highScore{
    _highScore = highScore;
    topScore.text = [[NSNumber numberWithInt:highScore] stringValue];
}

@end
