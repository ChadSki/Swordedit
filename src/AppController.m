//
//  AppController.m
//  swordedit
//
//  Created by sword on 10/21/07.
//  Copyright 2007 sword Inc. All rights reserved.
//
//	sword@clanhalo.net
//

#import "AppController.h"
#import "AboutBox.h"

#import "RenderView.h"
#import "BitmapView.h"
#import "SpawnEditorController.h"

void authMe(char * FullPathToMe)
{
	// get authorization as root
	
	OSStatus myStatus;
	
	// set up Authorization Item
	AuthorizationItem myItems[1];
	myItems[0].name = kAuthorizationRightExecute;
	myItems[0].valueLength = 0;
	myItems[0].value = NULL;
	myItems[0].flags = 0;
	
	// Set up Authorization Rights
	AuthorizationRights myRights;
	myRights.count = sizeof (myItems) / sizeof (myItems[0]);
	myRights.items = myItems;
	
	// set up Authorization Flags
	AuthorizationFlags myFlags;
	myFlags =
	kAuthorizationFlagDefaults |
	kAuthorizationFlagInteractionAllowed |
	kAuthorizationFlagExtendRights;
	
	// Create an Authorization Ref using Objects above. NOTE: Login bod comes up with this call.
	AuthorizationRef myAuthorizationRef;
	myStatus = AuthorizationCreate (&myRights, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
	
	if (myStatus == errAuthorizationSuccess)
	{
		// prepare communication path - used to signal that process is loaded
		FILE *myCommunicationsPipe = NULL;
		char myReadBuffer[] = " ";
		
		// run this app in GOD mode by passing authorization ref and comm pipe (asynchoronous call to external application)
		myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef,FullPathToMe,kAuthorizationFlagDefaults,nil,&myCommunicationsPipe);
		
		// external app is running asynchronously - it will send to stdout when loaded
		if (myStatus == errAuthorizationSuccess)
		{
			read (fileno (myCommunicationsPipe), myReadBuffer, sizeof (myReadBuffer));
			fclose(myCommunicationsPipe);
		}
		
		// release authorization reference
		myStatus = AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDestroyRights);
	}
}

bool checkExecutablePermissions(void)
{
	NSDictionary	*applicationAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[[NSBundle mainBundle] executablePath] traverseLink: YES];
	
	// We expect 2755 as octal (1517 as decimal, -rwxr-sr-x as extended notation)
	return ([applicationAttributes filePosixPermissions] == 1517 && [[applicationAttributes fileGroupOwnerAccountName] isEqualToString: @"procmod"]);
}

bool amIWorthy(void)
{
	// running as root?
	AuthorizationRef myAuthRef;
	OSStatus stat = AuthorizationCopyPrivilegedReference(&myAuthRef,kAuthorizationFlagDefaults);
	
	return stat == errAuthorizationSuccess || checkExecutablePermissions();
}

@implementation AppController
+ (void)aMethod:(id)param
{
	//int x;
	//for (x = 0; x < 50; x++)
	//{
	//	printf("Object thread says x is %i\n", x);
	//	usleep(1);
	//}
}


-(void)LoadMaps:(NSTimer *)t
{
	[self OpenMap:[t userInfo]];
}

-(int)PID
{
	return haloProcessID;
}

- (void)assignHaloProcessIDFromApplicationDictionary:(NSDictionary *)applicationDictionary
{
	if ([[applicationDictionary objectForKey:@"NSApplicationName"] rangeOfString:@"Halo Demo"
																		 options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		haloProcessID = [[applicationDictionary objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		NSLog(@"HALO MESSAGE");
		NSLog(@"HALO PID %d", haloProcessID);
	}
	else
	{
		
	}

}


- (void)awakeFromNib
{
	//Set the process ID
	haloProcessID = 0;
	
	BOOL needsAuthorizationCheck = YES;
	
	if (needsAuthorizationCheck)
	{

			// when the app restarts from asking the user his adminstator's password, the app isn't activated for some reason, so we'll activate it
			//[NSApp activateIgnoringOtherApps:YES];
		
	[NSApp setDelegate:self];
	
	/* Beta experation code */
	NSString *nowString = [NSString stringWithUTF8String:__DATE__];
	NSCalendarDate *nowDate = [NSCalendarDate dateWithNaturalLanguageString:nowString];
	NSCalendarDate *expireDate = [nowDate addTimeInterval:(60 * 60 * 24 * 10)];
	
	/*if ([expireDate earlierDate:[NSDate date]] == expireDate)
	{
		NSRunAlertPanel(@"Beta Expired!",@"Your swordedit beta has expired!",@"Oh woes me!", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	}
	else
	{
		NSRunAlertPanel(@"Welcome to the beta.", [[NSString stringWithString:@"swordedit beta expires on "] stringByAppendingString:[expireDate description]], @"I feel blessed!", nil, nil);
	}*/
	/* End beta experation code */
	
	userDefaults = [NSUserDefaults standardUserDefaults];
	
	[self loadPrefs];
	
	if (!bitmapFilePath)
	{
		[self selectBitmapLocation];
	}
	
	[mainWindow makeKeyAndOrderFront:self];
	//[mainWindow center];
	
	NSString *autoa = [NSString stringWithContentsOfFile:@"/tmp/starlight.auto"];
	if (autoa)
	{
		
		NSArray *settings = [autoa componentsSeparatedByString:@","];
		NSString *pat = [settings objectAtIndex:0];
		if ([[NSFileManager defaultManager] fileExistsAtPath:pat])
		{
			//[selecte center];
			//[selecte makeKeyAndOrderFront:nil];
			
			[[NSApplication sharedApplication] beginSheet:selecte modalForWindow:[rendView window] modalDelegate:self didEndSelector:nil contextInfo:self];
			
			
			[tpro setUsesThreadedAnimation:YES];
			[tpro startAnimation:nil];

		
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(LoadMaps:) userInfo:pat repeats:NO];
		
		}
	}
	}
}

-(void)OpenMap:(NSString *)t
{
	switch ([self loadMapFile:t])
	{
			
		case 0:
#ifdef __DEBUG__
			NSLog(@"Loaded!");
			NSLog(@"Setting renderview map objects...");
#endif
		
			[mainWindow makeKeyAndOrderFront:self];
			
			
			NSDate* startTime = [NSDate date];
			[rendView setPID:[self PID]];
			[rendView setMapObject:mapfile];
			[bitmapView setMapfile:mapfile];
			[spawnEditor setMapFile:mapfile];
			
			[selecte orderOut:nil];
			[NSApp endSheet:selecte];
			
			[tpro stopAnimation:self];
			
#ifdef __DEBUG__
			NSDate *endDate = [NSDate date];
			NSLog(@"Load duration: %f seconds", [endDate timeIntervalSinceDate:startTime]);
#endif
			break;
		case 1:
			break;
		case 2:
			NSLog(@"The map name is invalid!");
			break;
		case 3:
			NSLog(@"Could not open the map!");
			break;
		default:
			break;
	}
	[mainWindow setTitle:[[NSString stringWithString:@"starlight : "] stringByAppendingString:[mapfile mapName]]];
}

- (IBAction)loadMap:(id)sender
{
	NSOpenPanel *open = [NSOpenPanel openPanel];
	
	if ([open runModalForTypes:[NSArray arrayWithObjects:@"map", nil]] == NSOKButton)
	{
		[[NSApplication sharedApplication] beginSheet:selecte modalForWindow:[rendView window] modalDelegate:self didEndSelector:nil contextInfo:self];
		
		[tpro setUsesThreadedAnimation:YES];
		[tpro startAnimation:nil];
		
		#ifdef __DEBUG__
		printf("\n");
		NSLog(@"==============================================================================");
		NSDate *startTime = [NSDate date];
		NSLog([open filename]);
		NSLog(bitmapFilePath);
		#endif
		
		[opened setStringValue:[open filename]];

		
		[self OpenMap:[open filename]];
		
	}
	else {
		[selecte orderOut:nil];
		[NSApp endSheet:selecte];
	}

	
}
-(int)usesColor
{
	if ([color state])
	{
		return 4;
	}
	
	return 2;
}

- (IBAction)saveFile:(id)sender
{
	if (!mapfile)
	{
		NSRunAlertPanel(@"Error!",@"No mapfile currently open!", @"Ok", nil,nil);
		return;
	}
	if ((NSRunAlertPanel(@"Saving...", @"Are you sure you want to save?",@"Yes",@"No",nil)) == 1)
	{
		// do whatever the fuck you want
		[mapfile saveMap];
		
		//Restart map
		
		//Get camera positions
		
		float* pos = [rendView getCameraPos];
		float* view = [rendView getCameraView];
		
		[mapfile closeMap];

		[[NSString stringWithFormat:@"%@, %f, %f, %f, %f, %f, %f", [opened stringValue], pos[0],pos[1],pos[2], view[0],view[1],view[2]]  writeToFile:@"/tmp/starlight.auto" atomically:YES];
		
		//RElaunch
		
		NSString *relaunch = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"relaunch"];
		int procid = [[NSProcessInfo processInfo] processIdentifier];
		[NSTask launchedTaskWithLaunchPath:relaunch arguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] bundlePath], [NSString stringWithFormat:@"%d",procid], nil]];
		[NSApp terminate:NULL];
		
		///[self loadMapFile:opened];
	}
}
- (IBAction)close:(id)sender
{
	#ifdef __DEBUG__
	NSLog(@"Closing!");
	#endif
	if (sender == mainWindow)
	{
		[self closeMapFile];
	}
	else if (sender == prefsWindow)
	{
		#ifdef __DEBUG__
		NSLog(@"Closing prefs!");
		#endif
		[prefsWindow performClose:sender];
	}
}
- (IBAction)showAboutBox:(id)sender
{
	[[AboutBox sharedInstance] showPanel:sender];
}
- (int)loadMapFile:(NSString *)location
{
	[opened setStringValue:location];
	
	[self closeMapFile];
	mapfile = [[HaloMap alloc] initWithMapfiles:location bitmaps:bitmapFilePath];
	return [mapfile loadMap];
}
- (void)closeMapFile
{
	[rendView stopDrawing];
	if (mapfile)
	{
		[rendView releaseMapObjects];
		[bitmapView releaseAllObjects];
		[spawnEditor destroyAllMapObjects];
		[mapfile destroy];
		[mapfile release];
	}
}
- (void)loadPrefs
{
	firstTime = [userDefaults boolForKey:@"_firstTimeUse"];
	
	bitmapFilePath = [[userDefaults stringForKey:@"bitmapFileLocation"] retain];
	
	if (bitmapFilePath)
		[bitmapLocationText setStringValue:bitmapFilePath];
		
	// Heh, here's a logical fucker. When firstTime = FALSE, its the first time the program has been run.
	if (!firstTime)
	{
		[self runIntroShit];
	}
}
- (void)runIntroShit
{
	/*NSSound *genesis = [[NSSound alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Genesis.mp3"] byReference:NO];
	[genesis setDelegate:self];
	[genesis play];*/
	NSRunAlertPanel(@"Starlight",@"Welcome to starlight. Before you can begin, you must first setup the program.",@"Continue",nil,nil);
	NSRunAlertPanel(@"Halo Bitmap",@"You'll be asked to specify the location of the bitmaps file you wish to use in just a moment.",@"Locate...",nil,nil);
	[self selectBitmapLocation];
	[bitmapLocationText setStringValue:bitmapFilePath];
	switch (NSRunAlertPanel(@"Transparencies",@"Would you like transparencies to be rendered?",@"Yes",@"No",nil))
	{
		case NSAlertDefaultReturn:
			[userDefaults setBool:YES forKey:@"_useAlphas"];
			break;
		case NSAlertAlternateReturn:
			[userDefaults setBool:NO forKey:@"_useAlphas"];
			break;
	}
	switch (NSRunAlertPanel(@"Detail Level",@"Please select your detail level",@"High",@"Medium",@"Low"))
	{
		case NSAlertDefaultReturn:
			[userDefaults setInteger:2 forKey:@"_LOD"];
			break;
		case NSAlertAlternateReturn:
			[userDefaults setInteger:1 forKey:@"_LOD"];
			break;
		case NSAlertOtherReturn:
			[userDefaults setInteger:0 forKey:@"_LOD"];
			break;
	}
	NSRunAlertPanel(@"Setup Complete!",@"You may change all of these settings in the Rendering panel at a later date",@"Finish",nil,nil);
	[userDefaults setBool:TRUE forKey:@"_firstTimeUse"];
	[userDefaults synchronize];
	[rendView loadPrefs];
}
- (BOOL)selectBitmapLocation
{
	NSOpenPanel *open = [NSOpenPanel openPanel];
	[open setTitle:@"Please select the bitmap file you wish to use."];
	if ([open runModalForTypes:[NSArray arrayWithObjects:@"map", nil]] == NSOKButton)
	{
		bitmapFilePath = [open filename];
		//NSLog(@"Bitmap file path: %@", bitmapFilePath);
		[userDefaults setObject:bitmapFilePath forKey:@"bitmapFileLocation"];
		[userDefaults synchronize];
		return TRUE;
	}
	else
	{
		bitmapFilePath = @"";
	}
	return FALSE;
}
- (IBAction)setNewBitmaps:(id)sender
{
	if ([self selectBitmapLocation])
	{
		[bitmapLocationText setStringValue:bitmapFilePath];
		if (mapfile)
		{
			[NSThread detachNewThreadSelector:@selector(aMethod:) toTarget:[AppController class] withObject:nil];
			switch ([self loadMapFile:[mapfile mapLocation]])
			{
				case 0:
					#ifdef __DEBUG__
					NSLog(@"Loaded!");
					NSLog(@"Setting renderview map objects...");
					#endif
					[rendView setMapObject:mapfile];
					[bitmapView setMapfile:mapfile];
					[spawnEditor setMapFile:mapfile];
					break;
				case 1:
					break;
				case 2:
					NSRunAlertPanel(@"OH SHIT",@"The map name is invalid!",@"OK SIR",nil,nil);
					#ifdef __DEBUG__
					NSLog(@"The map name is invalid!");
					#endif
					break;
				case 3:
					NSRunAlertPanel(@"OH SHIT",@"Could not open the map! What did you fuck up?!?!?!?",@"OH GOD, I'M SORRY!",nil,nil);
					#ifdef __DEBUG__
					NSLog(@"Could not open the map!");
					#endif
					break;
				default:
					break;
			}
		}
	}
}

-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if ([tabView indexOfTabViewItem:tabViewItem] > 0)
	{
		[rendView stopDrawing];
	}
	else if ([tabView indexOfTabViewItem:tabViewItem] == 0)
	{
		[rendView resetTimerWithClassVariable];
	}
}
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying
{
	NSLog(@"Sound released!");
	[sound release];
}
@end
