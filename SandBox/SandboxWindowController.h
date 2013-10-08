/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>

#import <OsiriXAPI/BurnerWindowController.h>


@interface SandboxWindowController : BurnerWindowController
{
	BurnerWindowController *m_window;
	
}

- (id)initWithFiles:(NSArray *)theFiles managedObjects:(NSArray *)managedObjects;

- (void) prepareCDContent: (NSMutableArray*) dbObjects :(NSMutableArray*) originalDbObjects;



@end
