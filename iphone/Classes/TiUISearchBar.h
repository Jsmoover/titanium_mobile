/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#if defined(USE_TI_UITABLEVIEW) || defined(USE_TI_UILISTVIEW)
#ifndef USE_TI_UISEARCHBAR
#define USE_TI_UISEARCHBAR
#endif
#endif

#ifdef USE_TI_UISEARCHBAR

#import "TiUIView.h"

@interface TiSearchDisplayController : UISearchDisplayController
@property (nonatomic, assign) BOOL preventHiddingNavBar;

@end

@interface TiUISearchBar : TiUIView<UISearchBarDelegate> {
@private
	UISearchBar *searchView;
	id<UISearchBarDelegate> delegate;
}

-(void)setDelegate:(id<UISearchBarDelegate>)delegate;
-(UISearchBar*)searchBar;
-(TiSearchDisplayController*)searchController;

@end

#endif