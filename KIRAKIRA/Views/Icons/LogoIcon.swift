//
//  Logo.swift
//  KIRAKIRA
//
//  Created by Aira Sakuranomiya on 2025/11/22.
//

import SwiftUI

struct LogoIcon: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		let width = rect.size.width
		let height = rect.size.height
		path.move(to: CGPoint(x: 0.13398 * width, y: 0.40915 * height))
		path.addCurve(
			to: CGPoint(x: 0.16386 * width, y: 0.38976 * height),
			control1: CGPoint(x: 0.13088 * width, y: 0.39228 * height),
			control2: CGPoint(x: 0.14971 * width, y: 0.38006 * height)
		)
		path.addLine(to: CGPoint(x: 0.29122 * width, y: 0.47701 * height))
		path.addCurve(
			to: CGPoint(x: 0.31129 * width, y: 0.47807 * height),
			control1: CGPoint(x: 0.29719 * width, y: 0.4811 * height),
			control2: CGPoint(x: 0.30493 * width, y: 0.48151 * height)
		)
		path.addLine(to: CGPoint(x: 0.44708 * width, y: 0.4046 * height))
		path.addCurve(
			to: CGPoint(x: 0.47476 * width, y: 0.42702 * height),
			control1: CGPoint(x: 0.46216 * width, y: 0.39644 * height),
			control2: CGPoint(x: 0.47961 * width, y: 0.41056 * height)
		)
		path.addLine(to: CGPoint(x: 0.43112 * width, y: 0.5751 * height))
		path.addCurve(
			to: CGPoint(x: 0.43632 * width, y: 0.59452 * height),
			control1: CGPoint(x: 0.42908 * width, y: 0.58204 * height),
			control2: CGPoint(x: 0.43109 * width, y: 0.58954 * height)
		)
		path.addLine(to: CGPoint(x: 0.54816 * width, y: 0.70096 * height))
		path.addCurve(
			to: CGPoint(x: 0.5354 * width, y: 0.73421 * height),
			control1: CGPoint(x: 0.56059 * width, y: 0.71278 * height),
			control2: CGPoint(x: 0.55255 * width, y: 0.73373 * height)
		)
		path.addLine(to: CGPoint(x: 0.38107 * width, y: 0.73848 * height))
		path.addCurve(
			to: CGPoint(x: 0.36421 * width, y: 0.74943 * height),
			control1: CGPoint(x: 0.37384 * width, y: 0.73868 * height),
			control2: CGPoint(x: 0.36733 * width, y: 0.74291 * height)
		)
		path.addLine(to: CGPoint(x: 0.29753 * width, y: 0.88868 * height))
		path.addCurve(
			to: CGPoint(x: 0.26198 * width, y: 0.88681 * height),
			control1: CGPoint(x: 0.29012 * width, y: 0.90415 * height),
			control2: CGPoint(x: 0.26773 * width, y: 0.90297 * height)
		)
		path.addLine(to: CGPoint(x: 0.21022 * width, y: 0.74135 * height))
		path.addCurve(
			to: CGPoint(x: 0.19459 * width, y: 0.7287 * height),
			control1: CGPoint(x: 0.20779 * width, y: 0.73454 * height),
			control2: CGPoint(x: 0.20176 * width, y: 0.72965 * height)
		)
		path.addLine(to: CGPoint(x: 0.04157 * width, y: 0.70832 * height))
		path.addCurve(
			to: CGPoint(x: 0.03235 * width, y: 0.67393 * height),
			control1: CGPoint(x: 0.02457 * width, y: 0.70606 * height),
			control2: CGPoint(x: 0.01875 * width, y: 0.68439 * height)
		)
		path.addLine(to: CGPoint(x: 0.1547 * width, y: 0.57977 * height))
		path.addCurve(
			to: CGPoint(x: 0.1619 * width, y: 0.561 * height),
			control1: CGPoint(x: 0.16043 * width, y: 0.57536 * height),
			control2: CGPoint(x: 0.1632 * width, y: 0.56811 * height)
		)
		path.addLine(to: CGPoint(x: 0.13398 * width, y: 0.40915 * height))
		path.closeSubpath()
		path.move(to: CGPoint(x: 0.83815 * width, y: 0.47129 * height))
		path.addCurve(
			to: CGPoint(x: 0.87817 * width, y: 0.4798 * height),
			control1: CGPoint(x: 0.85155 * width, y: 0.46259 * height),
			control2: CGPoint(x: 0.86946 * width, y: 0.46641 * height)
		)
		path.addCurve(
			to: CGPoint(x: 0.86967 * width, y: 0.51982 * height),
			control1: CGPoint(x: 0.88687 * width, y: 0.4932 * height),
			control2: CGPoint(x: 0.88307 * width, y: 0.51112 * height)
		)
		path.addLine(to: CGPoint(x: 0.64322 * width, y: 0.66687 * height))
		path.addCurve(
			to: CGPoint(x: 0.6032 * width, y: 0.65836 * height),
			control1: CGPoint(x: 0.62982 * width, y: 0.67557 * height),
			control2: CGPoint(x: 0.61191 * width, y: 0.67176 * height)
		)
		path.addCurve(
			to: CGPoint(x: 0.6117 * width, y: 0.61834 * height),
			control1: CGPoint(x: 0.59451 * width, y: 0.64496 * height),
			control2: CGPoint(x: 0.59831 * width, y: 0.62704 * height)
		)
		path.addLine(to: CGPoint(x: 0.83815 * width, y: 0.47129 * height))
		path.closeSubpath()
		path.move(to: CGPoint(x: 0.92275 * width, y: 0.09625 * height))
		path.addCurve(
			to: CGPoint(x: 0.96277 * width, y: 0.10474 * height),
			control1: CGPoint(x: 0.93615 * width, y: 0.08755 * height),
			control2: CGPoint(x: 0.95407 * width, y: 0.09135 * height)
		)
		path.addCurve(
			to: CGPoint(x: 0.95427 * width, y: 0.14476 * height),
			control1: CGPoint(x: 0.97147 * width, y: 0.11814 * height),
			control2: CGPoint(x: 0.96767 * width, y: 0.13606 * height)
		)
		path.addLine(to: CGPoint(x: 0.56608 * width, y: 0.39687 * height))
		path.addCurve(
			to: CGPoint(x: 0.52606 * width, y: 0.38836 * height),
			control1: CGPoint(x: 0.55268 * width, y: 0.40557 * height),
			control2: CGPoint(x: 0.53476 * width, y: 0.40175 * height)
		)
		path.addCurve(
			to: CGPoint(x: 0.53456 * width, y: 0.34834 * height),
			control1: CGPoint(x: 0.51737 * width, y: 0.37496 * height),
			control2: CGPoint(x: 0.52116 * width, y: 0.35704 * height)
		)
		path.addLine(to: CGPoint(x: 0.92275 * width, y: 0.09625 * height))
		path.closeSubpath()
		return path
	}
}
