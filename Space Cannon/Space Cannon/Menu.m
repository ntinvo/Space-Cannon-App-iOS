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
    SKSpriteNode *title;
    SKSpriteNode *play;
    SKSpriteNode *scoreBoard;
    SKSpriteNode *musicBtn;
}
-(id) init {
    self = [super init];
    if (self) {
        title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.xScale = 1.75;
        title.yScale = 1.75;
        title.position = CGPointMake(500, 70);
        [self addChild:title];
        
        play = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        play.name = @"play";
        play.position = CGPointMake(500, -170);
        play.xScale = 1.75;
        play.yScale = 1.75;
        [self addChild:play];
        
        scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
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
        
        musicBtn = [SKSpriteNode spriteNodeWithImageNamed:@"MusicOnButton"];
        musicBtn.name = @"Music";
        musicBtn.xScale = 2.0;
        musicBtn.yScale = 2.0;
        musicBtn.position = CGPointMake(500, -250);
        [self addChild:musicBtn];
        
        self.score = 0;
        self.highScore = 0;
        self.touchable = YES;
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

-(void)hide {
    self.touchable = NO;
    
    SKAction *animateMenu = [SKAction scaleTo:0.0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1.0;
        self.yScale = 1.0;
    }];
}

-(void)show {
    self.hidden = NO;
    self.touchable = NO;
    
    /* Animate Title */
    title.position = CGPointMake(500, 160);
    title.alpha = 0;
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:70 duration:0.5],
                                               [SKAction fadeInWithDuration:0.5]]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [title runAction:animateTitle];
    
    
    /* Animate Scoreboard */
    scoreBoard.xScale = 4;
    scoreBoard.yScale = 4;
    scoreBoard.alpha = 0;
    SKAction *animatScoreBoard = [SKAction group:@[[SKAction scaleTo:1.75 duration:0.5],
                                                   [SKAction fadeInWithDuration:0.5]]];
    animatScoreBoard.timingMode = SKActionTimingEaseOut;
    [scoreBoard runAction:animatScoreBoard];
    
    /* Animate play button */
    play.alpha = 0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:2.0];
    animatePlayButton.timingMode = SKActionTimingEaseIn;
    [play runAction:animatePlayButton completion:^{
        self.touchable = YES;
    }];
    
    /* Music */
    musicBtn.alpha = 0.0;
    [musicBtn runAction:animatePlayButton];
}

-(void)setMusicPlaying:(BOOL)musicPlaying
{
    _musicPlaying = musicPlaying;
    if(musicPlaying) {
        musicBtn.texture = [SKTexture textureWithImageNamed:@"MusicOnButton"];
    } else {
        musicBtn.texture = [SKTexture textureWithImageNamed:@"MusicOffButton"];
    }
}

@end














