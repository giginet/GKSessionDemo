//
//  MSMainServerLayer.m
//  MultipleSession
//
//  Created by giginet on 2013/1/23.
//
//

#import "MSMainServerLayer.h"
#import "KWSessionManager.h"
#import "MSGoalLayer.h"
#import "KKInputTouch.h"
#import "SimpleAudioEngine.h"

@interface MSMainServerLayer()
- (void)broadCastAllPlayers;
@end

@implementation MSMainServerLayer

- (id)initWithServerPeer:(NSString *)peer andClients:(CCArray *)peers {
  self = [super initWithServerPeer:peer andClients:peers];
  if (self) {
    _cameraNode.scale = 0.8f; // iPad版はサイズを0.8倍にして扱う
    _random = [KWRandom random];
  }
  return self;
}

- (void)update:(ccTime)dt {
  [super update:dt];
  CCDirector* director = [CCDirector sharedDirector];
  
  switch (_state) {
    case MSGameStateMain:
    {
    // スクロールする
    float scrollSpeed = [KKConfig floatForKey:@"ScrollSpeed"];
    float railWidth = [KKConfig floatForKey:@"RailWidth"];
    float goalPoint = _map.height * railWidth;
    if (_scroll < goalPoint - 1024 * 1.25f) {
      _scroll += scrollSpeed;
    }
    
    // ランダムに雲を追加
    int r = [_random nextInt] % 300;
    if (r == 0) {
      CCSprite* clowd = [CCSprite spriteWithFile:@"clowd0.png"];
      clowd.position = ccp(-40, _scroll + 100);
      int w = director.screenSize.width;
      [_stage addChild:clowd];
      [clowd runAction:[CCSequence actions:
                        [CCMoveTo actionWithDuration:10.0f position:ccp(w + 40, _scroll + 600)],
                        [CCRemoveFromParentAction action],
                        nil]];
    }
    
    // 現在のスクロール座標をPlayerにbroadcastする
    for (MSPlayer* player in _players) {
      NSNumber* scroll = [NSNumber numberWithFloat:_scroll];
      MSContainer* container = [MSContainer containerWithObject:scroll forTag:MSContainerTagScroll];
      [self sendContainer:container peerID:player.peerID];
    }
    
    BOOL isAllGoal = YES;
    BOOL isAllDead = YES;
    for (MSPlayer* player in _players) {
      // コイン取りました判定
      MSTile* currentTile = [_map tileWithStagePoint:player.position];
      if (currentTile.tileType == MSTileTypeCoin) { // コイン取った！
        [currentTile setTileType:MSTileTypeRail]; // コイン消す
        player.coinCount += 1; // コイン追加します
        MSContainer* container = [MSContainer containerWithObject:[player state] forTag:MSContainerTagGetCoin]; // 取った人のプレイヤーステートを送ります
        [self broadcastContainerToPlayer:container];
        [self updateCoinLabel];
      } else if (currentTile.tileType == MSTileTypeRock || currentTile.tileType == MSTileTypeNone) { // クラッシュ判定
        if (!player.isDead && player.canMoving) {
          player.life -= 1;
          [player setCrashAnimation];
          if (currentTile.tileType == MSTileTypeRock) {
            // 岩の破壊 @ToDo
          }
          MSContainer* container = [MSContainer containerWithObject:nil forTag:MSContainerTagDamage]; // ダメージ受けました通知
          [self sendContainer:container peerID:player.peerID]; // ダメージ受けたキャラに送信
        }
      }
      // ゴール判定
      if (player.position.y - _scroll > director.screenSize.height) { // ゴールになったとき、ゴールタグが付いたモノを送ります
        MSContainer* container = [MSContainer containerWithObject:nil forTag:MSContainerTagPlayerGoal];
        [self sendContainer:container peerID:player.peerID];
        player.isGoal = YES;
      }
      if (!player.isGoal) {
        isAllGoal = NO;
      }
      if (!player.isDead) {
        isAllDead = NO;
      }
    }
    
    // タッチによる岩の破壊
    [KKInput sharedInput].gestureTapEnabled = YES;
    KKInput* input = [KKInput sharedInput];
    if ([input anyTouchBeganThisFrame]) {
      for( KKTouch* touch in input.touches ){
        CGPoint touchLocation =[_stage convertToNodeSpace:touch.location];
        
        MSTile* tile = [_map tileWithStagePoint:touchLocation];
        switch ([tile tileType]) {
          case MSTileTypeRock:
          {
          [tile setTileType:MSTileTypeRuinRock];
          [[SimpleAudioEngine sharedEngine] playEffect:@"rock_touch.caf"];
          [tile addRockBreakAnimation]; // アニメの追加
          MSContainer* container = [MSContainer containerWithObject:[NSValue valueWithCGPoint:touchLocation] forTag:MSContainerTagRuinRock];
          [self broadcastContainerToPlayer:container];
          }
            break;
          case MSTileTypeRuinRock:
          {
          [tile setTileType:MSTileTypeBrokenRock];
          }
            break;
          default:
            break;
        }
      }
    }
    if (isAllGoal) { // 全員がゴールしてたら
      MSContainer* container = [[MSContainer alloc] initWithObject:nil forTag:MSContainerTagGameEnd];
      for (MSPlayer* player in _players) {
        [self sendContainer:container peerID:player.peerID];
      }
      // ゴールレイヤー追加
      MSGoalLayer* goal = [[MSGoalLayer alloc] initWithMainLayer:self];
      [self addChild:goal];
      [self updateHighScore]; // ハイスコアの更新
      _state = MSGameStateClear;
    } else if (isAllDead) { // 全員死んだとき
      _state = MSGameStateGameOver;
      __block MSMainLayer* blockSelf = self;
      [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:3.0f]
                                        two:[CCCallBlock actionWithBlock:^{
        MSContainer* container = [MSContainer containerWithObject:nil forTag:MSContainerTagGameOver];
        [blockSelf broadcastContainerToPlayer:container];
        [blockSelf gotoGameOverScene];
      }]]];
    }
    }
      break;
      
    default:
      break;
  }
}

- (int)currentRow {
  return [[_players objectAtIndex:0] tileCountFromStart];
}

- (void)broadCastAllPlayers {
  KWSessionManager* manager = [KWSessionManager sharedManager];
  NSMutableArray* array = [NSMutableArray array];
  for (MSPlayer* player in _players) {
    [array addObject:[player state]];
  }
  MSContainer* container = [MSContainer containerWithObject:array forTag:MSContainerTagPlayerStates];
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:container];
  [manager broadCastData:data mode:GKSendDataUnreliable];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
  MSContainer* container = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  if (container.tag == MSContainerTagPlayerState) {
    MSPlayer* player = [self playerWithPeerID:peer];
    if (player) {
      MSPlayerState* playerState = (MSPlayerState*)container.object;
      [player updateWithPlayerState:playerState];
      [self broadCastAllPlayers];
    }
  }
}

- (int)getSight {
  return [KKConfig intForKey:@"ServerSight"];
}

@end
