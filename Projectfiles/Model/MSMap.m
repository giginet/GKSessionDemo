//
//  MSMapLoader.m
//  MultipleSession
//
//  Created by giginet on 1/26/13.
//
//

#import "MSMap.h"

@interface MSMap()
- (MSTile*)tileWithString:(NSString*)chip line:(int)line rail:(int)rail;
@end

@implementation MSMap

- (id)init {
  self = [super init];
  if (self) {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"stage1"
                                                     ofType:@"txt"];
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    _lines = [content componentsSeparatedByString:@"\n"];
    _chips = [NSMutableDictionary dictionary];
    _coinCount = 0;
  }
  return self;
}

- (MSTile*)tileWithLine:(int)line rail:(int)rail y:(int)y {
  int count = [_lines count];
  if (y < count) {
    int x = line * 3 + rail;
    NSValue* key = [NSValue valueWithCGPoint:CGPointMake(x, y)];
    if ([_chips objectForKey:key]) { // キャッシュにあるときはそのまま返す
      return [_chips objectForKey:key];
    } else { // ないときは新しく作る
      NSString* lineString = (NSString*)[_lines objectAtIndex:count - y - 1];
      NSString* chip = [lineString substringWithRange:NSMakeRange(x, 1)];
      MSTile* tile = [self tileWithString:chip line:line rail:rail];
      [_chips setObject:tile forKey:key];
      if (tile.tileType == MSTileTypeCoin) { // コインの時、総コイン枚数+1
        _coinCount += 1;
      }
      return tile;
    }
  }
  return nil;
}

- (NSDictionary*) itemDictionary
{
  if( _itemDictionary == nil ){
    _itemDictionary = @{
    @".":[NSNumber numberWithInt:MSTileTypeNone]
    ,@"#":[NSNumber numberWithBool:MSTileTypeRail]
    ,@"B":[NSNumber numberWithInt:MSTileTypeBranch]
    ,@"R":[NSNumber numberWithInt:MSTileTypeRock]
    ,@"C":[NSNumber numberWithInt:MSTileTypeCoin]
    };
    
  }
  return _itemDictionary;
}


- (MSTile*)tileWithString:(NSString *)chip line:(int)line rail:(int)rail {
  NSNumber* tileType = self.itemDictionary[chip];
  MSTileType type = [tileType intValue] != MSTileTypeBranch ? [tileType intValue] : (rail == 2 ? MSTileTypeBranchRight : MSTileTypeBranchLeft);
  return [[MSTile alloc] initWithTileType:type];
}

- (MSTile*)tileWithStagePoint:(CGPoint)point {
  int lineWidth = [KKConfig intForKey:@"LineWidth"];
  int railWidth = [KKConfig intForKey:@"RailWidth"];
  int line = floor(point.x / lineWidth);
  int rail = floor((point.x - (line * lineWidth)) / railWidth);
  int y = floor(point.y / railWidth);
  return [self tileWithLine:line rail:rail y:y];
}

- (int)height {
  return [_lines count];
}

@end
