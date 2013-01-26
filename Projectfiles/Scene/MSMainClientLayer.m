//
//  MSMainClientLayer.m
//  MultipleSession
//
//  Created by giginet on 2013/1/23.
//
//

#import "MSMainClientLayer.h"
#import "KWSessionManager.h"

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
    _cameraNode.position = ccp(-256 * _myPlayer.no, 0);
    [KKInput sharedInput].deviceMotionActive = YES;
    [KKInput sharedInput].gestureSwipeEnabled = YES;
  }
  return self;
}

- (void)update:(ccTime)dt {
  [super update:dt];
  //CCDirector* director = [CCDirector sharedDirector];
  KKInput* input = [KKInput sharedInput];
  if ([input gesturesAvailable]) {
    KKSwipeGestureDirection direction = [input gestureSwipeDirection];
    if ([input gestureSwipeRecognizedThisFrame] && (direction == KKSwipeGestureDirectionLeft || direction == KKSwipeGestureDirectionRight) ) {
      if (!_myPlayer.isLineChanging) {
        [_myPlayer setLineChangeAction:direction == KKSwipeGestureDirectionLeft ? MSDirectionLeft : MSDirectionRight];
      }
    }
  }
  
  if ([input deviceMotionAvailable]) {
    float rad = input.deviceMotion.roll; // rollを取るとラジアンが返ってくるはず！
    float deg = rad * 180 / M_PI; // ラジアンを度にする
    if (!_myPlayer.isRailChanging) { // レール切り替え中じゃないとき
      if (deg < -45) { // 左に45度以上傾いてたら
        [_myPlayer setRailChangeAction:MSDirectionLeft];
      } else if (deg > 45) { // 右に45度以上傾いてたら
        [_myPlayer setRailChangeAction:MSDirectionRight];
      }
    }
    _myPlayer.position = ccpAdd(_myPlayer.position, [_myPlayer.velocity point]);
  }
  [self sendPlayerToServer:_myPlayer];
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
      NSLog(@"goal %d", _myPlayer.no);
    }
  }
}

@end
