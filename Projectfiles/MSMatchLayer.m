//
//  MSMatchLayer.m
//  MultipleSession
//
//  Created by giginet on 2013/1/23.
//
//

#import "MSMatchLayer.h"
#import "MSMainClientLayer.h"
#import "MSMainServerLayer.h"
#import "MSMapLoader.h"
#import "DummyManager.h"

@interface MSMatchLayer()
- (void)updatePeerStateFor:(NSString*)peer toState:(GKPeerConnectionState)state;
- (void)onStart:(id)sender;
@end

@implementation MSMatchLayer

NSString* kSessionID = @"MultipleMatch";
NSString* kStartMessage = @"GameStart";

- (id)initWithServerOrClient:(MSSessionType)type {
  self = [super init];
  if (self) {
    CCDirector* director = [CCDirector sharedDirector];
    _type = type;
    _peers = [NSMutableDictionary dictionary];
    _sessionManager = [KWSessionManager sharedManager];
    _clients = [NSArray array];
    
    [_sessionManager startSession:kSessionID sessionMode:type == MSSessionTypeClient ? GKSessionModeClient : GKSessionModeServer];
    _sessionManager.delegate = self;
    [_sessionManager available];
    
    if (_type == MSSessionTypeClient) {
      _stateLabel = [CCLabelTTF labelWithString:@"ホストを探しています" fontName:@"Helvetica" fontSize:24];
    } else {
      _stateLabel = [CCLabelTTF labelWithString:@"参加者を募集中" fontName:@"Helvetica" fontSize:24];
    }
    _stateLabel.position = ccp(director.screenCenter.x, 280);
    _stateLabel.color = ccc3(255, 255, 255);
    
    _peersNode = [CCNode node];
    _peersNode.position = director.screenCenter;
    [self addChild:_stateLabel];
    [self addChild:_peersNode];
    if (_type == MSSessionTypeServer) {
      _serverPeerID = _sessionManager.session.peerID;
    } else {
      _serverPeerID = @"";
    }
    if (_type == MSSessionTypeServer) {
      CCLabelTTF* startLabel = [CCLabelTTF labelWithString:@"Start" fontName:@"Helvetica" fontSize:32];
      CCMenuItemLabel* start = [CCMenuItemLabel itemWithLabel:startLabel target:self selector:@selector(onStart:)];
      _startMenu = [CCMenu menuWithItems:start, nil];
      _startMenu.enabled = NO;
      _startMenu.position = ccp(director.screenCenter.x, 50);
      [self addChild:_startMenu];
        
        
      /*CCLabelTTF**/ startLabel = [CCLabelTTF labelWithString:@"Demo" fontName:@"Helvetica" fontSize:32];
      /*CCMenuItemLabel**/ start = [CCMenuItemLabel itemWithLabel:startLabel target:self selector:@selector(onStartDemo:)];
      _demoMenu = [CCMenu menuWithItems:start, nil];
      _demoMenu.enabled = YES;
      _demoMenu.position = ccp(director.screenCenter.x, 100);
      [self addChild:_demoMenu];
      
    }
  }
  return self;
}

- (void)updatePeerStateFor:(NSString *)peer toState:(GKPeerConnectionState)state {
  if (state == GKPeerStateUnavailable) {
    [_peers removeObjectForKey:peer];
  } else {
    [_peers setObject:[NSNumber numberWithInt:state] forKey:peer];
    [_peersNode removeAllChildrenWithCleanup:YES];
    int count = 0;
    for (NSString* peerID in [_peers keyEnumerator]) {
      GKPeerConnectionState s = (GKPeerConnectionState)[(NSNumber*)[_peers objectForKey:peerID] intValue];
      NSString* peerName = [_sessionManager.session displayNameForPeer:peerID];
      CCLabelTTF* label = [CCLabelTTF labelWithString:peerName fontName:@"Helvetica" fontSize:16];
      label.position = ccp(0, count * 20);
      if ([_serverPeerID isEqualToString:peerID]) {
        label.color = ccc3(0, 0, 255);
      } else if (s == GKPeerStateConnecting) {
        label.color = ccc3(255, 255, 0);
      } else if (s == GKPeerStateConnected) {
        label.color = ccc3(255, 0, 0);
      } else if (s == GKPeerStateDisconnected) {
        label.color = ccc3(128, 128, 128);
      } else {
        label.color = ccc3(255, 255, 255);
      }
      [_peersNode addChild:label];
      ++count;
    }
  }
}

- (void)onStart:(id)sender {
  CCLayer* nextLayer = nil;
  if (_type == MSSessionTypeServer) {
    // サーバー側、接続順に従ってクライアント一覧を作る
    NSMutableArray* clients = [NSMutableArray arrayWithArray:_sessionManager.connectedPeers];
    [clients removeObject:_serverPeerID];
    _clients = [NSArray arrayWithArray:clients];
    nextLayer = [[MSMainServerLayer alloc] initWithServerPeer:_serverPeerID andClients:[CCArray arrayWithNSArray:_clients]];
    for (NSString* client in clients) {
      MSContainer* container = [MSContainer containerWithObject:clients forTag:MSMatchContainerTagClients];
      [_sessionManager sendDataToPeer:[NSKeyedArchiver archivedDataWithRootObject:container] to:client mode:GKSendDataReliable];
    }
  } else {
    // クライアント側、サーバーから受け取ったクライアントをそのまま使う
    nextLayer = [[MSMainClientLayer alloc] initWithServerPeer:_serverPeerID andClients:[CCArray arrayWithNSArray:_clients]];
  }
  CCScene* scene = [CCScene node];
  [scene addChild:nextLayer];
  CCTransitionFade* fade = [CCTransitionFade transitionWithDuration:0.5f scene:scene];
  [[CCDirector sharedDirector] replaceScene:fade];
}

- (void) onStartDemo:(id)sender {
    
    if (_type == MSSessionTypeServer) {
        
        // サーバー側、接続順に従ってクライアント一覧を作る
        NSMutableArray* clients = [NSMutableArray arrayWithArray:_sessionManager.connectedPeers];
        [clients removeObject:_serverPeerID];
        _clients = [NSArray arrayWithArray:clients];
        CCLayer* nextLayer = [[MSMainServerLayer alloc] initWithServerPeer:[DummyManager serverID] andClients:[CCArray arrayWithNSArray:@[
                                                                                                               [DummyManager playerID]
                                                                                                               ,[DummyManager player2ID]
                                                                                                               ,[DummyManager player3ID]
                                                                                                               ]]];
        for (NSString* client in clients) {
            MSContainer* container = [MSContainer containerWithObject:clients forTag:MSMatchContainerTagClients];
            [_sessionManager sendDataToPeer:[NSKeyedArchiver archivedDataWithRootObject:container] to:client mode:GKSendDataReliable];
        }
        
        CCScene* scene = [CCScene node];
        [scene addChild:nextLayer];
        CCTransitionFade* fade = [CCTransitionFade transitionWithDuration:0.5f scene:scene];
        [[CCDirector sharedDirector] replaceScene:fade];
      
      [_sessionManager disable];
      [_sessionManager stopSession];
      
    }
}

#pragma mark KWSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
  NSString* stateName = @"";
  switch (state) {
    case GKPeerStateAvailable:
      stateName = @"Available";
      [_sessionManager connectToPeer:peerID];
      break;
    case GKPeerStateConnecting:
      stateName = @"Connecting";
      break;
    case GKPeerStateConnected:
      stateName = @"Connected";
      if (_type == MSSessionTypeClient) {
        [_stateLabel setString:@"ホストに接続しました"];
      } else if (_type == MSSessionTypeServer) {
        MSContainer* container = [MSContainer containerWithObject:_serverPeerID forTag:MSMatchContainerTagServerPeer];
        [_sessionManager broadCastData:[NSKeyedArchiver archivedDataWithRootObject:container] mode:GKSendDataUnreliable];
      }
    default:
      break;
  }
  NSLog(@"%@, %@", [_sessionManager.session displayNameForPeer:peerID], stateName);
  [self updatePeerStateFor:peerID toState:state];
  if (_type == MSSessionTypeServer) {
    int count = [_sessionManager.connectedPeers count];
    _startMenu.enabled = count > 0;
  }
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
  [_sessionManager acceptConnectionFromPeer:peerID];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession:(GKSession *)session context:(void *)context {
  if (_type == MSSessionTypeClient) {
    MSContainer* container = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (container.tag == MSMatchContainerTagClients) {
      _clients = (NSArray*)container.object;
      [self onStart:nil];
    } else if (container.tag == MSMatchContainerTagServerPeer) {
      _serverPeerID = (NSString*)container.object;
      [self updatePeerStateFor:peer toState:GKPeerStateConnected];
    }
  }
}

@end
