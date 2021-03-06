//
//  MSPlayer.h
//  MultipleSession
//
//  Created by giginet on 2013/1/23.
//
//

#import "CCSprite.h"
#import "MSPlayerState.h"
#import "KWVector.h"
#import "KWTimer.h"

typedef enum {
  MSDirectionLeft,
  MSDirectionRight
} MSDirection;

@interface MSPlayer : CCSprite {
  int _no;
  BOOL _isMine;
  NSString* _peerID;
}

@property(readonly) int no; // キャラ番号0~2
@property(readwrite) int life; // ライフ
@property(readwrite) int railNumber; // 現在のレール番号
@property(readwrite) int lineNumber; // 現在のライン番号
@property(readwrite) int coinCount; // コインの枚数
@property(readonly) BOOL isMine; // 自分の操っているキャラかどうか
@property(readwrite) BOOL isRailChanging; // レール切り替え中かどうか
@property(readwrite) BOOL isLineChanging; // ライン切り替え中かどうか
@property(readwrite) BOOL isRailChanged; // レールチェンジ後かどうか
@property(readwrite) BOOL isCrashing;
@property(readwrite) BOOL isGoal; // ゴールしたかどうか
@property(readonly) BOOL isDead; // 死んでるかどうか
@property(readonly, copy) NSString* peerID; // PeerID
@property(readwrite, retain) KWVector* velocity; // 加速度

/*
 x座標が変化するのは
  ・レールの変更
  ・ラインの変更
 のみなので、その時のみ操作してやる
 */
@property(readwrite) float x; // 現在のx座標

- (id)initWithPeerID:(NSString*)peerID no:(int)no;
- (void)update:(ccTime)dt;
- (NSData*)dump;
- (MSPlayerState*)state;
- (void)updateWithPlayerState:(MSPlayerState*)state;

/**
 現在の座標からレール番号、ライン番号を更新します
 */
- (void)updateRailAndLineNumber;


/**
 レールの変更をするアクションを追加します
 @param MSDirection どちらのラインに移動するか
 */
- (void)setRailChangeAction:(MSDirection)direction;

- (void)setLineChangeAction:(MSDirection)direction;

- (void)setCrashAnimation;

- (BOOL)canMoving;

// スタートからのタイル数を取得します
- (int)tileCountFromStart;

@end
