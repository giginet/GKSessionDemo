//
//  MSMainClientLayer.m
//  MultipleSession
//
//  Created by giginet on 2013/1/23.
//
//

#import "MSMainClientLayer.h"
#import "KWSessionManager.h"
#import "MSGoalLayer.h"
#import "MSTitleLayer.h"
#import "SimpleAudioEngine.h"

@interface MSMainClientLayer()
- (void)sendPlayerToServer:(MSPlayer*)player;
@end

@implementation MSMainClientLayer

- (id)initWithServerPeer:(NSString *)peer andClients:(CCArray *)peers {
  self = [super initWithServerPeer:peer andClients:peers];
  if (self) {
    for (MSPlayer* player in _players) {
      if (player.isMine) {
        _myPlayer = player;
        break;
      }
    }
    _cameraNode.position = ccp(-320 * _myPlayer.lineNumber, 0);
    [KKInput sharedInput].deviceMotionActive = YES;
    [KKInput sharedInput].gestureSwipeEnabled = YES;
  }
  return self;
}

- (void)update:(ccTime)dt {
  [super update:dt];
  //CCDirector* director = [CCDirector sharedDirector];
  KKInput* input = [KKInput sharedInput];
  
  switch (_state) {
    case MSGameStateMain:
    {
    // ライン変更
    if ([input gesturesAvailable]) {
      KKSwipeGestureDirection direction = [input gestureSwipeDirection];
      if ([input gestureSwipeRecognizedThisFrame] && (direction == KKSwipeGestureDirectionLeft || direction == KKSwipeGestureDirectionRight) ) {
        MSTile* tile = [_map tileWithStagePoint:_myPlayer.position]; // 現在の足下のタイルを取得します
        if ([_myPlayer canMoving]) {
          if (tile.tileType == MSTileTypeBranchLeft || tile.tileType == MSTileTypeBranchRight) { // 足下がブランチの時のみ分岐可能です
            [[SimpleAudioEngine sharedEngine] playEffect:@"line_change.caf"];
            [_myPlayer setLineChangeAction:direction == KKSwipeGestureDirectionLeft ? MSDirectionLeft : MSDirectionRight];
          }
        }
      }
    }
    
    // レール変更
    if ([input deviceMotionAvailable]) {
      float rad = input.deviceMotion.roll; // rollを取るとラジアンが返ってくるはず！
      float deg = rad * 180 / M_PI; // ラジアンを度にする
      if ([_myPlayer canMoving]) { // レール切り替え中じゃないとき
        if (deg < -45) { // 左に45度以上傾いてたら
          if (!_myPlayer.isRailChanged) {
            [_myPlayer setRailChangeAction:MSDirectionLeft];
            [[SimpleAudioEngine sharedEngine] playEffect:@"rail_change.caf"];
          }
        } else if (deg > 45) { // 右に45度以上傾いてたら
          if (!_myPlayer.isRailChanged) {
            [_myPlayer setRailChangeAction:MSDirectionRight];
            [[SimpleAudioEngine sharedEngine] playEffect:@"rail_change.caf"];
          }
        } else {
          _myPlayer.isRailChanged = NO;
        }
      }
    }
    
    // 移動に応じてカメラを動かしてやる
    if (_myPlayer.isLineChanging) {
      _cameraNode.position = ccp(-_myPlayer.position.x + 160, 0);
    } else {
      _cameraNode.position = ccp(_myPlayer.lineNumber * -320, 0);
    }
    
    [self sendPlayerToServer:_myPlayer];
    }
      break;
    default:
      break;
  }
}

- (int)getSight {
  return [KKConfig intForKey:@"ClientSight"];
}

- (int)currentRow {
  return [_myPlayer tileCountFromStart];
}

- (void)sendPlayerToServer:(MSPlayer *)player {
  KWSessionManager* manager = [KWSessionManager sharedManager];
  MSContainer* container = [MSContainer containerWithObject:[player state] forTag:MSContainerTagPlayerState];
  [manager sendDataToPeer:[NSKeyedArchiver archivedDataWithRootObject:container] to:_angel.peerID mode:GKSendDataUnreliable];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
  if ([peer isEqualToString:_angel.peerID]) { // サーバーから送られてきたとき
    MSContainer* container = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (container.tag == MSContainerTagPlayerStates) { // PlayerState
      NSArray* states = (NSArray*)container.object;
      for (MSPlayerState* state in states) {
        if (![_myPlayer.peerID isEqualToString:state.peerID]) { // 自分以外の時
          MSPlayer* player = [self playerWithPeerID:state.peerID];
          [player updateWithPlayerState:state];
        }
      }
    } else if (container.tag == MSContainerTagPlayerGoal) { // ゴールはいりました通知を貰ったとき
      _myPlayer.isGoal = YES;
    } else if (container.tag == MSContainerTagScroll) { // スクロール座標を貰ったとき、同期する
      NSNumber* scroll = (NSNumber*)container.object;
      if (!_myPlayer.isDead) { // プレイヤーが死んだらスクロール停止
        _scroll = [scroll floatValue];
        _myPlayer.position = ccpAdd(_myPlayer.position, [_myPlayer.velocity point]); // ついでにプレイヤーも進ませる
      }
    } else if (container.tag == MSContainerTagPlayerGoal) { // ゴール終わりました通知を貰ったとき
      // ゴールレイヤー追加
      MSGoalLayer* goal = [[MSGoalLayer alloc] initWithMainLayer:self];
      [self addChild:goal];
      _state = MSGameStateClear;
    } else if (container.tag == MSContainerTagTitleButtonPressed) { // ボタンが押されたこと通知
      [self runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:0.5f] two:[CCCallBlock actionWithBlock:^{
        CCScene* scene = [MSTitleLayer nodeWithScene];
        CCTransitionCrossFade* fade = [CCTransitionCrossFade transitionWithDuration:0.5f scene:scene];
        [[CCDirector sharedDirector] replaceScene:fade];
      }]]];
    } else if (container.tag == MSContainerTagGetCoin) { // コイン取りました通知
      MSPlayerState* state = (MSPlayerState*)container.object;
      MSPlayer* player = [self playerWithPeerID:state.peerID];
      player.coinCount += 1; // コイン追加します
      [[SimpleAudioEngine sharedEngine] playEffect:@"coin.caf"];
      [self updateCoinLabel];
      MSTile* coin = [_map tileWithStagePoint:state.position];
      [coin setTileType:MSTileTypeRail];
    } else if (container.tag == MSContainerTagRuinRock) { // 岩の破壊
      CGPoint touchPoint = [(NSValue*)container.object CGPointValue];
      MSTile* tile = [_map tileWithStagePoint:touchPoint];
      [tile setTileType:MSTileTypeRuinRock];
      [tile addRockBreakAnimation];
      [[SimpleAudioEngine sharedEngine] playEffect:@"rock_break.caf"];
    } else if (container.tag == MSContainerTagDamage) { // ダメージ受けました通知
      _myPlayer.life -= 1;
      [_myPlayer setCrashAnimation]; // クラッシュ
      if (_myPlayer.life <= 0) {
        CCDirector* director = [CCDirector sharedDirector];
        CCSprite* crash = [CCSprite spriteWithFile:[NSString stringWithFormat:@"crash%d.png", _myPlayer.no + 1]];
        crash.position = director.screenCenter;
        [self addChild:crash];
        [[SimpleAudioEngine sharedEngine] playEffect:@"death.caf"];
      } else {
        [[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
      }
    } else if (container.tag == MSContainerTagGameStart) { // ゲーム始まりました通知
      [_startLabel.actionManager addAction:[CCSequence
                                            actionOne:
                                            [CCDelayTime actionWithDuration:1.0f]
                                            two:[CCRemoveFromParentAction action]] target:_startLabel paused:NO];
      _state = MSGameStateMain;
    } else if (container.tag == MSContainerTagGameOver) { // ゲームオーバー通知
      [self gotoGameOverScene];
    }
  }
}

@end
