PROJECT := SmartMenu.xcodeproj
SCHEME := SmartMenu
CONFIGURATION ?= Release
DESTINATION := platform=macOS
DERIVED_DATA := build/DerivedData
APP := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/SmartMenu.app

.PHONY: build run install test clean

build:
	xcodebuild build -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

run: build
	open $(APP)

install: build
	cp -R $(APP) /Applications/
	open /Applications/SmartMenu.app

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

clean:
	rm -rf build
