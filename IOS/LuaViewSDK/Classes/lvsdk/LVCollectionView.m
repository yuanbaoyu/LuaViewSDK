//
//  LVCollectionView.m
//  LVSDK
//
//  Created by dongxicheng on 6/11/15.
//  Copyright (c) 2015 dongxicheng. All rights reserved.
//

#import "LVCollectionView.h"
#import "LVCollectionViewCell.h"
#import "LView.h"
#import "LVBaseView.h"
#import "LVScrollView.h"
#import "UIScrollView+LuaView.h"
#import "LVCollectionViewDelegate.h"


// lua 对应的数据 key


@interface LVCollectionView ()
@property (nonatomic,strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic,strong) LVCollectionViewDelegate* collectionViewDelegate;
@end


@implementation LVCollectionView

-(id) init:(lv_State*) l identifierArray:(NSArray*) identifierArray {
    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self = [super initWithFrame:CGRectMake(0, 0, 0, 0) collectionViewLayout:flowLayout];
    if( self ){
        self.lv_lview = (__bridge LView *)(l->lView);
        self.collectionViewDelegate = [[LVCollectionViewDelegate alloc] init:self];
        self.delegate = self.collectionViewDelegate;
        self.dataSource = self.collectionViewDelegate;
        self.backgroundColor = [UIColor clearColor];
        
        self.flowLayout = flowLayout;
        
        [self registerClass:[LVCollectionViewCell class] forCellWithReuseIdentifier:DEFAULT_CELL_IDENTIFIER];
        for( NSString* identifier in identifierArray ){
            [self registerClass:[LVCollectionViewCell class] forCellWithReuseIdentifier:identifier];
        }
    }
    return self;
}

-(void) registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier{
    [super registerClass:cellClass forCellWithReuseIdentifier:identifier];
    if( self.collectionViewDelegate.identifierDic == nil ) {
        self.collectionViewDelegate.identifierDic = [[NSMutableDictionary alloc] init];
    }
    [self.collectionViewDelegate.identifierDic setValue:identifier forKey:identifier];
}

-(void) dealloc{
}

-(void) layoutSubviews{
    [super layoutSubviews];
    
    [self lv_callLuaByKey1:@"LayoutSubviews" key2:nil];
}

static Class g_class = nil;

+ (void) setDefaultStyle:(Class) c{
    if( [c isSubclassOfClass:[LVCollectionView class]] ) {
        g_class = c;
    }
}

#pragma -mark lvNewCollectionView
static int lvNewCollectionView (lv_State *L) {
    if( g_class == nil ) {
        g_class = [LVCollectionView class];
    }
    BOOL haveArgs = NO;
    NSArray* identifierArray = nil;
    if ( lv_gettop(L)>=1 && lv_type(L, 1)==LV_TTABLE ) {
        haveArgs = YES;
    }
    if( haveArgs ) {
        lv_pushstring(L, "Cell");
        lv_gettable(L, 1);
        identifierArray = lv_luaTableKeys(L, -1);
    }
    LVCollectionView* tableView = [[g_class alloc] init:L identifierArray:identifierArray];

    NEW_USERDATA(userData, LVUserDataView);
    userData->view = CFBridgingRetain(tableView);
    tableView.lv_userData = userData;
    lvL_getmetatable(L, META_TABLE_UICollectionView );
    lv_setmetatable(L, -2);
    
    if ( haveArgs ) {
        lv_pushvalue(L, 1);
        lv_udataRef(L, USERDATA_KEY_DELEGATE );
    }
    
    LView* lview = (__bridge LView *)(L->lView);
    if( lview ){
        [lview containerAddSubview:tableView];
    }
    return 1;
}

//static int delegate (lv_State *L) {
//    LVUserDataView * user = (LVUserDataView *)lv_touserdata(L, 1);
//    if( user ){
//        if ( lv_gettop(L)>=2 ) {
//            NSArray* identifierArray = nil;
//            if ( lv_gettop(L)>=2 && lv_type(L, 2)==LV_TTABLE ) {
//                lv_pushstring(L, "Cell");
//                lv_gettable(L, 2);
//                identifierArray = lv_luaTableKeys(L, -1);
//            }
//            lv_settop(L, 2);
//            lv_udataRef(L, USERDATA_KEY_DELEGATE);
//            
//            if ( identifierArray ) {
//                LVCollectionView* collectionView = (__bridge LVCollectionView *)(user->view);
//                for( NSString* identifier in identifierArray ){
//                    [collectionView registerClass:[LVCollectionViewCell class] forCellWithReuseIdentifier:identifier];
//                }
//            }
//            return 1;
//        } else {
//            lv_pushUDataRef(L, USERDATA_KEY_DELEGATE);
//            return 1;
//        }
//    }
//    return 0;
//}

static int reloadData (lv_State *L) {
    LVUserDataView * user = (LVUserDataView *)lv_touserdata(L, 1);
    if( user ){
        LVCollectionView* tableView = (__bridge LVCollectionView *)(user->view);
        [tableView reloadData];
        lv_pushvalue(L, 1);
        return 1;
    }
    return 0;
}

static int miniSpacing (lv_State *L) {
    LVUserDataView * user = (LVUserDataView *)lv_touserdata(L, 1);
    if( user ){
        LVCollectionView* tableView = (__bridge LVCollectionView *)(user->view);
        if( lv_gettop(L)>=3 ) {
            CGFloat value1 = lv_tonumber(L, 2);
            CGFloat value2 = lv_tonumber(L, 3);
            tableView.flowLayout.minimumLineSpacing = value1;
            tableView.flowLayout.minimumInteritemSpacing = value2;
            return 0;
        } else if( lv_gettop(L)>=2 ) {
            CGFloat value1 = lv_tonumber(L, 2);
            tableView.flowLayout.minimumLineSpacing = value1;
            tableView.flowLayout.minimumInteritemSpacing = value1;
            return 0;
        } else {
            CGFloat value1 = tableView.flowLayout.minimumLineSpacing;
            CGFloat value2 = tableView.flowLayout.minimumInteritemSpacing;
            lv_pushnumber(L, value1);
            lv_pushnumber(L, value2);
            return 2;
        }
    }
    return 0;
}

static int scrollDirection (lv_State *L) {
    LVUserDataView * user = (LVUserDataView *)lv_touserdata(L, 1);
    if( user ){
        LVCollectionView* tableView = (__bridge LVCollectionView *)(user->view);
        if( lv_gettop(L)>=2 ) {
            int value1 = lv_tonumber(L, 2);
            tableView.flowLayout.scrollDirection = value1;
            return 0;
        } else {
            CGFloat value1 = tableView.flowLayout.scrollDirection;
            lv_pushnumber(L, value1);
            return 1;
        }
    }
    return 0;
}

static int rectForSection (lv_State *L) {
    LVUserDataView * user = (LVUserDataView *)lv_touserdata(L, 1);
    if( LVIsType(user,LVUserDataView) ){
        LVCollectionView* tableView = (__bridge LVCollectionView *)(user->view);
        if( [tableView isKindOfClass:[LVCollectionView class]] ) {
            int nargs = lv_gettop(L);
            if( nargs>=3 ){
                int section = lv_tonumber(L, 2)-1;
                int row = lv_tonumber(L, 3)-1;
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                CGRect r = [tableView layoutAttributesForItemAtIndexPath:indexPath].frame;
                lv_pushnumber(L, r.origin.x);
                lv_pushnumber(L, r.origin.y);
                lv_pushnumber(L, r.size.width);
                lv_pushnumber(L, r.size.height);
                return 4;
            }
        }
    }
    return 0;
}

+(int) classDefine: (lv_State *)L {
    {
        lv_pushcfunction(L, lvNewCollectionView);
        lv_setglobal(L, "CollectionView");
    }
    const struct lvL_reg memberFunctions [] = {
        {"reload",    reloadData},
        {"rectForSection", rectForSection},
        
        {"miniSpacing", miniSpacing},
        
//        {"delegate", delegate},
        
        {"scrollDirection", scrollDirection},
        {NULL, NULL}
    };
    
    lv_createClassMetaTable(L ,META_TABLE_UICollectionView);
    
    lvL_openlib(L, NULL, [LVBaseView baseMemberFunctions], 0);
    lvL_openlib(L, NULL, [LVScrollView memberFunctions], 0);
    lvL_openlib(L, NULL, memberFunctions, 0);
    
    const char* keys[] = { "addView", NULL};// 移除多余API
    lv_luaTableRemoveKeys(L, keys );
    return 1;
}



-(NSString*) description{
    return [NSString stringWithFormat:@"<CollectionView(0x%x) frame = %@; contentSize = %@>",
            (int)[self hash], NSStringFromCGRect(self.frame) , NSStringFromCGSize(self.contentSize)];
}

@end
