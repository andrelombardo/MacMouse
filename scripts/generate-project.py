#!/usr/bin/env python3
"""Generate the dependency-free Xcode project deterministically from local sources."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent.parent
objects = {}

def uid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()

def add(identity, isa, **fields):
    key = uid(identity)
    objects[key] = dict(isa=isa, **fields)
    return key

def ref(name):
    return uid(name)

def file(path, file_type, tree="SOURCE_ROOT"):
    return add("file:" + path, "PBXFileReference", lastKnownFileType=file_type, path=path, sourceTree=tree)

app_sources = sorted(p.relative_to(root).as_posix() for folder in ["Sources/MacMouse", "Sources/MacMouseCore"] for p in (root / folder).rglob("*.swift"))
source_refs = [file(p, "sourcecode.swift") for p in app_sources]
source_builds = [add("build:" + p, "PBXBuildFile", fileRef=r) for p, r in zip(app_sources, source_refs)]
assets = file("Sources/MacMouse/Resources/Assets.xcassets", "folder.assetcatalog")
info = file("Sources/MacMouse/Resources/Info.plist", "text.plist.xml")
package = file("Package.swift", "sourcecode.swift")
readme = file("README.md", "net.daringfireball.markdown")
tests = [file(p.relative_to(root).as_posix(), "sourcecode.swift") for p in sorted((root / "Tests").rglob("*.swift"))]
product = add("product", "PBXFileReference", explicitFileType="wrapper.application", path="MacMouse.app", sourceTree="BUILT_PRODUCTS_DIR")
sources_phase = add("sources", "PBXSourcesBuildPhase", buildActionMask=2147483647, files=source_builds, runOnlyForDeploymentPostprocessing=0)
resources_phase = add("resources", "PBXResourcesBuildPhase", buildActionMask=2147483647, files=[add("assets-build", "PBXBuildFile", fileRef=assets)], runOnlyForDeploymentPostprocessing=0)
frameworks_phase = add("frameworks", "PBXFrameworksBuildPhase", buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0)
sources_group = add("source-group", "PBXGroup", children=source_refs + [assets, info], name="Sorgenti", sourceTree="<group>")
tests_group = add("tests-group", "PBXGroup", children=tests, name="Test (swift test)", sourceTree="<group>")
products_group = add("products", "PBXGroup", children=[product], name="Products", sourceTree="<group>")
main = add("main", "PBXGroup", children=[sources_group, tests_group, package, readme, products_group], sourceTree="<group>")
project_configs, target_configs = [], []
for config in ["Debug", "Release"]:
    project_configs.append(add("project-" + config, "XCBuildConfiguration", name=config, buildSettings={
        "SDKROOT": "macosx", "MACOSX_DEPLOYMENT_TARGET": "27.0", "SWIFT_VERSION": "6.0",
        "CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone" if config == "Debug" else "-O",
        "SWIFT_COMPILATION_MODE": "singlefile" if config == "Debug" else "wholemodule",
        "DEBUG_INFORMATION_FORMAT": "dwarf" if config == "Debug" else "dwarf-with-dsym",
        "ENABLE_TESTABILITY": "YES" if config == "Debug" else "NO",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG" if config == "Debug" else "",
    }))
    target_configs.append(add("target-" + config, "XCBuildConfiguration", name=config, buildSettings={
        "PRODUCT_BUNDLE_IDENTIFIER": "com.andrelombardo.MacMouse", "PRODUCT_NAME": "MacMouse",
        "INFOPLIST_FILE": "Sources/MacMouse/Resources/Info.plist", "GENERATE_INFOPLIST_FILE": "NO",
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon", "CODE_SIGN_STYLE": "Automatic",
        "CODE_SIGN_IDENTITY": "-", "ENABLE_HARDENED_RUNTIME": "YES", "ENABLE_APP_SANDBOX": "NO",
        "ARCHS": "arm64", "ONLY_ACTIVE_ARCH": "YES", "COMBINE_HIDPI_IMAGES": "YES",
        "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/../Frameworks",
    }))
project_list = add("project-list", "XCConfigurationList", buildConfigurations=project_configs, defaultConfigurationIsVisible=0, defaultConfigurationName="Release")
target_list = add("target-list", "XCConfigurationList", buildConfigurations=target_configs, defaultConfigurationIsVisible=0, defaultConfigurationName="Release")
target = add("app-target", "PBXNativeTarget", buildConfigurationList=target_list, buildPhases=[sources_phase, frameworks_phase, resources_phase], buildRules=[], dependencies=[], name="MacMouse", productName="MacMouse", productReference=product, productType="com.apple.product-type.application")
project = add("project", "PBXProject", attributes={"BuildIndependentTargetsInParallel": "YES", "LastUpgradeCheck": "2700"}, buildConfigurationList=project_list, compatibilityVersion="Xcode 14.0", developmentRegion="it", hasScannedForEncodings=0, knownRegions=["it", "en", "Base"], mainGroup=main, productRefGroup=products_group, projectDirPath="", projectRoot="", targets=[target])

def encode(value, indent=0):
    if isinstance(value, dict):
        return "{\n" + "".join("\t" * (indent+1) + json.dumps(str(k)) + " = " + encode(v, indent+1) + ";\n" for k, v in value.items()) + "\t" * indent + "}"
    if isinstance(value, list):
        return "(" + ", ".join(encode(v, indent) for v in value) + ")"
    if isinstance(value, int):
        return str(value)
    return json.dumps(value, ensure_ascii=False)

document = {"archiveVersion": 1, "classes": {}, "objectVersion": 56, "objects": objects, "rootObject": project}
folder = root / "MacMouse.xcodeproj"
folder.mkdir(exist_ok=True)
(folder / "project.pbxproj").write_text("// !$*UTF8*$!\n" + encode(document) + "\n")
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
    <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="MacMouse.app" BlueprintName="MacMouse" ReferencedContainer="container:MacMouse.xcodeproj"/>
    </BuildActionEntry>
  </BuildActionEntries></BuildAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="NO">
    <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="MacMouse.app" BlueprintName="MacMouse" ReferencedContainer="container:MacMouse.xcodeproj"/></BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
    <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="MacMouse.app" BlueprintName="MacMouse" ReferencedContainer="container:MacMouse.xcodeproj"/></BuildableProductRunnable>
  </ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
scheme_dir = folder / "xcshareddata/xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
(scheme_dir / "MacMouse.xcscheme").write_text(scheme)
