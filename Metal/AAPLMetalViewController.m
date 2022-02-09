/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller that displays Metal content.
*/

#import "AAPLMetalViewController.h"
#import "AAPLMetalRenderer.h"

@implementation AAPLMetalViewController
{
    MTKView *_view;

    AAPLMetalRenderer *_renderer;
}

static id<MTLDevice> FindIntelGPU()
{
    for (id<MTLDevice> dev in MTLCopyAllDevices()) {
        if ([[dev name] containsString:@"Intel"])
            return dev;
    }
    fprintf(stderr, "Could not find Intel GPU!");
    abort();
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set the view to use the default device.
    _view = (MTKView *)self.view;
    _view.device = FindIntelGPU();

    if(!_view.device)
    {
        assert(!"Metal is not supported on this device.");
        return;
    }

    _renderer = [[AAPLMetalRenderer alloc] initWithMetalKitView:_view];

    if(!_renderer)
    {
        assert(!"Renderer failed initialization.");
        return;
    }

    // Initialize renderer with the view size.
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    _view.delegate = _renderer;
}

@end
