--[[
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
--]]


--[[
		* Need help with the KKStartupConfig settings?
		* ------ http://www.kobold2d.com/x/ygMO ------
--]]


local config =
{
	KKStartupConfig = 
	{
		-- load first scene from a class with this name, or from a Lua script with this name with .lua appended
		FirstSceneClassName = "MSLogoLayer",

		MaxFrameRate = 30,
		DisplayFPS = YES,

		EnableUserInteraction = YES,
		EnableMultiTouch = YES,

		-- Render settings
		DefaultTexturePixelFormat = TexturePixelFormat.RGBA8888,
		GLViewColorFormat = GLViewColorFormat.RGB565,
		GLViewDepthFormat = GLViewDepthFormat.DepthNone,
		GLViewMultiSampling = NO,
		GLViewNumberOfSamples = 0,

		Enable2DProjection = NO,
		EnableRetinaDisplaySupport = YES,
		EnableGLViewNodeHitTesting = NO,
		EnableStatusBar = NO,

		-- Orientation & Autorotation
		-- Kobold2D uses the supported orientations from the Target's Summary pane: http://cl.ly/2l132Z2f463H2O3r0M1O
		-- (same as Info.plist key UISupportedInterfaceOrientations aka "Supported interface orientations")
	
		-- iAd setup
		EnableAdBanner = NO,
		PlaceBannerOnBottom = NO,
		LoadOnlyPortraitBanners = NO,
		LoadOnlyLandscapeBanners = NO,
		AdProviders = "iAd, AdMob",	-- comma seperated list -> "iAd, AdMob" means: use iAd if available, otherwise AdMob
		AdMobRefreshRate = 15,
		AdMobFirstAdDelay = 5,
		AdMobPublisherID = "YOUR_ADMOB_PUBLISHER_ID", -- how to get an AdMob Publisher ID: http://developer.admob.com/wiki/PublisherSetup
		AdMobTestMode = YES,

		-- Mac OS specific settings
		AutoScale = NO,
		AcceptsMouseMovedEvents = NO,
		EnableFullScreen = NO,
	},
  Margin = 28,
  RailWidth = 88,
  LineWidth = 320,
  ClientSight = 8,
  ServerSight = 16,
  ScrollSpeed = 10,
  RockAndCoinWidth = 88,
  MusicVolume = 0.6,
  HighScoreKey = "HighScore",
  MatchFontSizePhone = 9.0,
  MatchFontSizePad = 16,
  MatchStateFontSizePhone = 12.0,
  MatchStateFontSizePad = 24.0
}

return config
