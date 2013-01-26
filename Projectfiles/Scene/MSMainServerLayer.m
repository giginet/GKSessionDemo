//
//  MSMainServerLayer.m
//  MultipleSession
//
//  Created by giginet on 2013/1/23.
//
//

#import "MSMainServerLayer.h"
#import "KWSessionManager.h"

@interface MSMainServerLayer()
- (void)broadCastAllPlayers;
@end

@implementation MSMainServerLayer

- (id)initWithServerPeer:(NSString *)peer andClients:(CCArray *)peers {
  self = [super initWithServerPeer:peer andClients:peers];
  if (self) {
    _cameraNode.scale = 0.8f; // iPad版はサイズを0.8倍にして扱う
  }
  return self;
}

- (void)update:(ccTime)dt {
  [super update:dt];
  CCDirector* director = [CCDirector sharedDirector];
  
  // スクロールする
  float scrollSpeed = [KKConfig floatForKey:@"ScrollSpeed"];
  float railWidth = [KKConfig floatForKey:@"RailWidth"];
  float goalPoint = _loader.height * railWidth;
  if (_scroll < goalPoint - 1024 * 1.25f) {
    _scroll += scrollSpeed;
  }
  
  // 現在のスクロール座標をPlayerにbroadcastする
  for (MSPlayer* player in _players) {
    NSNumber* scroll = [NSNumber numberWithFloat:_scroll];
    MSContainer* container = [MSContainer containerWithObject:scroll forTag:MSContainerTagScroll];
    [self sendContainer:container peerID:player.peerID];
  }
  
  // ゴール判定
  for (MSPlayer* player in _players) {
    if (_scroll >= goalPoint && player.position.y > director.screenCenter.y) { // ゴールになったとき、ゴールタグが付いたモノを送ります
      MSContainer* container = [MSContainer containerWithObject:nil forTag:MSContainerTagPlayerGoal];
      [self sendContainer:container peerID:player.peerID];
    }
  }
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

@end
