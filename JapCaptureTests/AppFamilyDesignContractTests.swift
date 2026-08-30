import AppFamilyDesign
import Foundation
import SwiftUI
import UIKit
import XCTest

@MainActor
final class AppFamilyDesignContractTests: XCTestCase {
    func testProjectLinksOnlyIntendedLocalAppFamilyProducts() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let project = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("JapCapture.xcodeproj/project.pbxproj"),
            encoding: .utf8
        )
        let manifest = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("Packages/AppFamilyFoundation/Package.swift"),
            encoding: .utf8
        )

        assertAppFamilyPackageBoundary(project: project, manifest: manifest)
    }

    func testProjectBoundaryAllowsUnrelatedPackageReferencesAndCommentedManifestExample() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let project = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("JapCapture.xcodeproj/project.pbxproj"),
            encoding: .utf8
        )
        let manifest = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("Packages/AppFamilyFoundation/Package.swift"),
            encoding: .utf8
        )
        let unrelatedProductID = "E20000102FA000010045C314"
        let unrelatedLocalID = "E200000F2FA000010045C314"
        let unrelatedRemoteID = "E200000E2FA000010045C314"
        let projectWithUnrelatedReferences = project
            .replacingOccurrences(
                of: "\t\t\t\tF10000102FA000010045C314 /* AppFamilyDesign */,\n\t\t\t);",
                with: """
                \t\t\t\tF10000102FA000010045C314 /* AppFamilyDesign */,
                \t\t\t\t\(unrelatedProductID) /* UnrelatedProduct */,
                \t\t\t);
                """
            )
            .replacingOccurrences(
                of: "\t\t\t\tF10000122FA000010045C314 /* AppFamilyLocalizationQA */,\n\t\t\t);",
                with: """
                \t\t\t\tF10000122FA000010045C314 /* AppFamilyLocalizationQA */,
                \t\t\t\t\(unrelatedProductID) /* UnrelatedProduct */,
                \t\t\t);
                """
            )
            .replacingOccurrences(
                of: "/* End XCLocalSwiftPackageReference section */",
                with: """
                \t\t\(unrelatedLocalID) /* XCLocalSwiftPackageReference "Packages/Unrelated" */ = {
                \t\t\tisa = XCLocalSwiftPackageReference;
                \t\t\trelativePath = Packages/Unrelated;
                \t\t};
                /* End XCLocalSwiftPackageReference section */
                """
            )
            .replacingOccurrences(
                of: "/* Begin XCSwiftPackageProductDependency section */",
                with: """
                /* Begin XCRemoteSwiftPackageReference section */
                \t\t\(unrelatedRemoteID) /* XCRemoteSwiftPackageReference "Unrelated" */ = {
                \t\t\tisa = XCRemoteSwiftPackageReference;
                \t\t\trepositoryURL = "https://example.com/unrelated.git";
                \t\t};
                /* End XCRemoteSwiftPackageReference section */

                /* Begin XCSwiftPackageProductDependency section */
                """
            )
            .replacingOccurrences(
                of: "/* End XCSwiftPackageProductDependency section */",
                with: """
                \t\t\(unrelatedProductID) /* UnrelatedProduct */ = {
                \t\t\tisa = XCSwiftPackageProductDependency;
                \t\t\tproductName = UnrelatedProduct;
                \t\t};
                /* End XCSwiftPackageProductDependency section */
                """
            )

        let fixtureModel = try AppFamilyProjectModel(
            project: projectWithUnrelatedReferences
        )
        XCTAssertTrue(
            fixtureModel.packageProductsByTarget["JapCapture"]?
                .contains("UnrelatedProduct") == true
        )
        XCTAssertTrue(
            fixtureModel.packageProductsByTarget["JapCaptureTests"]?
                .contains("UnrelatedProduct") == true
        )
        XCTAssertTrue(
            fixtureModel.localPackagePaths.contains("Packages/Unrelated")
        )
        XCTAssertTrue(projectWithUnrelatedReferences.contains(unrelatedRemoteID))

        assertAppFamilyPackageBoundary(
            project: projectWithUnrelatedReferences,
            manifest: "// .package(url: \"https://example.com/ignored.git\")\n\(manifest)"
        )
    }

    func testProjectBoundaryRejectsAppLocalizationAndDuplicateFoundationReference() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let project = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("JapCapture.xcodeproj/project.pbxproj"),
            encoding: .utf8
        )
        let manifest = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("Packages/AppFamilyFoundation/Package.swift"),
            encoding: .utf8
        )
        let duplicateReferenceID = "E300000F2FA000010045C314"
        let invalidProject = project
            .replacingOccurrences(
                of: "\t\t\t\tF10000102FA000010045C314 /* AppFamilyDesign */,\n\t\t\t);",
                with: """
                \t\t\t\tF10000102FA000010045C314 /* AppFamilyDesign */,
                \t\t\t\tF10000122FA000010045C314 /* AppFamilyLocalizationQA */,
                \t\t\t);
                """
            )
            .replacingOccurrences(
                of: "/* End XCLocalSwiftPackageReference section */",
                with: """
                \t\t\(duplicateReferenceID) /* XCLocalSwiftPackageReference "Packages/AppFamilyFoundation" */ = {
                \t\t\tisa = XCLocalSwiftPackageReference;
                \t\t\trelativePath = Packages/AppFamilyFoundation;
                \t\t};
                /* End XCLocalSwiftPackageReference section */
                """
            )

        let issues = appFamilyPackageBoundaryIssues(
            project: invalidProject,
            manifest: manifest
        )

        XCTAssertTrue(
            issues.contains {
                $0.contains("target=JapCapture")
                    && $0.contains("forbidden=AppFamilyLocalizationQA")
            },
            "Expected app LocalizationQA violation, got \(issues)"
        )
        XCTAssertTrue(
            issues.contains {
                $0.contains("Packages/AppFamilyFoundation")
                    && $0.contains("actual=2")
            },
            "Expected duplicate Foundation reference violation, got \(issues)"
        )
    }

    func testFoundationManifestDependencyScanIgnoresCommentsAndFindsRealDependency() {
        let commentsOnly = """
        // .package(url: "https://example.com/line-comment.git")
        /*
          .package (
            url: "https://example.com/block-comment.git"
          )
        */
        """
        let realDependency = """
        dependencies: [
            .package /* formatting */ (
                url: "https://example.com/real.git",
                from: "1.0.0"
            )
        ]
        """

        XCTAssertEqual(remoteManifestDependencyCount(in: commentsOnly), 0)
        XCTAssertEqual(remoteManifestDependencyCount(in: realDependency), 1)
    }

    func testDefaultFamilyPalettePreservesApprovedDayAndDarkValues() {
        let expected: [(String, FamilyAdaptiveColorToken, String, String)] = [
            ("background", DefaultFamilyPalette.background, "#F8F6F0", "#171A19"),
            ("sectionSurface", DefaultFamilyPalette.sectionSurface, "#ECEAE2", "#272C2A"),
            ("cardSurface", DefaultFamilyPalette.cardSurface, "#FFFDF8", "#222624"),
            ("raisedCardSurface", DefaultFamilyPalette.raisedCardSurface, "#FFFFFF", "#2B302E"),
            ("primaryText", DefaultFamilyPalette.primaryText, "#26302D", "#F1F0EA"),
            ("secondaryText", DefaultFamilyPalette.secondaryText, "#66706B", "#B0B8B3"),
            ("tertiaryText", DefaultFamilyPalette.tertiaryText, "#8A918C", "#89938E"),
            ("contentPrimaryText", DefaultFamilyPalette.contentPrimaryText, "#1F2926", "#F4F3EE"),
            ("primaryAccent", DefaultFamilyPalette.primaryAccent, "#2F5D50", "#8FB3A6"),
            ("primaryAccentDeep", DefaultFamilyPalette.primaryAccentDeep, "#264C42", "#628D7E"),
            ("primaryAccentMuted", DefaultFamilyPalette.primaryAccentMuted, "#D9E5DF", "#34443F"),
            ("secondaryAccent", DefaultFamilyPalette.secondaryAccent, "#D6A84F", "#D7B363"),
            ("secondaryAccentMuted", DefaultFamilyPalette.secondaryAccentMuted, "#F3E4C0", "#4A402A"),
            ("success", DefaultFamilyPalette.success, "#4F7D65", "#86A991"),
            ("warning", DefaultFamilyPalette.warning, "#C6923E", "#D2A24F"),
            ("destructiveMuted", DefaultFamilyPalette.destructiveMuted, "#B85A54", "#D77B73"),
            ("outline", DefaultFamilyPalette.outline, "#ADB3B0", "#65706B")
        ]

        for (name, token, day, dark) in expected {
            XCTAssertEqual(token.day.hexRGB, day, "\(name) Day")
            XCTAssertEqual(token.dark.hexRGB, dark, "\(name) Dark")
        }
    }

    func testAdaptiveTokenResolvesUnspecifiedAppearanceToDay() {
        let token = DefaultFamilyPalette.background
        XCTAssertEqual(token.value(for: .light), token.day)
        XCTAssertEqual(token.value(for: .dark), token.dark)
        XCTAssertEqual(token.value(for: .unspecified), token.day)
    }

    func testAdaptiveUIColorResolvesExplicitLightAndDarkTraits() {
        let token = DefaultFamilyPalette.background
        let light = resolvedToken(from: token.uiColor, interfaceStyle: .light)
        let dark = resolvedToken(from: token.uiColor, interfaceStyle: .dark)

        assertRGBA(light, equals: token.day)
        assertRGBA(dark, equals: token.dark)
        XCTAssertEqual(light.hexRGB, token.day.hexRGB)
        XCTAssertEqual(dark.hexRGB, token.dark.hexRGB)
    }

    func testSharedColorTokenRetainsContrastMath() {
        XCTAssertGreaterThanOrEqual(
            DefaultFamilyPalette.primaryText.day.contrastRatio(
                with: DefaultFamilyPalette.background.day
            ),
            4.5
        )
        XCTAssertGreaterThanOrEqual(
            DefaultFamilyPalette.primaryText.dark.contrastRatio(
                with: DefaultFamilyPalette.background.dark
            ),
            4.5
        )
    }

    func testDefaultThemeConformsToFamilyThemeContract() {
        func acceptsFamilyTheme<T: FamilyTheme>(_: T) {}
        acceptsFamilyTheme(DefaultFamilyTheme())
    }

    func testDefaultThemeUsesNoLineTonalDepthPolicy() {
        let theme = DefaultFamilyTheme()
        XCTAssertFalse(theme.usesExplicitDividersByDefault)
        XCTAssertTrue(theme.prefersTonalLayeringOverShadows)
        XCTAssertFalse(theme.allowsStandardIOSShadows)
        XCTAssertFalse(theme.shouldUseAmbientShadow(for: .base))
        XCTAssertFalse(theme.shouldUseAmbientShadow(for: .section))
        XCTAssertFalse(theme.shouldUseAmbientShadow(for: .card))
        XCTAssertTrue(theme.shouldUseAmbientShadow(for: .elevated))
    }

    func testDefaultThemeSurfaceDepthMappingsResolveApprovedColorsInLightAndDark() {
        let theme = DefaultFamilyTheme()
        let mappings: [(String, FamilySurfaceDepth, FamilyAdaptiveColorToken)] = [
            ("base", .base, DefaultFamilyPalette.background),
            ("section", .section, DefaultFamilyPalette.sectionSurface),
            ("card", .card, DefaultFamilyPalette.cardSurface),
            ("elevated", .elevated, DefaultFamilyPalette.cardSurface)
        ]

        for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            for (name, depth, expected) in mappings {
                assertColor(
                    theme.surfaceColor(for: depth),
                    resolvesTo: expected.value(for: interfaceStyle),
                    interfaceStyle: interfaceStyle,
                    message: "\(name) \(interfaceStyle)"
                )
            }
        }
    }

    func testDefaultThemeRepresentativeRolesResolveApprovedColorsInLightAndDark() {
        let theme = DefaultFamilyTheme()
        let mappings: [(String, Color, FamilyAdaptiveColorToken)] = [
            ("accentPrimaryStrong", theme.accentPrimaryStrong, DefaultFamilyPalette.primaryAccent),
            (
                "accentPrimaryGradientEnd",
                theme.accentPrimaryGradientEnd,
                DefaultFamilyPalette.primaryAccentDeep
            ),
            ("accentPrimarySoft", theme.accentPrimarySoft, DefaultFamilyPalette.primaryAccentMuted),
            (
                "buttonPrimaryGradientStart",
                theme.buttonPrimaryGradientStart,
                DefaultFamilyPalette.primaryAccent
            ),
            (
                "buttonPrimaryGradientEnd",
                theme.buttonPrimaryGradientEnd,
                DefaultFamilyPalette.primaryAccentDeep
            ),
            ("inputFill", theme.inputFill, DefaultFamilyPalette.sectionSurface),
            ("inputForeground", theme.inputForeground, DefaultFamilyPalette.primaryText)
        ]

        for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            for (name, color, expected) in mappings {
                assertColor(
                    color,
                    resolvesTo: expected.value(for: interfaceStyle),
                    interfaceStyle: interfaceStyle,
                    message: "\(name) \(interfaceStyle)"
                )
            }

            let highEmphasis = token(
                DefaultFamilyPalette.primaryAccentMuted.value(for: interfaceStyle),
                withOpacity: 0.72
            )
            assertColor(
                theme.surfaceInteractiveControl,
                resolvesTo: highEmphasis,
                interfaceStyle: interfaceStyle,
                message: "surfaceInteractiveControl \(interfaceStyle)"
            )
            assertColor(
                theme.surfaceHighEmphasis,
                resolvesTo: highEmphasis,
                interfaceStyle: interfaceStyle,
                message: "surfaceHighEmphasis \(interfaceStyle)"
            )
        }
    }

    func testDefaultThemeFixedAndDerivedColorsPreserveApprovedRGBA() {
        let theme = DefaultFamilyTheme()
        let shutterCore = FamilyVisualColorToken(red: 95, green: 103, blue: 105)

        for interfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            assertColor(
                theme.cameraShutterCore,
                resolvesTo: shutterCore,
                interfaceStyle: interfaceStyle,
                message: "cameraShutterCore \(interfaceStyle)"
            )

            let ambientShadow = token(
                DefaultFamilyPalette.primaryAccent.value(for: interfaceStyle),
                withOpacity: 0.08
            )
            assertColor(
                theme.ambientShadowTint,
                resolvesTo: ambientShadow,
                interfaceStyle: interfaceStyle,
                message: "ambientShadowTint \(interfaceStyle)"
            )
        }
    }

    func testFamilyTypographyUsesApprovedTrackingPolicy() {
        XCTAssertEqual(FamilyTypography.displayTracking, 0)
        XCTAssertEqual(FamilyTypography.displayHeroTracking, 0)
        XCTAssertEqual(FamilyTypography.displayMetricTracking, 0)
        XCTAssertEqual(FamilyTypography.headlineTracking, 0)
        XCTAssertEqual(FamilyTypography.labelTracking, 0.8)
        XCTAssertEqual(FamilyTypography.eyebrowTracking, 0.9)
        XCTAssertEqual(FamilyTypography.sectionLabelTracking, 1.1)
    }

    func testContentLineHeightClampsToApprovedRange() {
        XCTAssertEqual(FamilyTypography.contentLineSpacing(for: 20, multiplier: 1.0), 10)
        XCTAssertEqual(FamilyTypography.contentLineSpacing(for: 20, multiplier: 1.6), 12)
        XCTAssertEqual(FamilyTypography.contentLineSpacing(for: 20, multiplier: 2.0), 16)
    }

    func testFamilyRoundedSurfaceRendersFillInsideRoundedBounds() throws {
        let size = CGSize(width: 32, height: 32)
        let pixels = try renderPixels(
            Color.clear
                .frame(width: size.width, height: size.height)
                .familyRoundedSurface(fill: .red, cornerRadius: 10),
            size: size
        )

        XCTAssertEqual(pixels.pixel(x: 0, y: 0).alpha, 0)
        let center = pixels.pixel(x: 16, y: 16)
        XCTAssertGreaterThan(center.alpha, 250)
        XCTAssertGreaterThan(center.red, center.green)
        XCTAssertGreaterThan(center.red, center.blue)
    }

    func testFamilyCircularSurfaceRendersFillInsideCircularBounds() throws {
        let size = CGSize(width: 32, height: 32)
        let pixels = try renderPixels(
            Color.clear
                .frame(width: size.width, height: size.height)
                .familyCircularSurface(fill: .green),
            size: size
        )

        XCTAssertEqual(pixels.pixel(x: 0, y: 0).alpha, 0)
        let center = pixels.pixel(x: 16, y: 16)
        XCTAssertGreaterThan(center.alpha, 250)
        XCTAssertGreaterThan(center.green, center.red)
        XCTAssertGreaterThan(center.green, center.blue)
    }

    func testFamilyCardSurfaceMatchesContinuousRoundedClip() throws {
        let size = CGSize(width: 32, height: 32)
        let actual = try renderPixels(
            Color.clear
                .frame(width: size.width, height: size.height)
                .familyCardSurface(
                    theme: DefaultFamilyTheme(),
                    depth: .card,
                    fill: .blue,
                    cornerRadius: 10
                ),
            size: size
        )
        let expected = try renderPixels(
            Color.clear
                .frame(width: size.width, height: size.height)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)),
            size: size
        )

        XCTAssertEqual(actual.rgba, expected.rgba)
        XCTAssertEqual(actual.pixel(x: 0, y: 0).alpha, 0)
        XCTAssertGreaterThan(actual.pixel(x: 16, y: 16).alpha, 250)
    }

    func testFamilyAmbientDepthOnlyRendersShadowForEnabledDepth() throws {
        let size = CGSize(width: 96, height: 96)
        let coreBounds = CGRect(x: 38, y: 38, width: 20, height: 20)
        let disabled = try renderPixels(
            ambientDepthSample(depth: .card),
            size: size
        )
        let elevated = try renderPixels(
            ambientDepthSample(depth: .elevated),
            size: size
        )

        XCTAssertEqual(disabled.alphaMass(outside: coreBounds), 0)
        XCTAssertGreaterThan(elevated.alphaMass(outside: coreBounds), 0)
    }

    func testFamilyAmbientDepthCustomYOffsetMovesRenderedShadow() throws {
        let size = CGSize(width: 96, height: 96)
        let coreBounds = CGRect(x: 38, y: 38, width: 20, height: 20)
        let defaultOffset = try renderPixels(
            ambientDepthSample(depth: .elevated),
            size: size
        )
        let customOffset = try renderPixels(
            ambientDepthSample(depth: .elevated, yOffset: -12),
            size: size
        )
        let defaultCentroid = try XCTUnwrap(
            defaultOffset.alphaCentroidY(outside: coreBounds)
        )
        let customCentroid = try XCTUnwrap(
            customOffset.alphaCentroidY(outside: coreBounds)
        )

        XCTAssertNotEqual(defaultOffset.rgba, customOffset.rgba)
        XCTAssertGreaterThan(abs(defaultCentroid - customCentroid), 2)
    }

    private func assertAppFamilyPackageBoundary(
        project: String,
        manifest: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let issues = appFamilyPackageBoundaryIssues(
            project: project,
            manifest: manifest
        )
        XCTAssertEqual(
            issues,
            [],
            "App family package boundary violations:\n\(issues.joined(separator: "\n"))",
            file: file,
            line: line
        )
    }

    private func appFamilyPackageBoundaryIssues(
        project: String,
        manifest: String
    ) -> [String] {
        do {
            let model = try AppFamilyProjectModel(project: project)
            var issues = targetPackageProductIssues(
                for: "JapCapture",
                requiring: ["AppFamilyDesign"],
                forbidding: ["AppFamilyLocalizationQA"],
                in: model
            )
            issues.append(
                contentsOf: targetPackageProductIssues(
                    for: "JapCaptureTests",
                    requiring: ["AppFamilyDesign", "AppFamilyLocalizationQA"],
                    forbidding: [],
                    in: model
                )
            )

            let foundationPath = "Packages/AppFamilyFoundation"
            let foundationReferenceCount = model.localPackagePaths
                .filter { $0 == foundationPath }
                .count
            if foundationReferenceCount != 1 {
                issues.append(
                    """
                    local package reference mismatch: path=\(foundationPath) \
                    expected=1 actual=\(foundationReferenceCount) \
                    allPaths=\(model.localPackagePaths)
                    """
                )
            }

            let dependencyCount = remoteManifestDependencyCount(in: manifest)
            if dependencyCount != 0 {
                issues.append(
                    """
                    Package.swift remote dependency count mismatch: expected=0 \
                    actual=\(dependencyCount) pattern=.package(url:
                    """
                )
            }
            return issues.sorted()
        } catch {
            return ["unable to parse target/package references: \(error)"]
        }
    }

    private func targetPackageProductIssues(
        for target: String,
        requiring requiredProducts: Set<String>,
        forbidding forbiddenProducts: Set<String>,
        in model: AppFamilyProjectModel
    ) -> [String] {
        guard let actualProducts = model.packageProductsByTarget[target] else {
            return [
                """
                target package products unavailable: target=\(target) \
                required=\(requiredProducts.sorted()) availableTargets=\
                \(model.packageProductsByTarget.keys.sorted())
                """
            ]
        }

        let actual = Set(actualProducts)
        var issues = requiredProducts.subtracting(actual).sorted().map {
            "target package product missing: target=\(target) required=\($0) actual=\(actual.sorted())"
        }
        issues.append(
            contentsOf: actual.intersection(forbiddenProducts).sorted().map {
                "target package product forbidden: target=\(target) forbidden=\($0) actual=\(actual.sorted())"
            }
        )
        return issues
    }

    private func remoteManifestDependencyCount(in manifest: String) -> Int {
        let codeWithoutComments = swiftSourceRemovingComments(manifest)
        guard let expression = try? NSRegularExpression(
            pattern: #"\.package\s*\(\s*url\s*:"#
        ) else {
            return 0
        }
        return expression.numberOfMatches(
            in: codeWithoutComments,
            range: NSRange(codeWithoutComments.startIndex..., in: codeWithoutComments)
        )
    }

    private func swiftSourceRemovingComments(_ source: String) -> String {
        let bytes = Array(source.utf8)
        var output: [UInt8] = []
        var index = 0

        while index < bytes.count {
            if hasBytePrefix([0x2F, 0x2F], in: bytes, at: index) {
                index += 2
                while index < bytes.count, bytes[index] != 0x0A {
                    index += 1
                }
            } else if hasBytePrefix([0x2F, 0x2A], in: bytes, at: index) {
                index += 2
                var depth = 1
                while index < bytes.count, depth > 0 {
                    if hasBytePrefix([0x2F, 0x2A], in: bytes, at: index) {
                        depth += 1
                        index += 2
                    } else if hasBytePrefix([0x2A, 0x2F], in: bytes, at: index) {
                        depth -= 1
                        index += 2
                    } else {
                        if bytes[index] == 0x0A {
                            output.append(bytes[index])
                        }
                        index += 1
                    }
                }
            } else if bytes[index] == 0x22 {
                copySwiftString(in: bytes, index: &index, output: &output)
            } else {
                output.append(bytes[index])
                index += 1
            }
        }

        return String(decoding: output, as: UTF8.self)
    }

    private func copySwiftString(
        in bytes: [UInt8],
        index: inout Int,
        output: inout [UInt8]
    ) {
        output.append(bytes[index])
        index += 1
        while index < bytes.count {
            let byte = bytes[index]
            output.append(byte)
            index += 1
            if byte == 0x5C, index < bytes.count {
                output.append(bytes[index])
                index += 1
            } else if byte == 0x22 {
                return
            }
        }
    }

    private func hasBytePrefix(
        _ prefix: [UInt8],
        in bytes: [UInt8],
        at index: Int
    ) -> Bool {
        guard index + prefix.count <= bytes.count else {
            return false
        }
        return bytes[index..<(index + prefix.count)].elementsEqual(prefix)
    }

    private func ambientDepthSample(
        depth: FamilySurfaceDepth,
        yOffset: CGFloat? = nil
    ) -> some View {
        Color.white
            .frame(width: 16, height: 16)
            .familyAmbientDepth(
                theme: DefaultFamilyTheme(),
                depth: depth,
                yOffset: yOffset
            )
            .frame(width: 96, height: 96)
    }

    private func renderPixels<Content: View>(
        _ content: Content,
        size: CGSize
    ) throws -> RenderedPixels {
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.scale = 1
        renderer.isOpaque = false

        let image = try XCTUnwrap(renderer.uiImage?.cgImage)
        var rgba = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue
        let context = try XCTUnwrap(
            CGContext(
                data: &rgba,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo
            )
        )
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
        )
        return RenderedPixels(width: image.width, height: image.height, rgba: rgba)
    }

    private struct RenderedPixels {
        struct Pixel {
            let red: UInt8
            let green: UInt8
            let blue: UInt8
            let alpha: UInt8
        }

        let width: Int
        let height: Int
        let rgba: [UInt8]

        func pixel(x: Int, y: Int) -> Pixel {
            let index = ((y * width) + x) * 4
            return Pixel(
                red: rgba[index],
                green: rgba[index + 1],
                blue: rgba[index + 2],
                alpha: rgba[index + 3]
            )
        }

        func alphaMass(outside excludedBounds: CGRect) -> Int {
            var mass = 0
            for y in 0..<height {
                for x in 0..<width where !excludedBounds.contains(
                    CGPoint(x: x, y: y)
                ) {
                    mass += Int(pixel(x: x, y: y).alpha)
                }
            }
            return mass
        }

        func alphaCentroidY(outside excludedBounds: CGRect) -> Double? {
            var mass = 0.0
            var weightedY = 0.0
            for y in 0..<height {
                for x in 0..<width where !excludedBounds.contains(
                    CGPoint(x: x, y: y)
                ) {
                    let alpha = Double(pixel(x: x, y: y).alpha)
                    mass += alpha
                    weightedY += Double(y) * alpha
                }
            }
            return mass > 0 ? weightedY / mass : nil
        }
    }

    private func assertColor(
        _ color: Color,
        resolvesTo expected: FamilyVisualColorToken,
        interfaceStyle: UIUserInterfaceStyle,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertRGBA(
            resolvedToken(from: UIColor(color), interfaceStyle: interfaceStyle),
            equals: expected,
            message: message,
            file: file,
            line: line
        )
    }

    private func token(
        _ token: FamilyVisualColorToken,
        withOpacity opacity: Double
    ) -> FamilyVisualColorToken {
        FamilyVisualColorToken(
            red: token.red,
            green: token.green,
            blue: token.blue,
            opacity: opacity
        )
    }

    private func resolvedToken(
        from color: UIColor,
        interfaceStyle: UIUserInterfaceStyle
    ) -> FamilyVisualColorToken {
        let resolved = color.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: interfaceStyle)
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0
        XCTAssertTrue(
            resolved.getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        )
        return FamilyVisualColorToken(
            red: Double(red * 255),
            green: Double(green * 255),
            blue: Double(blue * 255),
            opacity: Double(opacity)
        )
    }

    private func assertRGBA(
        _ actual: FamilyVisualColorToken,
        equals expected: FamilyVisualColorToken,
        message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            actual.red,
            expected.red,
            accuracy: 0.000_1,
            "\(message) red",
            file: file,
            line: line
        )
        XCTAssertEqual(
            actual.green,
            expected.green,
            accuracy: 0.000_1,
            "\(message) green",
            file: file,
            line: line
        )
        XCTAssertEqual(
            actual.blue,
            expected.blue,
            accuracy: 0.000_1,
            "\(message) blue",
            file: file,
            line: line
        )
        XCTAssertEqual(
            actual.opacity,
            expected.opacity,
            accuracy: 0.000_001,
            "\(message) opacity",
            file: file,
            line: line
        )
    }
}

private struct AppFamilyProjectModel {
    let packageProductsByTarget: [String: [String]]
    let localPackagePaths: [String]

    init(project: String) throws {
        let targetObjects = try Self.objects(in: "PBXNativeTarget", project: project)
        let productObjects = try Self.objects(
            in: "XCSwiftPackageProductDependency",
            project: project
        )
        let localPackageObjects = try Self.objects(
            in: "XCLocalSwiftPackageReference",
            project: project
        )
        let productNamesByID = productObjects.mapValues {
            Self.scalarField("productName", in: $0) ?? "<missing-productName>"
        }
        var productsByTarget: [String: [String]] = [:]
        for targetBody in targetObjects.values {
            guard let targetName = Self.scalarField("name", in: targetBody) else {
                continue
            }
            let dependencyIDs = Self.identifierList(
                field: "packageProductDependencies",
                in: targetBody
            )
            productsByTarget[targetName] = dependencyIDs.map {
                productNamesByID[$0] ?? "<unresolved:\($0)>"
            }
        }

        packageProductsByTarget = productsByTarget
        localPackagePaths = localPackageObjects.values
            .map { Self.scalarField("relativePath", in: $0) ?? "<missing-relativePath>" }
            .sorted()
    }

    private static func objects(
        in section: String,
        project: String
    ) throws -> [String: String] {
        guard let objects = try objectsIfPresent(in: section, project: project) else {
            throw AppFamilyProjectParseError.missingSection(section)
        }
        return objects
    }

    private static func objectsIfPresent(
        in section: String,
        project: String
    ) throws -> [String: String]? {
        let startMarker = "/* Begin \(section) section */"
        let endMarker = "/* End \(section) section */"
        guard let start = project.range(of: startMarker) else {
            return nil
        }
        guard let end = project.range(
            of: endMarker,
            range: start.upperBound..<project.endIndex
        ) else {
            throw AppFamilyProjectParseError.unterminatedSection(section)
        }

        let sectionText = project[start.upperBound..<end.lowerBound]
        var parsed: [String: String] = [:]
        var currentID: String?
        var bodyLines: [String] = []

        for rawLine in sectionText.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ) {
            let line = String(rawLine)
            if let objectID = currentID {
                if line == "\t\t};" {
                    parsed[objectID] = bodyLines.joined(separator: "\n")
                    currentID = nil
                    bodyLines = []
                } else {
                    bodyLines.append(line)
                }
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let assignment = trimmed.range(of: " = {") else {
                continue
            }
            let identifierAndComment = trimmed[..<assignment.lowerBound]
            let identifier = identifierAndComment.split(separator: " ").first.map(String.init)
            guard let identifier, isPBXIdentifier(identifier) else {
                continue
            }
            currentID = identifier
        }

        if currentID != nil {
            throw AppFamilyProjectParseError.unterminatedObject(section)
        }
        return parsed
    }

    private static func scalarField(_ field: String, in body: String) -> String? {
        let prefix = "\(field) = "
        for rawLine in body.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix(prefix), line.hasSuffix(";") else {
                continue
            }
            let value = line.dropFirst(prefix.count).dropLast()
            return value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }

    private static func identifierList(field: String, in body: String) -> [String] {
        let startMarker = "\(field) = ("
        guard let start = body.range(of: startMarker),
              let end = body.range(
                  of: ");",
                  range: start.upperBound..<body.endIndex
              ) else {
            return []
        }

        let list = body[start.upperBound..<end.lowerBound]
        return list.split(separator: "\n").compactMap { rawLine in
            let identifier = rawLine
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: " ")
                .first
                .map(String.init)?
                .trimmingCharacters(in: CharacterSet(charactersIn: ","))
            guard let identifier, isPBXIdentifier(identifier) else {
                return nil
            }
            return identifier
        }
    }

    private static func isPBXIdentifier(_ value: String) -> Bool {
        value.count == 24 && value.allSatisfy(\.isHexDigit)
    }
}

private enum AppFamilyProjectParseError: Error, CustomStringConvertible {
    case missingSection(String)
    case unterminatedSection(String)
    case unterminatedObject(String)

    var description: String {
        switch self {
        case let .missingSection(section):
            return "missing \(section) section"
        case let .unterminatedSection(section):
            return "unterminated \(section) section"
        case let .unterminatedObject(section):
            return "unterminated object in \(section) section"
        }
    }
}
