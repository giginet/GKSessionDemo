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
#import "MSMap.h"
#import "DummyManager.h"
#import "SimpleAudioEngine.h"

@interface MSMatchLayer()
- (void)updatePeerStateFor:(NSString*)peer toState:(GKPeerConnectionState)state;
- (void)onStart:(id)sender;
- (void)onStartDemo:(id)sender;
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
    
    CCSprite* spriteBoard = [CCSprite spriteWithFile:@"board.png"];
    spriteBoard.position = _type == MSSessionTypeClient ? ccp(160.0f,480.0f - 141.0f) : ccp(389.95f,1024-367.75f);
    [self addChild:spriteBoard];
    
    _lightServer = [CCSprite spriteWithFile:@"off.png"];
    _lightServer.position = _type == MSSessionTypeClient ? ccp(69.15,480.0f - 126.75f) : ccp(168.95,1024-367.75f);
    [self addChild:_lightServer];
    
    _lightClient = [CCSprite spriteWithFile:@"off.png"];
    _lightClient.position = _type == MSSessionTypeClient ? ccp(174.0f,480.0f - 126.75f) : ccp(441.75,1024-364.75f);
    [self addChild:_lightClient];
    
    _lightClient2 = [CCSprite spriteWithFile:@"off.png"];
    _lightClient2.position = _type == MSSessionTypeClient ? ccp(69.15,480.0f - 174.4f) : ccp(168.95,1024-481.1f);
    [self addChild:_lightClient2];
    
    _lightClient3 = [CCSprite spriteWithFile:@"off.png"];
    _lightClient3.position = _type == MSSessionTypeClient ? ccp(174.0f,480.0f - 174.4f) : ccp(441.75,1024-481.1f);
    [self addChild:_lightClient3];
    
    CCSprite* spriteStay = [CCSprite spriteWithFile:@"stay.png"];
    spriteStay.position = _type == MSSessionTypeClient ? ccp(160,480.0f - 81.4) : ccp(384.95,1024-224);
    [self addChild:spriteStay];
    

    const float stateFontSizePhone = [KKConfig floatForKey:@"MatchStateFontSizePhone"];
    const float stateFontSizePad = [KKConfig floatForKey:@"MatchStateFontSizePad"];
    
    
    
    
    [_sessionManager startSession:kSessionID sessionMode:type == MSSessionTypeClient ? GKSessionModeClient : GKSessionModeServer];
    _sessionManager.delegate = self;
    [_sessionManager available];
    
    if (_type == MSSessionTypeClient) {
      _stateLabel = [CCLabelTTF labelWithString:@"ホストを探しています" fontName:@"Helvetica" fontSize:_type == MSSessionTypeClient ? stateFontSizePhone : stateFontSizePad];
    } else {
      _stateLabel = [CCLabelTTF labelWithString:@"参加者を募集中" fontName:@"Helvetica" fontSize:_type == MSSessionTypeClient ? stateFontSizePhone : stateFontSizePad];
    }
    _stateLabel.position = _type == MSSessionTypeClient ? ccp(director.screenCenter.x, 480 - 213.6 ) : ccp(director.screenCenter.x, 1024 - 682.5);
    _stateLabel.color = ccc3(255, 255, 255);
    
    _peersNode = [CCNode node];
    _peersNode.position = director.screenCenter;
    //[self addChild:_stateLabel];
    [self addChild:_peersNode];
    if (_type == MSSessionTypeServer) {
      _serverPeerID = _sessionManager.session.peerID;
    } else {
      _serverPeerID = @"";
    }
    if (_type == MSSessionTypeServer) {
      CCMenuItemImage* menuItemImage = [CCMenuItemImage itemWithNormalImage:@"startbtn.png" selectedImage:@"startbtn-on.png"disabledImage:@"startbtn-on.png" target:self selector:@selector(onStart:)];
      _startMenu = [CCMenu menuWithItems:menuItemImage,nil];
      _startMenu.enabled = NO;
      _startMenu.position = ccp(384,1024 - 613.15);
      [self addChild:_startMenu];

      
      CCLabelTTF* startLabel = [CCLabelTTF labelWithString:@"Demo" fontName:@"Helvetica" fontSize:32];
      CCMenuItemLabel* start = [CCMenuItemLabel itemWithLabel:startLabel target:self selector:@selector(onStartDemo:)];
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

    CCDirector* director = [CCDirector sharedDirector];
    CGPoint center = director.screenCenter;
    
    const CGPoint pointsClient[] = {
      ccp(120.55f - center.x,480.0f - 126.45f- center.y)
      ,ccp(223.55f- center.x,480.0f - 126.45f- center.y)
      ,ccp(120.55f- center.x,480.0f - 171.45- center.y)
      ,ccp(223.55f- center.x,480.0f - 171.45- center.y) };
    
    const CGPoint pointsServer[] = {
       ccp(305.55f- center.x,1024.0f - 364.1f- center.y)
      ,ccp(582.15f- center.x,1024.0f - 364.1f- center.y)
      ,ccp(305.55f- center.x,1024.0f - 478.6f- center.y)
      ,ccp(582.15f- center.x,1024.0f - 474.6f- center.y)
    };
    
    const CGPoint* points = _type == MSSessionTypeClient ? pointsClient : pointsServer;
    const float fontSizePhone = [KKConfig floatForKey:@"MatchFontSizePhone"];
    const float fontSizePad = [KKConfig floatForKey:@"MatchFontSizePad"];
    
    CCSprite* indicators[] = {
      _lightServer,_lightClient,_lightClient2,_lightClient3
    };

    const CGPoint pointServerMarkOffset = ccp( 0 , -44.f);
    
    if( _type == MSSessionTypeServer ){
      NSString* peerName = [_serverPeerID length] > 0 ?  [_sessionManager.session displayNameForPeer:_serverPeerID] : nil;
      if( [peerName length] <= 0 )
        peerName = [UIDevice currentDevice].name;
      
      if( [peerName length] > 0 )
      {
        if( _spriteServerMark == nil ){
          _spriteServerMark = [CCSprite spriteWithFile:@"crown.png"];
          _spriteServerMark.position = CGPointMake(points[count].x - pointServerMarkOffset.x ,points[count].y - pointServerMarkOffset.y);
          [_peersNode addChild:_spriteServerMark];
        }else{
          _spriteServerMark.position = CGPointMake(points[count].x - pointServerMarkOffset.x ,points[count].y - pointServerMarkOffset.y);
        }
        
        
        CCLabelTTF* label = [CCLabelTTF labelWithString:peerName fontName:@"Helvetica" fontSize:_type == MSSessionTypeClient ? fontSizePhone : fontSizePad];

        label.position = points[count];
        [_peersNode addChild:label];
        [indicators[count] setTexture:[[CCTextureCache sharedTextureCache] addImage:@"on.png"]];
      }
      count++;
    }
    
    
    for (NSString* peerID in [_peers keyEnumerator]) {
      GKPeerConnectionState s = (GKPeerConnectionState)[(NSNumber*)[_peers objectForKey:peerID] intValue];
      NSString* peerName = [_sessionManager.session displayNameForPeer:peerID];
      CCLabelTTF* label = [CCLabelTTF labelWithString:peerName fontName:@"Helvetica" fontSize:_type == MSSessionTypeClient ? fontSizePhone : fontSizePad];

      label.position = points[count];

      
      if ([_serverPeerID isEqualToString:peerID]) {
        
        if( _spriteServerMark == nil ){
          _spriteServerMark = [CCSprite spriteWithFile:@"crown.png"];
          _spriteServerMark.position = CGPointMake(points[count].x - pointServerMarkOffset.x ,points[count].y - pointServerMarkOffset.y);
          [_peersNode addChild:_spriteServerMark];
        }else{
          _spriteServerMark.position = CGPointMake(points[count].x - pointServerMarkOffset.x ,points[count].y - pointServerMarkOffset.y);
        }
        
        
        [indicators[count] setTexture:[[CCTextureCache sharedTextureCache] addImage:@"on.png"]];
      } else if (s == GKPeerStateConnecting) {
        [indicators[count] setTexture:[[CCTextureCache sharedTextureCache] addImage:@"off.png"]];
      } else if (s == GKPeerStateConnected) {
        [indicators[count] setTexture:[[CCTextureCache sharedTextureCache] addImage:@"on.png"]];
      } else if (s == GKPeerStateDisconnected) {
        [indicators[count] setTexture:[[CCTextureCache sharedTextureCache] addImage:@"off.png"]];
      } else {

      }
      
      
//      if ([_serverPeerID isEqualToString:peerID]) {
//        label.color = ccc3(0, 0, 255);
//      } else if (s == GKPeerStateConnecting) {
//        label.color = ccc3(255, 255, 0);
//      } else if (s == GKPeerStateConnected) {
//        label.color = ccc3(255, 0, 0);
//      } else if (s == GKPeerStateDisconnected) {
//        label.color = ccc3(128, 128, 128);
//      } else {
//        label.color = ccc3(255, 255, 255);
//      }
      [_peersNode addChild:label];
      ++count;
    }
    
    
    
  }
}

- (void)onEnter {
  [super onEnter];
  [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
  [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"matching.caf"];
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
  [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
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
        [[SimpleAudioEngine sharedEngine] playEffect:@"matching_complete.caf"];
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
