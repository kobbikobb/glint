build:
	swift build

test:
	swift test

clean:
	swift package clean

run:
	swift run

lint:
	swiftlint --strict

format:
	swift-format format --in-place --recursive Sources Tests

lint-format:
	swift-format lint --recursive Sources Tests

.PHONY: build test clean run lint format lint-format
