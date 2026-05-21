.PHONY: help run run-release test analyze format gen gen-watch clean build-ios pods

# Use FVM-pinned Flutter for all commands.
FLUTTER := fvm flutter
DART    := fvm dart

# Compile-time env. Override on the command line:
#   make run OPENAI_API_KEY=sk-...
OPENAI_API_KEY ?=
DEFINES := --dart-define=OPENAI_API_KEY=$(OPENAI_API_KEY)

help:
	@echo "Targets:"
	@echo "  make run                 — run iOS sim (debug)"
	@echo "  make run-release         — run iOS sim (release, for demo recording)"
	@echo "  make test                — flutter test"
	@echo "  make analyze             — flutter analyze"
	@echo "  make format              — dart format ."
	@echo "  make gen                 — codegen (freezed / json / riverpod)"
	@echo "  make gen-watch           — codegen in watch mode"
	@echo "  make pods                — pod install in ios/"
	@echo "  make build-ios           — release iOS build (no codesign)"
	@echo "  make clean               — flutter clean + codegen artifacts"

run:
	$(FLUTTER) run $(DEFINES)

run-release:
	$(FLUTTER) run --release $(DEFINES)

test:
	$(FLUTTER) test

analyze:
	$(FLUTTER) analyze

format:
	$(DART) format .

gen:
	$(DART) run build_runner build --delete-conflicting-outputs

gen-watch:
	$(DART) run build_runner watch --delete-conflicting-outputs

pods:
	cd ios && pod install

build-ios:
	$(FLUTTER) build ios --release --no-codesign $(DEFINES)

clean:
	$(FLUTTER) clean
	find . -name '*.g.dart' -delete
	find . -name '*.freezed.dart' -delete
