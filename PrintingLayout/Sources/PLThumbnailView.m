//
//  PLThumbnailView
//  PrintingLayout
//
//  Created by Benoit Deville on 03.09.12.
//
//

#import "PLThumbnailView.h"
#import "PLLayoutView.h"
#import <OsiriXAPI/DCMPix.h>
#include <OpenGL/CGLMacro.h>
#include <OpenGL/CGLCurrent.h>
#include <OpenGL/CGLContext.h>
#import <OsiriXAPI/GLString.h>
#import </usr/include/objc/objc-class.h>

#import <OsiriXAPI/StringTexture.h>

@implementation PLThumbnailView

@synthesize isDraggingDestination, isGoingToBeSelected, isSelected;
@synthesize shrinking;
@synthesize originalFrame;
@synthesize layoutIndex;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.isDraggingDestination   = NO;
        self.isGoingToBeSelected     = NO;
        self.isSelected              = NO;
        self.shrinking               = none;
        self.layoutIndex             = -1;
        self.annotationType          = annotGraphics;
        COPYSETTINGSINSERIES         = NO;
        
        [self setPostsFrameChangedNotifications:NO];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.isDraggingDestination   = NO;
        self.isGoingToBeSelected     = NO;
        self.isSelected              = NO;
        self.shrinking               = none;
        self.layoutIndex             = -1;
        
        self.originalFrame           = frame;
        drawingFrameRect             = frame;
        self.annotationType          = annotGraphics;
        COPYSETTINGSINSERIES         = NO;
        
        [self setPostsFrameChangedNotifications:NO];
    }
    return self;
}

//- (void)dealloc
//{
//    [super dealloc];
//}

//- (BOOL)acceptsFirstResponder
//{
//    return NO;
//}

- (BOOL)is2DViewer
{
	return NO;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"ANNOTATIONS"])
        return;
}

#pragma mark-View's graphic management

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Memorize the general preference, and force it to be "none" for the printing layout
//    NSInteger annotations = [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"];
//    [[NSUserDefaults standardUserDefaults] setInteger:annotNone forKey:@"ANNOTATIONS"];
//    [DCMView setDefaults];
//    [super drawRect:dirtyRect];
//    
//    // Go back to previous case
//    [[NSUserDefaults standardUserDefaults] setInteger:annotations forKey:@"ANNOTATIONS"];
//    [DCMView setDefaults];
//}

- (void)drawRectAnyway:(NSRect)aRect
{
    CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
    
    float heighthalf = self.frame.size.height/2 - 0.5;
    float widthhalf = self.frame.size.width/2 - 0.5;
    float sf = [self.window backingScaleFactor];
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glScalef (2.0f /(xFlipped ? -(self.frame.size.width) : self.frame.size.width), -2.0f / (yFlipped ? -(self.frame.size.height) : self.frame.size.height), 1.0f);

    if (isDraggingDestination)
    {
        glEnable(GL_BLEND);
        glColor4f(.5, .5, .5, .5);
        glBegin(GL_QUADS);
        {
            glVertex2f(-widthhalf, -heighthalf);
            glVertex2f(-widthhalf,  heighthalf);
            glVertex2f( widthhalf,  heighthalf);
            glVertex2f( widthhalf, -heighthalf);
        }
        glEnd();
        glDisable(GL_BLEND);
        glColor4f(0., 0., 1., 0.);
        glLineWidth(3 * sf);
    }
    else
    {
        if (isSelected)
        {
            glColor4f(1., .5, 0., 0.);
            glLineWidth(3 * sf);
        }
        else
        {
            glColor4f(0., 1., 0., 0.);
            glLineWidth(1. * sf);
        }
    }
    
    glBegin(GL_LINE_LOOP);
    {
        glVertex2f(-widthhalf, -heighthalf);
        glVertex2f(-widthhalf,  heighthalf);
        glVertex2f( widthhalf,  heighthalf);
        glVertex2f( widthhalf, -heighthalf);
    }
    glEnd();
}

- (void)fillView:(NSInteger)gridIndex withPasteboard:(NSPasteboard*)pasteboard
{
    if ([[pasteboard availableTypeFromArray:[NSArray arrayWithObject:pasteBoardOsiriX]] isEqualToString:pasteBoardOsiriX])
    {
        if (![pasteboard dataForType:pasteBoardOsiriX])
        {
            NSLog(@"No data in pasteboardOsiriX");
        }
        else
        {
            DCMView **draggedView = (DCMView**)malloc(sizeof(DCMView*));
            NSData *draggedData = [pasteboard dataForType:pasteBoardOsiriX];
            [draggedData getBytes:draggedView length:sizeof(DCMView*)];
            
            short index = [*draggedView curImage];
            
            [self fillView:gridIndex withDCMView:*draggedView atIndex:index];
            free(draggedView);
        }
    }
}

- (BOOL)fillView:(NSInteger)gridIndex withPasteboard:(NSPasteboard*)pasteboard atIndex:(NSInteger)imageIndex
{
    if ([[pasteboard availableTypeFromArray:[NSArray arrayWithObject:pasteBoardOsiriX]] isEqualToString:pasteBoardOsiriX])
    {
        if (![pasteboard dataForType:pasteBoardOsiriX])
        {
            NSLog(@"No data in pasteboardOsiriX");
            return NO;
        }
        else
        {
            DCMView **draggedView = (DCMView**)malloc(sizeof(DCMView*));
            NSData *draggedData = [pasteboard dataForType:pasteBoardOsiriX];
            [draggedData getBytes:draggedView length:sizeof(DCMView*)];
            
            if (imageIndex >= (*draggedView).dcmPixList.count)
                return NO;
            
            [self fillView:gridIndex withDCMView:*draggedView atIndex:imageIndex];
            free(draggedView);
            
            return YES;
        }
    }
    else
        return NO;
}

- (BOOL)fillView:(NSInteger)gridIndex withDCMView:(DCMView*)dcm atIndex:(NSInteger)imageIndex;
{
    if (imageIndex < dcm.dcmPixList.count)
    {
        NSMutableArray *pixList = [NSMutableArray array];
        [pixList addObject:[[dcm dcmPixList] objectAtIndex:imageIndex]];
        
        NSMutableArray *filesList = [NSMutableArray array];
        if ([[dcm dcmFilesList] count])
            [filesList addObject:[[dcm dcmFilesList] objectAtIndex:imageIndex]];
        
        NSMutableArray *roiList = [NSMutableArray array];
        if ([[dcm dcmRoiList] count])
            [roiList addObject:[[dcm dcmRoiList] objectAtIndex:imageIndex]];
        
        [self setPixels:pixList
                  files:[[dcm dcmFilesList]   count] ? filesList  : nil
                   rois:[[dcm dcmRoiList]     count] ? roiList    : nil
             firstImage:0
                  level:'i'
                  reset:YES];
        self.layoutIndex = gridIndex;
        
        return YES;
    }
    
    return NO;
}


- (void)shrinkWidth:(int)marginSize onIts:(shrinkType)side
{
    if ([dcmPixList count] && shrinking == none)
    {
        self.shrinking = side;

        NSViewAnimation *shrink;
        NSMutableDictionary *viewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        NSRect startFrame, endFrame;
        
        startFrame = originalFrame;
        [viewDict setObject:self forKey:NSViewAnimationTargetKey];
        [viewDict setObject:[NSValue valueWithRect:startFrame] forKey:NSViewAnimationStartFrameKey];
        endFrame = startFrame;
        int size = originalFrame.size.width * marginSize / 100;
        
        endFrame.size.width -= size;
        if (side == left)
            endFrame.origin.x += size;
        
        [viewDict setObject:[NSValue valueWithRect:endFrame] forKey:NSViewAnimationEndFrameKey];
        shrink = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:viewDict]];
        
        [shrink setDuration:0.25];
        [shrink startAnimation];
        [shrink release];
        [self setNeedsDisplay:YES];
    }
}

- (void)backToOriginalSize
{
    if ([dcmPixList count])
    {
        NSViewAnimation *shrink;
        NSMutableDictionary *viewDict = [NSMutableDictionary dictionaryWithCapacity:3];
        NSRect startFrame, endFrame;
        
        startFrame = self.frame;
        [viewDict setObject:self forKey:NSViewAnimationTargetKey];
        [viewDict setObject:[NSValue valueWithRect:startFrame] forKey:NSViewAnimationStartFrameKey];
        endFrame = originalFrame;
        self.shrinking = none;
        [viewDict setObject:[NSValue valueWithRect:endFrame] forKey:NSViewAnimationEndFrameKey];
        shrink = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:viewDict]];
        
        [shrink setDuration:0.25];
        [shrink startAnimation];
        [shrink release];
        [self setNeedsDisplay:YES];
    }
}

- (void)clearView
{
    [self setPixels:nil files:nil rois:nil firstImage:0 level:0 reset:YES]; // A bit dirty?
    self.isSelected = NO;
    [self setNeedsDisplay:YES];
}

- (void)resetView:(id)sender
{
    [self scaleToFit];
    [self setRotation:0.f];
    [self setWLWW:[[self curDCM] savedWL] :[[self curDCM] savedWW]];
}

- (void)selectView
{
    self.isSelected = !isSelected;
    self.isGoingToBeSelected = NO;
    [self setNeedsDisplay:YES];
}


#pragma mark-Events handling

- (void)keyDown:(NSEvent *)event
{
    if ([[event characters] length] == 0)
        return;
    
    unichar key = [event.characters characterAtIndex:0];
    
    switch (key)
    {
        // Seems not to be used
        case NSF1FunctionKey:
        case NSF2FunctionKey:
        case NSF3FunctionKey:
        case NSPageUpFunctionKey:
        case NSUpArrowFunctionKey:
        case NSLeftArrowFunctionKey:
        case NSPageDownFunctionKey:
        case NSDownArrowFunctionKey:
        case NSRightArrowFunctionKey:
        case NSHomeFunctionKey:
        case NSEndFunctionKey:
            [self.superview.superview keyDown:event];
            break;

        // Prevent annotation type to be changed in a key/selected thumbnail
        case NSTabCharacter:
            break;
            
        default:
            [super keyDown:event];
            break;
    }
}

// Prepare the possibility of selecting an image with the contextual menu
- (void) rightMouseDown:(NSEvent *)event
{
    self.isGoingToBeSelected = YES;
}

// Action on right mouse button up
- (void) rightMouseUp:(NSEvent *)event
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    
    if (isGoingToBeSelected && NSPointInRect(p, self.bounds))
    {
        if (curDCM)
        {
            NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
            [theMenu insertItemWithTitle:@"Delete"      	action:@selector(clearView)     keyEquivalent:@"" atIndex:0];
            [theMenu insertItemWithTitle:@"Reset"       	action:@selector(resetView:)    keyEquivalent:@"" atIndex:1];
            [theMenu insertItemWithTitle:@"Rescale"         action:@selector(scaleToFit)    keyEquivalent:@"" atIndex:2];
            
            if (isSelected)
                [theMenu insertItemWithTitle:@"Deselect"    action:@selector(selectView)    keyEquivalent:@"" atIndex:3];
            else
                [theMenu insertItemWithTitle:@"Select"      action:@selector(selectView)    keyEquivalent:@"" atIndex:3];
            
//            [theMenu insertItemWithTitle:@"Insert Page"     action:@selector(insertPage)    keyEquivalent:@"" atIndex:4];
            
            [NSMenu popUpContextMenu:theMenu withEvent:event forView:self];
            [theMenu release];
        }
        else
            [self selectView];
    }
    [self setNeedsDisplay:YES];
}

// Force the scroll to be handled by the layout view
- (void)scrollWheel:(NSEvent *)event
{
    [[self superview] scrollWheel:event];
}

- (void)mouseDown:(NSEvent *)event
{
    PLLayoutView *parentView = (PLLayoutView *)[self superview];
    
    // Tell the layout view that the current thumbnail is the one dragged
    [parentView setDraggedThumbnailIndex:layoutIndex];
    
//    if ([event type] == NSLeftMouseDown && [event clickCount] == 2)
//        [super startDrag:nil];
//    else
        [super mouseDown:event];
}

@end



















































