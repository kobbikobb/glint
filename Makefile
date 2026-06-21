APP_NAME = Glint
BUILD_DIR = .build/arm64-apple-macosx/debug
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app

build:
	swift build

test:
	swift test

clean:
	swift package clean

run:
	swift run

bundle: build
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	cp Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	@echo "Bundle created at $(APP_BUNDLE)"
	@open "$(APP_BUNDLE)"

lint:
	swiftlint --strict

format:
	swift-format format --in-place --recursive Sources Tests

lint-format:
	swift-format lint --recursive Sources Tests

check-guardrails:
	scripts/check-guardrails.sh

check-deadcode:
	periphery scan

.PHONY: build test clean run bundle lint format lint-format check-guardrails check-deadcode
